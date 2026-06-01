## ROLE
Você é um engenheiro SRE com especialidade em infraestrutura AWS, Kubernetes e Grafana.

## INPUT

*   **Alerta Recorrente:** `[CRITICAL] High memory usage on Chronos API pods (>85% for 10min)` (ocorre ~4x por semana, gerando 30-40 min de overhead por falta de documentação).

*   **EKS :** Roda no cluster AWS EKS, namespace `production`, possui 6 réplicas ativas controladas por um HPA (Horizontal Pod Autoscaler) configurado com min: 4, max: 12 e alvo de CPU em 70%.

*   **CI/CD:** Deploy feito via Argo CD utilizando o repositório Git `hvt/chronos-api`.

*   **Arquitetura/Dependências:** Ledger (Banco de dados PostgreSQL) e Reactor (mensageria via filas AWS SQS).

*   **Observabilidade:** Métricas expostas no endpoint `/metrics`, logs centralizados na ferramenta "Beacon" e painéis visuais no Grafana.

*   **Ferramentas do Plantonista:** `kubectl`, `aws cli` e `argocd cli`.

*   **Comunicação:** Canal do Slack `#oncall-chronos`. Time de escalação sênior: `@chronos-core` (SLA: 15min comercial / 30min fora).

## STEPS
Gere o runbook organizando-o estritamente nas seguintes seções sequenciais:

1.  **Triagem Inicial e Diagnóstico:** Crie o passo a passo com comandos reais e específicos (utilizando `kubectl`, `aws` ou `argocd`) para o plantonista verificar:
    *   O consumo real de memória dos pods atuais.
    *   Se o HPA está tentando buildar novos pods e se há nós disponíveis no cluster (evitar gargalo de cluster autoscaler).
    *   Como buscar mensagens de erro de Out-Of-Memory (OOMKilled) nos logs do Beacon ou via kubectl.

2.  **Verificação de Dependências:** Forneça instruções para checar a saúde do Ledger (PostgreSQL) e o volume/lag de mensagens nas filas do Reactor (SQS), identificando se o acúmulo de memória na API é um sintoma dessas dependências.

3.  **Ações de Mitigação (Nível 1):** Liste os procedimentos operacionais padrão para estabilizar o serviço temporariamente. Cada passo deve conter uma explicação da saída esperada (ex: "O comando deve retornar a mensagem X; no Grafana, a curva Y deve cair").

4.  **Critérios de Escalação (Nível 2):** Defina gatilhos quantitativos e claros de quando o plantonista deve acionar o time `@chronos-core` no canal `#oncall-chronos` (ex: X minutos sem sucesso, erro persistente no banco, etc.).

5.  **Critério de Encerramento (Definição de Pronto):** Determine quais métricas e comportamentos no Grafana e Slack consolidam que o incidente foi mitigado e o alerta pode ser fechado.

## EXPECTATION
Espero um runbooks procedurais extremamente direto, simples e  claros, acionáveis e bem organizado para fácil leitura

O foco é a execução rápida por um plantonista sob pressão,  e que permitam que engenheiros de plantão de qualquer nível de senioridade resolvam incidentes de forma autônoma e rapida consultando o runbooks

O tom deve ser puramente técnico, imperativo ("Rode o comando X", "Verifique o painel Y") e extremamente direto ao ponto. 

O runbook final deve ser um artefato entregue em formato Markdown estruturado, utilizando blocos de código para comandos de terminal (`bash`). 
