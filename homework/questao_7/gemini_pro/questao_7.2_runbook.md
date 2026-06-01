# Runbook: [CRITICAL] High memory usage on Chronos API pods (>85% for 10min)

## 1. Triagem Inicial e Diagnóstico

Execute os comandos abaixo para identificar o estado atual do cluster e dos pods da aplicação `chronos-api`.

**1.1. Verifique o consumo real de memória dos pods**

Bash

```
kubectl top pods -n production -l app=chronos-api
```

_Ação:_ Observe se os pods estão consistentemente acima do limite esperado de memória. Anote os nomes dos pods com maior consumo.

**1.2. Valide o estado do HPA e disponibilidade de Nós**

Bash

```
# Verifique o alvo e o número atual de réplicas
kubectl get hpa -n production

# Verifique detalhes de eventos do HPA (falhas de scale up)
kubectl describe hpa chronos-api -n production

# Confirme se há recursos disponíveis nos nós do cluster (evitar gargalo do Cluster Autoscaler)
kubectl top nodes
kubectl get nodes
```

_Ação:_ Confirme se o HPA atingiu o limite de 12 réplicas ou se está travado por falta de CPU/Memória nos nós (status `Pending` nos pods novos).

**1.3. Busque por eventos de Out-Of-Memory (OOMKilled)**

Bash

```
# Liste os pods e observe a coluna RESTARTS
kubectl get pods -n production -l app=chronos-api

# Descreva um pod reiniciado para confirmar o OOMKilled
kubectl describe pod <NOME_DO_POD> -n production | grep -A 5 -i "OOMKilled"
```

_Ação:_ Acesse a ferramenta **Beacon** e filtre os logs dos últimos 15 minutos com a query: `app="chronos-api" AND "OutOfMemory"`. Verifique se há uma transação ou endpoint específico causando o estouro de memória.

## 2. Verificação de Dependências

O acúmulo de memória na API geralmente é sintoma de conexões presas no banco de dados ou lentidão no consumo de mensagens.

**2.1. Cheque a saúde do banco Ledger (PostgreSQL)**

Bash

```
# Busque por erros de timeout ou conexões recusadas nos logs da API
kubectl logs -l app=chronos-api -n production --tail=500 | grep -i -E "timeout|connection refused|ledger|postgres"
```

_Ação:_ Abra o Grafana no painel do banco de dados (Ledger/PostgreSQL). Verifique os gráficos de **Active Connections** e **Query Latency**. Se as conexões estiverem no limite ou a latência estiver em pico vertical, o problema está no banco segurando as threads da API.

**2.2. Avalie o volume/lag de mensagens nas filas do Reactor (SQS)**

Bash

```
# Verifique o volume de mensagens represadas na fila principal
aws sqs get-queue-attributes \
    --queue-url <URL_DA_FILA_REACTOR> \
    --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible
```

_Ação:_ No Grafana, acesse o painel da AWS SQS. Se o gráfico `ApproximateAgeOfOldestMessage` estiver crescendo continuamente, a API não está conseguindo processar as mensagens, acumulando-as em memória.

## 3. Ações de Mitigação (Nível 1)

Execute os procedimentos abaixo para estabilizar o serviço temporariamente e restaurar a operação normal.

**3.1. Reinício Controlado (Rollout Restart)** Se não houver anomalias nas dependências (Banco e Fila saudáveis), a memória acumulada é um vazamento (memory leak). Force a reciclagem dos pods.

Bash

```
kubectl rollout restart deployment chronos-api -n production
```

_Saída Esperada:_ O comando retornará `deployment.apps/chronos-api restarted`. _Comportamento Esperado:_ No Grafana, o gráfico de consumo de memória deve cair drasticamente para o nível basal (< 40%). Novos pods assumirão o tráfego limpos.

**3.2. Sincronização via Argo CD (Em caso de falha no Rollout)** Se o cluster apresentar inconsistência de estado, force a sincronização declarativa.

Bash

```
argocd app sync chronos-api --force
```

_Saída Esperada:_ O comando mostrará o progresso de sincronização dos recursos Kubernetes e reportará `Healthy`.

## 4. Critérios de Escalação (Nível 2)

Acione imediatamente o time `@chronos-core` no canal do Slack `#oncall-chronos` se **qualquer** uma das seguintes condições for verdadeira:

1. **Persistência Pós-Mitigação:** O consumo de memória volta a ultrapassar 85% em menos de 15 minutos após o `rollout restart`.
    
2. **Falha em Dependência Crítica:** O banco de dados Ledger apresenta CPU > 90%, recusa conexões persistentes ou as filas do SQS possuem mensagens não processadas há mais de 10 minutos.
    
3. **Indisponibilidade de Cluster:** O HPA tenta escalar, mas o Cluster Autoscaler não consegue provisionar novos nós (falha de cota AWS EKS ou erro de infraestrutura).
    
4. **Violação de SLA:** O incidente não foi mitigado após 15 minutos de troubleshooting contínuo.
    

_Template de Escalação (Copie e cole no Slack):_

> `@chronos-core` Escalação de Incidente - Chronos API OOMKilled. Memória > 85%. Rollout restart executado sem sucesso prolongado. Dependências: [Status do DB] / [Status do SQS]. Precisamos de apoio para análise de root cause (Possível Memory Leak severo).

## 5. Critério de Encerramento (Definição de Pronto)

O incidente pode ser considerado **mitigado** e o alerta resolvido quando **todas** as condições abaixo forem atendidas:

- **Grafana:** O uso de memória de todos os pods da `chronos-api` permanece estável **abaixo de 70%** por pelo menos **15 minutos** contínuos.
    
- **Kubernetes:** A métrica `kubectl get pods -n production` não registra nenhum novo `RESTART` na coluna correspondente nos últimos 15 minutos.
    
- **HPA:** O número de réplicas estabilizou e não está em flutuação constante (flapping).
    
- **Slack:** Uma mensagem final foi enviada no canal `#oncall-chronos` reportando o encerramento da atuação de Nível 1.
    

_Template de Encerramento (Copie e cole no Slack):_

> Alerta mitigado. Pods reciclados via `rollout restart`. Memória estabilizada em níveis normais (<70%) há mais de 15 minutos. Nenhuma anomalia no DB ou SQS. Acompanhando o dashboard.