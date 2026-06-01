## Resumo Executivo

- **Recomendação:** **Rollback imediato** para a versão **v2.47.0**.

_**Status do Incidente:** Crítico (P1). Latência p99 degradada para 8.1s, taxa de erro em 11.7%, disjuntor (_circuit breaker_) aberto e o Reactor acumulando mais de 50 mil mensagens com_ consumer lag* de 18 minutos e em crescimento exponencial.

- **Ação Recomendada:** Interromper imediatamente qualquer tentativa de escalonamento da infraestrutura e disparar o rollback via Argo CD.

---
## Análise da Causa Raiz

O incidente foi provocado por um efeito cascata gerado pela combinação de três fatores introduzidos na versão `v2.48.0` sob tráfego de pico:

1. **Subdimensionamento e Contenção no Pool:** A nova biblioteca interna de conexões fixou o limite de conexões em `max=20` por pod. Com o HPA no teto (12 pods), o limite total que a API consegue abrir é de exatamente 240 conexões ($12 \\times 20 = 240$).
2. **Saturação do RDS:** O banco de dados atingiu $240$ de seu limite físico de $250$ conexões ativas. O novo endpoint `POST /v2/transactions/batch` introduziu operações concorrentes mais pesadas e longas, retendo as conexões por mais tempo.
3. **Efeito Cascata:** Com o banco saturado, o pool local esgotou e gerou filas de espera gigantescas (`waiting=147`). Como o timeout foi agressivamente reduzido de 5s para 2s, as requisições estouraram por _context deadline exceeded_, abrindo o _circuit breaker_ (87% de falha) e travando o consumo de mensagens da fila do Reactor.

---

## Justificativa Técnica da Decisão

### Opção A: Scaling Emergencial (Aumentar Pool e RDS) — **REJEITADA**

- **Inviabilidade Matemática:** Elevar o parâmetro do pool nos pods para dar vazão à fila (ex: `max=40`) exigiria instantaneamente $12 \\times 40 = 480$ conexões. Isso causaria um estouro imediato do limite rígido do RDS (250), gerando um erro global de `Too many connections` e derrubando a base por completo.
- **Risco Operacional:** Alterar o limite físico de conexões (`max_connections`) no RDS exige a modificação de Parameter Groups e o reboot da instância master, estendendo o tempo de indisponibilidade em uma janela crítica.

### Opção B: Rollback Imediato para v2.47.0 — **ESCOLHIDA**

_**Mitigação Eficaz:** A versão `v2.47.0` reverte a biblioteca do cliente para o comportamento elástico testado, desativa o endpoint de_ batch* (eliminando a contenção de travas) e restaura o timeout seguro de 5s. Isso permite ao RDS absorver as queries pendentes de forma assíncrona e gradual, restabelecendo a saúde do ambiente sem sobrecarga estrutural.

---

## Plano de Ação de Emergência (Call de Crise)

1. **[IMEDIATO] Executar Rollback:** Acessar o Argo CD e realizar o sync override da `chronos-api` para a versão estável `v2.47.0`.
2. **[+3 min] Monitorar RDS:** Validar via monitoramento que as conexões ativas no RDS recuaram do patamar crítico de 240 e que o log parou de registrar `connection pool exhausted`.
3. **[+5 min] Restabelecer Fluxo:** Verificar o fechamento automático do _circuit breaker_ após a normalização das latências.
4. **[+10 min] Expurgar o Consumer Lag:** Acompanhar a fila `chronos-transactions` no Reactor. Uma vez que os pods apresentem consumo estável de CPU (62%) e Memória (71%), aumentar temporariamente a capacidade do HPA para acelerar o escoamento das ~50k mensagens remanescentes.