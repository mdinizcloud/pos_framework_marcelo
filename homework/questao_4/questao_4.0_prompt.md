----
# TASK (Tarefa / Papel)
Você é um Engenheiro de Dados Sênior especialista em PostgreSQL. 

Extrair métricas consolidadas do banco de dados Ledger para uma apresentação de crescimento de transações.

# ACTION (Ação / Instruções específicas)
Escreva uma query SQL em PostgreSQL que atenda estritamente aos seguintes requisitos técnicos baseados nas tabelas abaixo:

```sql
CREATE TABLE transactions (
  id              BIGSERIAL PRIMARY KEY,
  customer_id     BIGINT NOT NULL REFERENCES customers(id),
  category        VARCHAR(32) NOT NULL,
  amount_cents    BIGINT NOT NULL,
  status          VARCHAR(16) NOT NULL,
  payment_method  VARCHAR(16),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at    TIMESTAMPTZ
);

CREATE TABLE customers (
  id          BIGSERIAL PRIMARY KEY,
  segment     VARCHAR(16) NOT NULL,
  country     CHAR(2) NOT NULL,
  signup_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```
# DEMANDA E REGRAS DE NEGÓCIO] 

Categorias em produção hoje: subscription, one_time, refund e credit_adjustment. 

Só entra no relatório quem tem status = 'completed'. 

O campo amount_cents está em centavos de real e precisa aparecer na saída em reais com 2 casas decimais. 

Ordenação final: mês crescente, depois categoria crescente." --- 
# GOAL 
Entregue uma única query SQL limpa, formatada e otimizada (utilizando os índices acima). 
Exiba as colunas perfeitamente calculadas e ordenadas conforme exigido. 

Retorne apenas o código SQL e uma breve explicação das funções utilizadas para a conversão de valores e formatação de datas.


