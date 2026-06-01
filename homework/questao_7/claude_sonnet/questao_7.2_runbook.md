# RUNBOOK — [CRITICAL] High Memory Usage on Chronos API Pods (>85%)

|Campo|Valor|
|---|---|
|**Serviço**|Chronos API|
|**Namespace**|`production`|
|**Cluster**|AWS EKS|
|**Repositório**|`hvt/chronos-api`|
|**Canal de comunicação**|`#oncall-chronos`|
|**Escalação sênior**|`@chronos-core`|
|**SLA de escalação**|15 min (horário comercial) / 30 min (fora do horário)|
|**Dependências**|Ledger (PostgreSQL), Reactor (AWS SQS)|
|**Observabilidade**|Endpoint `/metrics`, Beacon (logs), Grafana (painéis)|

---

## PRÉ-REQUISITOS

Confirme acesso antes de iniciar. Execute:

```bash
kubectl get nodes -o wide
aws sts get-caller-identity
argocd app list
```

Todos os comandos devem retornar sem erro de autenticação. Se falharem, resolva o acesso antes de prosseguir.

---

## SEÇÃO 1 — TRIAGEM INICIAL E DIAGNÓSTICO

**Objetivo:** Confirmar se o alerta reflete consumo real de memória, identificar pods afetados e verificar capacidade do cluster para resposta automática via HPA.

### 1.1 — Confirmar consumo real de memória por pod

```bash
kubectl top pods -n production -l app=chronos-api --sort-by=memory
```

**Saída esperada normal:** Pods abaixo de 85% do `resources.limits.memory` definido no manifesto.

**Saída indicando problema:** Um ou mais pods exibindo valores próximos ou acima do limite configurado. Anote os nomes dos pods afetados — serão usados nos passos seguintes.

Para ver os limites configurados:

```bash
kubectl get pods -n production -l app=chronos-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].resources}{"\n"}{end}'
```

### 1.2 — Verificar status do HPA e se está escalando

```bash
kubectl get hpa -n production
kubectl describe hpa chronos-api -n production
```

**O que verificar na saída do `describe`:**

- `Current Replicas` vs `Desired Replicas`: se `Desired > Current`, o HPA já detectou a carga e está tentando escalar.
- `Conditions`: procure por `ScalingLimited: True` — indica que o HPA atingiu `max: 12` ou está bloqueado por falta de nós.
- `Events`: qualquer mensagem `FailedScale` ou `SuccessfulRescale` indica o histórico recente de ações.

### 1.3 — Verificar disponibilidade de nós no cluster (gargalo do Cluster Autoscaler)

```bash
kubectl get nodes -o custom-columns="NAME:.metadata.name,STATUS:.status.conditions[-1].type,CPU:.status.allocatable.cpu,MEM:.status.allocatable.memory"
```

```bash
kubectl describe nodes | grep -A5 "Allocated resources"
```

**O que verificar:** Se todos os nós aparecerem com `MemoryPressure` ou com allocatable próximo de 0, o Cluster Autoscaler pode não ter conseguido provisionar novos nós. Verifique os eventos do Cluster Autoscaler:

```bash
kubectl get events -n kube-system --sort-by='.lastTimestamp' | grep -i "scale\|autoscal\|node" | tail -20
```

**Saída indicando problema:** Eventos com `NotTriggerScaleUp` ou `ScaleUpFailed` confirmam gargalo de infraestrutura — escale para `@chronos-core` imediatamente (ver Seção 4).

### 1.4 — Identificar eventos OOMKilled (reinicializações por falta de memória)

```bash
kubectl get pods -n production -l app=chronos-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\t"}{.status.containerStatuses[0].lastState.terminated.reason}{"\n"}{end}'
```

**Saída indicando OOMKill:** `OOMKilled` na coluna `reason`. Pods com `restartCount > 0` e razão `OOMKilled` confirmam que o kernel Linux já encerrou processos por esgotamento de memória.

Para inspecionar o último estado de um pod específico:

```bash
kubectl describe pod <NOME_DO_POD> -n production | grep -A10 "Last State"
```

**Buscar OOMKilled nos logs do Beacon:**

No painel do Beacon, execute a query:

```
service="chronos-api" AND (level="ERROR" OR message="OOMKilled" OR message="out of memory")
```

Filtre pelas últimas 2 horas e ordene por `timestamp` decrescente.

---

## SEÇÃO 2 — VERIFICAÇÃO DE DEPENDÊNCIAS

**Objetivo:** Determinar se o consumo de memória na Chronos API é causado por lentidão ou falha no Ledger (PostgreSQL) ou acúmulo de mensagens no Reactor (SQS). Dependências degradadas forçam a API a acumular dados em memória enquanto aguarda resposta.

### 2.1 — Verificar saúde do Ledger (PostgreSQL)

Verifique o endpoint de health da aplicação (se exposto):

```bash
kubectl exec -n production deploy/chronos-api -- curl -sf http://localhost:8080/health | jq .
```

**Saída esperada:** `{"status": "UP", "ledger": "UP"}` ou equivalente. Se `ledger` retornar `DOWN` ou `DEGRADED`, a causa raiz é o banco de dados.

Verifique conexões ativas no banco via pod da aplicação:

```bash
kubectl exec -n production deploy/chronos-api -- env | grep -i "DB\|POSTGRES\|LEDGER"
```

Use as variáveis retornadas para identificar o host do banco. Depois cheque latência de conexão:

```bash
kubectl exec -n production deploy/chronos-api -- sh -c "time psql \$DATABASE_URL -c 'SELECT 1;' 2>&1"
```

**Saída indicando problema:** Latência acima de 500ms ou erro de conexão (`Connection refused`, `timeout`). Nesse caso, acione `@chronos-core` e inclua a mensagem de erro completa.

Verifique métricas de conexão no Grafana:

- Painel: **Chronos API → Database**
- Métrica: `chronos_db_connection_pool_active` e `chronos_db_query_duration_seconds`
- **Alerta:** Pool saturado (active ≈ max) ou P99 de latência acima de 1s confirmam gargalo no Ledger.

### 2.2 — Verificar volume e lag nas filas do Reactor (SQS)

Liste as filas associadas ao Chronos API:

```bash
aws sqs list-queues --queue-name-prefix "chronos" --output table
```

Para cada fila retornada, verifique o número de mensagens visíveis e não processadas:

```bash
aws sqs get-queue-attributes \
  --queue-url <URL_DA_FILA> \
  --attribute-names ApproximateNumberOfMessages,ApproximateNumberOfMessagesNotVisible,ApproximateNumberOfMessagesDelayed
```

|Atributo|Valor normal|Valor problemático|
|---|---|---|
|`ApproximateNumberOfMessages`|< 1.000|> 10.000|
|`ApproximateNumberOfMessagesNotVisible`|< 500|> 5.000|
|`ApproximateNumberOfMessagesDelayed`|0|> 0|

**Lógica de diagnóstico:** Filas com lag crescente (`ApproximateNumberOfMessages` aumentando ao longo do tempo) indicam que a Chronos API está consumindo mensagens mais lento do que estão chegando. Isso força acúmulo de dados em memória durante o processamento.

Verifique a tendência no Grafana:

- Painel: **Chronos API → Reactor (SQS)**
- Métrica: `chronos_sqs_messages_received_total` vs `chronos_sqs_messages_processed_total`
- **Alerta:** Gap crescente entre as duas curvas confirma lag de processamento.

---

## SEÇÃO 3 — AÇÕES DE MITIGAÇÃO (NÍVEL 1)

Execute as ações na ordem apresentada. Após cada ação, aguarde 3 minutos e verifique o efeito no Grafana antes de prosseguir para o próximo passo.

### Ação 3.1 — Reiniciar pods com maior consumo de memória (Rolling Restart Seletivo)

Identifique os 2 pods com maior consumo (da Seção 1.1) e delete-os. O Deployment recriará os pods automaticamente com estado limpo.

```bash
# Substitua <POD_1> e <POD_2> pelos nomes identificados na triagem
kubectl delete pod <POD_1> <POD_2> -n production
```

Monitore a recriação:

```bash
kubectl get pods -n production -l app=chronos-api -w
```

**Saída esperada:** Os pods deletados entram em `Terminating` e novos pods aparecem com status `ContainerCreating` → `Running`. O processo deve completar em menos de 60 segundos.

**Efeito esperado no Grafana:** No painel **Chronos API → Memory Usage**, as curvas dos pods reiniciados devem cair para o baseline (tipicamente 30-50% do limite) imediatamente após o restart.

> ⚠️ **Atenção:** Não delete mais do que 2 pods simultaneamente. O HPA garante `min: 4` réplicas, mas deletar muitos pods ao mesmo tempo pode causar queda de disponibilidade.

### Ação 3.2 — Forçar escala manual temporária via HPA

Se a memória permanecer alta mesmo após o restart dos pods, force o HPA a manter mais réplicas ativas:

```bash
kubectl scale deployment chronos-api --replicas=8 -n production
```

Verifique que o HPA não conflita com o scaling manual:

```bash
kubectl get hpa chronos-api -n production
```

**Saída esperada:** `REPLICAS` atualiza para 8 e o HPA não reverte imediatamente (o HPA só age se a CPU média divergir do target de 70%).

**Efeito esperado no Grafana:** Com mais réplicas, a carga de memória distribui entre os pods. No painel **Chronos API → Memory Usage**, todas as linhas de pods devem cair abaixo de 80%.

> ⚠️ **Lembre-se:** Após a estabilização do incidente, reverta o scaling manual para que o HPA retome o controle:
> 
> ```bash
> kubectl scale deployment chronos-api --replicas=6 -n production
> ```

### Ação 3.3 — Verificar e sincronizar o estado do deploy via Argo CD

Se os pods reiniciados apresentarem comportamento anômalo (crash loops, versão inesperada), verifique se o estado do cluster está sincronizado com o Git:

```bash
argocd app get chronos-api
argocd app diff chronos-api
```

**Saída esperada:** `Sync Status: Synced` e sem diff entre o estado atual e o repositório `hvt/chronos-api`.

Se houver drift (estado `OutOfSync`):

```bash
argocd app sync chronos-api --prune
```

**Efeito esperado:** O Argo CD reaplicará os manifestos do repositório, garantindo que limits/requests de memória estejam corretos e que nenhuma configuração tenha sido alterada manualmente fora do processo de CD.

### Ação 3.4 — Realizar rolling restart completo do Deployment (último recurso Nível 1)

Se as ações anteriores não estabilizarem o serviço em 15 minutos, realize o restart completo do deployment de forma controlada:

```bash
kubectl rollout restart deployment/chronos-api -n production
```

Monitore o progresso:

```bash
kubectl rollout status deployment/chronos-api -n production
```

**Saída esperada:**

```
Waiting for deployment "chronos-api" rollout to finish: 1 out of 6 new replicas have been updated...
...
deployment "chronos-api" successfully rolled out
```

**Efeito esperado no Grafana:** Todas as curvas de memória no painel **Chronos API → Memory Usage** devem resetar para o baseline em até 3 minutos após a conclusão do rollout. A taxa de requisições no painel **Chronos API → Request Rate** não deve cair abaixo de 80% do baseline durante o rollout (o RollingUpdate garante disponibilidade).

---

## SEÇÃO 4 — CRITÉRIOS DE ESCALAÇÃO (NÍVEL 2)

Acione `@chronos-core` no canal `#oncall-chronos` se **qualquer** das condições abaixo for verdadeira:

|#|Gatilho|Evidência|
|---|---|---|
|1|**15 minutos após início da mitigação** e memória ainda acima de 85%|Grafana: curva de memória não cede após as ações da Seção 3|
|2|**OOMKilled em loop** — pod reinicia mais de 3 vezes em 10 minutos|`kubectl get pods`: `RESTARTS > 3` em pods com `AGE < 10m`|
|3|**HPA no limite máximo** (12 réplicas) e memória ainda crescendo|`kubectl get hpa`: `MAXPODS=12`, `CURRENT=12`|
|4|**Cluster Autoscaler com falha** — nós não provisionados|Eventos `ScaleUpFailed` ou `NotTriggerScaleUp` na Seção 1.3|
|5|**Ledger inacessível ou com latência P99 > 2s**|Health check da Seção 2.1 falhando|
|6|**Lag de SQS crescente e irrecuperável** — fila acima de 50.000 mensagens|AWS CLI da Seção 2.2 retornando valores críticos|
|7|**Rollout do Argo CD falhou**|`argocd app get chronos-api` com status `Degraded` ou `Error`|

### Mensagem de escalação (copie e preencha):

```
@chronos-core [ESCALAÇÃO] Incidente de alta memória na Chronos API — NÍVEL 2

⏱ Início do incidente: <HH:MM>
⏱ Início da mitigação: <HH:MM>
📌 Gatilho de escalação: <descreva qual condição acima foi atingida>

Estado atual:
- Réplicas ativas: <N>
- Consumo de memória máximo: <X%>
- Pods com OOMKilled: <lista>
- HPA: CURRENT=<N> / MAX=12

Ações já executadas:
- [ ] Restart seletivo de pods (Seção 3.1)
- [ ] Scale manual para 8 réplicas (Seção 3.2)
- [ ] Sync Argo CD (Seção 3.3)
- [ ] Rolling restart completo (Seção 3.4)

Ledger (PostgreSQL): <UP/DOWN/DEGRADED>
Reactor (SQS) lag: <N mensagens>

Link Grafana: <URL do painel>
Link Beacon: <URL da query de logs>
```

---

## SEÇÃO 5 — CRITÉRIO DE ENCERRAMENTO (DEFINIÇÃO DE PRONTO)

O incidente só pode ser encerrado e o alerta fechado quando **todos** os critérios abaixo forem satisfeitos simultaneamente por um período mínimo de **10 minutos contínuos**:

### 5.1 — Métricas no Grafana

Verifique no painel **Chronos API → Overview**:

|Painel|Métrica|Critério de encerramento|
|---|---|---|
|Memory Usage|`container_memory_working_set_bytes` por pod|Todos os pods abaixo de **75%** do limite de memória|
|Memory Trend|Derivada da curva de memória|Curva **estável ou decrescente** (sem inclinação positiva)|
|Pod Restarts|`kube_pod_container_status_restarts_total`|**Zero novos restarts** nos últimos 10 minutos|
|Request Rate|Requisições por segundo|Acima de **90% do baseline histórico**|
|Error Rate|Taxa de erros 5xx|Abaixo de **1%**|
|HPA Replicas|`kube_horizontalpodautoscaler_status_current_replicas`|Estável (sem variação brusca)|

### 5.2 — Estado do cluster

```bash
# Confirmar que nenhum pod está em estado problemático
kubectl get pods -n production -l app=chronos-api

# Saída esperada: todos os pods com STATUS=Running e RESTARTS baixo/estável
```

```bash
# Confirmar que o HPA está operando normalmente
kubectl get hpa chronos-api -n production

# Saída esperada: CONDITION não contém ScalingLimited e TARGETS próximo ao alvo de 70% CPU
```

### 5.3 — Verificação das dependências

- Ledger: health check retornando `UP` (Seção 2.1)
- Reactor: filas SQS sem lag crescente (Seção 2.2)

### 5.4 — Comunicação de encerramento no Slack

Após confirmar todos os critérios, poste no `#oncall-chronos`:

```
✅ [ENCERRADO] Incidente de alta memória — Chronos API

⏱ Início: <HH:MM> | Encerramento: <HH:MM> | Duração: <X min>

Resolução: <descreva o que foi feito — ex: "Rolling restart de 2 pods afetados + scale manual para 8 réplicas durante pico">
Causa provável: <ex: "Leak de memória associado a pico de SQS — lag de X mensagens forçou retenção de dados em memória">

Próximos passos (pós-incidente):
- [ ] Abrir ticket de investigação no repositório hvt/chronos-api
- [ ] Rever limites de memória no manifesto do Deployment
- [ ] Verificar se HPA deve incluir target de memória (além de CPU)
- [ ] Revisar configuração de prefetch/batch do consumidor SQS
```

---

_Runbook versão 1.0 — gerado para o alerta `[CRITICAL] High memory usage on Chronos API pods (>85% for 10min)`_