## Resumo Executivo

**Recomendação Direta de Ação Imediata: Opção B (Rollback imediato para v2.47.0)**. A degradação severa do ambiente (latência p99 em 8100ms e taxa de erro de 11.7%) é consequência direta do esgotamento do pool de conexões com o banco de dados (Ledger). Tentar escalar a infraestrutura neste momento (Opção A) geraria um efeito cascata catastrófico. O rollback é a única via segura para estancar a falha e mitigar o lag do SQS.

## Análise da Causa Raiz

O incidente foi disparado pelo deploy da `v2.48.0` devido à combinação letal de três alterações sob carga crescente:

1. **Exaustão Matemática:** O cluster está no máximo (12 pods) com 20 conexões ativas por pod, resultando em 240 conexões, batendo no limite crítico de 250 do RDS.
2. **Gargalo no Endpoint:** O novo endpoint `POST /v2/transactions/batch` é computacionalmente pesado e retém conexões no pool por mais tempo que o esperado.
3. **Timeouts Agressivos:** A redução do timeout do Ledger para 2s aliada à alta latência das queries gerou disparos de `context deadline exceeded`. As threads ficam presas (147 em fila de espera), derrubando a comunicação, forçando a abertura do circuit breaker e impedindo o envio das mensagens para o Reactor, o que gerou o acúmulo das mais de 50.000 mensagens na fila.

## Justificativa Técnica da Decisão

_**O Perigo da Opção A (Scaling Emergencial):** Aumentar os limites de conexão do RDS e do pool nos pods é um anti-pattern conhecido neste cenário. Injetar mais tráfego e concorrência num banco de dados que já está derrubando requisições por timeout não resolverá a vazão. Pelo contrário, causará lock contention massivo e possível_ meltdown* (queda total) do PostgreSQL, agravando o incidente.

- **A Eficiência da Opção B (Rollback):** O rollback para a `v2.47.0` elimina o endpoint de batch não otimizado, restaura a resiliência do timeout de 5s e desfaz a mudança de biblioteca de pool. Isso imediatamente desobstrui o pipeline do banco de dados, fechando o circuit breaker da API e permitindo que a aplicação volte a consumir as 800 mensagens/min represadas no Reactor.

## Plano de Ação de Emergência

1. **Rollback Imediato (Argo CD):** Executar `argocd app rollback chronos-api` para restaurar o ReplicaSet correspondente à `v2.47.0`.
2. **Descompressão do Ledger:** Acompanhar pelo Grafana a queda das conexões ativas no RDS (deve afastar de 240) e o retorno do p99 para valores basais (~400ms).
3. **Acompanhamento do Reactor:** Confirmar no painel SQS se a taxa de consumo de mensagens superou o fluxo de entrada (>800/min), confirmando que o lag de 18 minutos começou a ser drenado.
4. **Code Freeze Temporário:** Bloquear novos deploys da API. O endpoint de batch e a nova biblioteca de connection pooling precisarão de refatoração, análise em ambiente de staging e testes de carga severos antes de voltarem ao pipeline de release.
