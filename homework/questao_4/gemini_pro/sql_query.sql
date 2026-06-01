SELECT 
    -- 1. Agrupamento por mês e ano a partir do campo TIMESTAMPTZ
    TO_CHAR(t.created_at, 'YYYY-MM') AS mes_ano,
    
    -- 2. Categoria da transação
    t.category,
    
    -- 3. Volume total formatado em Reais (conversão de centavos)
    ROUND(SUM(t.amount_cents) / 100.0, 2) AS volume_total_brl,
    
    -- 4. Contagem total de transações completadas no período
    COUNT(t.id) AS quantidade_transacoes,
    
    -- 5. Ticket médio também convertido para Reais com 2 casas decimais
    ROUND(AVG(t.amount_cents) / 100.0, 2) AS ticket_medio_brl
FROM 
    transactions t
INNER JOIN 
    customers c ON t.customer_id = c.id
WHERE 
    t.status = 'completed'
GROUP BY 
    TO_CHAR(t.created_at, 'YYYY-MM'),
    t.category
ORDER BY 
    mes_ano ASC,
    t.category ASC;