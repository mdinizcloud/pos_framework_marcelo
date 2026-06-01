# ROLE
Você é um engenheiro  SRE especializado em infraestruturas críticas de alta escala (Kubernetes, AWS/Azure, Bancos de Dados Relacionais). 

# INPUT
Analise os seguintes artefatos coletados do ambiente de produção:
## Evento do deploy anterior (ontem, 18:42 UTC):
- Deploy chronos-api: v2.47.0 -> v2.48.0
- Argo CD sync: 2026-04-23 18:42:11 UTC
- Changelog:
  * Adicionado endpoint POST /v2/transactions/batch
  * Refatorado cliente do Ledger (pool de conexoes movido para nova biblioteca interna)
  * Bump de psycopg 3.1.18 -> 3.2.0
  * Reduzido timeout do Ledger de 5s para 2s

## Métricas do Beacon nos últimos 30 minutos:
timestamp                p99_latency_ms   req_rate_s   err_rate_pct
2026-04-24 13:30 UTC     420              1200         0.2
2026-04-24 13:45 UTC     510              1450         0.3
2026-04-24 14:00 UTC     780              1780         0.8
2026-04-24 14:10 UTC     2400             2100         4.5
2026-04-24 14:15 UTC     5200             2400         8.2
2026-04-24 14:20 UTC     8100             2650         11.7

## Trecho do log do pod chronos-api-79c4d8b9-xk2jp:
2026-04-24 14:19:48 [ERROR] [ledger-client] connection pool exhausted (max=20, active=20, waiting=147)
2026-04-24 14:19:49 [WARN]  [ledger-client] query timeout after 2000ms: SELECT ... FROM transactions WHERE ...
2026-04-24 14:19:49 [ERROR] [handler] POST /v2/transactions/batch failed: context deadline exceeded
2026-04-24 14:19:50 [ERROR] [ledger-client] connection reset by peer
2026-04-24 14:19:51 [WARN]  [circuit-breaker] ledger-client OPEN (threshold 50%, current 87%)
2026-04-24 14:19:52 [ERROR] [reactor] failed to publish message: chronos-api upstream error

## Estado do Reactor (fila chronos-transactions):
- 50.127 mensagens acumuladas, crescendo a ~800/min.
- Consumer lag atual: 18 minutos e aumentando.

## Estado do cluster:
- Chronos: 12/12 pods running (HPA no máximo).
- CPU médio dos pods: 62%.
- Memória média dos pods: 71%.
- Conexões ativas ao Ledger: 240/250 (limite do RDS).

# STEPS
Faça a análise seguindo estes passos internos antes de criar o postmortem:
1. Correlacione o aumento de tráfego (`req_rate_s`) com a degradação de latência (`p99`) e taxa de erro (`err_rate_pct`).

2. Identifique o gargalo principal olhando os logs do `ledger-client` e as conexões ativas do banco de dados (RDS).

3. Avalie o impacto do novo endpoint `POST /v2/transactions/batch` introduzido na v2.48.0 e a alteração da biblioteca do pool de conexões.

4. Compare matematicamente as duas opções de mitigação:
   - Opção A: Scaling emergencial (Aumentar conexões do RDS e pool).
   - Opção B: Rollback imediato para v2.47.0.

5. Determine qual ação resolve o incidente de forma imediata e mitiga o lag do Reactor.

# EXPECTATION
Gere um Postmortem Técnico Executivo direto curto, organizado em:

- **Resumo Executivo:** Recomendação direta de ação imediata (Rollback vs Scaling).
- **Análise da Causa Raiz:** O que quebrou e por quê direto e curto (baseados nos logs e métricas).
- **Justificativa Técnica da Decisão:** Explicação por que a opção escolhida é a única viável, evidenciando o perigo da outra opção.
- **Plano de Ação de Emergência:** Lista ordenada por prioridade das ações a serem tomadas na call.

Gere o output em um artefato markdown