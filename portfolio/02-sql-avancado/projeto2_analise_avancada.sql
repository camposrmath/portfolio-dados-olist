-- =============================================================================
-- PROJETO 2 | Análise Avançada com SQL — Olist E-commerce
-- Banco de dados: db_olist.sqlite
-- Ferramentas: CTEs, Window Functions (LAG, RANK, SUM OVER), Subqueries
-- Autor: Portfólio Jr Data Analyst
-- =============================================================================


-- =============================================================================
-- SEÇÃO 1 | CRESCIMENTO MENSAL DE RECEITA (MoM)
-- Usando CTE + LAG para calcular crescimento mês a mês.
-- LAG() busca o valor da linha anterior na janela ordenada por mês.
-- =============================================================================

WITH receita_mensal AS (
    SELECT
        strftime('%Y-%m', o.order_purchase_timestamp)   AS mes,
        COUNT(DISTINCT o.order_id)                       AS pedidos,
        ROUND(SUM(op.payment_value), 2)                  AS receita
    FROM orders o
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    mes,
    pedidos,
    receita                                                          AS receita_r$,
    LAG(receita) OVER (ORDER BY mes)                                 AS receita_mes_anterior_r$,
    ROUND(
        (receita - LAG(receita) OVER (ORDER BY mes))
        / LAG(receita) OVER (ORDER BY mes) * 100
    , 1)                                                             AS crescimento_pct
FROM receita_mensal
ORDER BY mes;


-- =============================================================================
-- SEÇÃO 2 | RANKING DE VENDEDORES POR FATURAMENTO
-- RANK() ordena vendedores do maior para o menor faturamento.
-- DENSE_RANK() não pula posições em caso de empate.
-- =============================================================================

WITH performance_vendedor AS (
    SELECT
        s.seller_id,
        s.seller_state,
        s.seller_city,
        COUNT(DISTINCT oi.order_id)         AS total_pedidos,
        ROUND(SUM(oi.price), 2)             AS faturamento_r$,
        ROUND(AVG(oi.price), 2)             AS preco_medio_r$,
        ROUND(AVG(r.review_score), 2)       AS nota_media_clientes
    FROM order_items oi
    JOIN sellers s        ON oi.seller_id  = s.seller_id
    JOIN orders o         ON oi.order_id   = o.order_id
    LEFT JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1, 2, 3
)
SELECT
    RANK() OVER (ORDER BY faturamento_r$ DESC)         AS ranking_faturamento,
    seller_id,
    seller_state,
    seller_city,
    total_pedidos,
    faturamento_r$,
    preco_medio_r$,
    nota_media_clientes
FROM performance_vendedor
ORDER BY ranking_faturamento
LIMIT 20;


-- =============================================================================
-- SEÇÃO 3 | ANÁLISE DE SLA DE ENTREGA (ON-TIME vs ATRASADO)
-- Comparamos data de entrega real vs estimada.
-- SUM() OVER() calcula o total geral para obter o percentual.
-- =============================================================================

WITH entregas AS (
    SELECT
        c.customer_state,
        CASE
            WHEN order_delivered_customer_date IS NULL          THEN 'Sem registro'
            WHEN order_delivered_customer_date
                 <= order_estimated_delivery_date               THEN 'No prazo'
            ELSE                                                     'Atrasado'
        END AS status_entrega,
        ROUND(
            JULIANDAY(order_delivered_customer_date)
            - JULIANDAY(order_purchase_timestamp)
        , 1) AS dias_ate_entrega,
        ROUND(
            JULIANDAY(order_estimated_delivery_date)
            - JULIANDAY(order_purchase_timestamp)
        , 1) AS dias_estimados
    FROM orders o
    JOIN customer c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
)
-- Resumo geral de SLA
SELECT
    status_entrega,
    COUNT(*)                                              AS total,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS pct_total,
    ROUND(AVG(dias_ate_entrega), 1)                       AS media_dias_entrega,
    ROUND(AVG(dias_estimados), 1)                         AS media_dias_estimado
FROM entregas
GROUP BY 1
ORDER BY total DESC;

-- SLA por estado (top 10 estados com mais pedidos)
WITH entregas_estado AS (
    SELECT
        c.customer_state,
        COUNT(*) AS total_pedidos,
        SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date
                 THEN 1 ELSE 0 END) AS entregues_no_prazo,
        ROUND(AVG(JULIANDAY(order_delivered_customer_date)
                  - JULIANDAY(order_purchase_timestamp)), 1) AS media_dias_entrega
    FROM orders o
    JOIN customer c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    customer_state,
    total_pedidos,
    entregues_no_prazo,
    total_pedidos - entregues_no_prazo                              AS atrasados,
    ROUND(100.0 * entregues_no_prazo / total_pedidos, 1)            AS pct_no_prazo,
    media_dias_entrega
FROM entregas_estado
ORDER BY total_pedidos DESC
LIMIT 10;


-- =============================================================================
-- SEÇÃO 4 | CLIENTES QUE COMPRARAM MAIS DE UMA VEZ
-- Subquery para identificar clientes recorrentes.
-- Insight: em marketplaces, recompra é rara — quantos voltam?
-- =============================================================================

WITH compras_por_cliente AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)      AS num_pedidos,
        ROUND(SUM(op.payment_value), 2) AS gasto_total_r$,
        MIN(o.order_purchase_timestamp) AS primeira_compra,
        MAX(o.order_purchase_timestamp) AS ultima_compra
    FROM orders o
    JOIN customer c        ON o.customer_id = c.customer_id
    JOIN order_payments op ON o.order_id   = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
-- Resumo: compradores únicos vs recorrentes
SELECT
    CASE
        WHEN num_pedidos = 1  THEN '1 compra (único)'
        WHEN num_pedidos = 2  THEN '2 compras'
        WHEN num_pedidos = 3  THEN '3 compras'
        WHEN num_pedidos >= 4 THEN '4+ compras'
    END AS perfil_compra,
    COUNT(*)                                              AS total_clientes,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS pct_clientes,
    ROUND(AVG(gasto_total_r$), 2)                         AS gasto_medio_r$
FROM compras_por_cliente
GROUP BY 1
ORDER BY total_clientes DESC;


-- =============================================================================
-- SEÇÃO 5 | PARTICIPAÇÃO DE MERCADO POR CATEGORIA (MARKET SHARE)
-- SUM() OVER() calcula o total geral sem GROUP BY,
-- permitindo calcular o % de cada categoria no total.
-- =============================================================================

WITH receita_categoria AS (
    SELECT
        COALESCE(pc.product_category_name_english,
                 p.product_category_name)       AS categoria,
        ROUND(SUM(oi.price), 2)                  AS receita
    FROM order_items oi
    JOIN products p                 ON oi.product_id          = p.product_id
    LEFT JOIN product_category_name pc ON p.product_category_name = pc.product_category_name
    JOIN orders o                   ON oi.order_id            = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    categoria,
    receita                                                     AS receita_r$,
    RANK() OVER (ORDER BY receita DESC)                          AS ranking,
    ROUND(100.0 * receita / SUM(receita) OVER (), 2)             AS market_share_pct,
    ROUND(SUM(receita) OVER (ORDER BY receita DESC
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          / SUM(receita) OVER () * 100, 1)                       AS market_share_acumulado_pct
FROM receita_categoria
ORDER BY receita DESC
LIMIT 15;


-- =============================================================================
-- SEÇÃO 6 | TEMPO MÉDIO DE ENTREGA POR ESTADO
-- Usando JULIANDAY para calcular diferença entre datas no SQLite.
-- =============================================================================

SELECT
    c.customer_state                                          AS estado,
    COUNT(DISTINCT o.order_id)                                AS pedidos,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date)
              - JULIANDAY(o.order_purchase_timestamp)), 1)    AS media_dias_entrega,
    ROUND(MIN(JULIANDAY(o.order_delivered_customer_date)
              - JULIANDAY(o.order_purchase_timestamp)), 1)    AS entrega_mais_rapida_dias,
    ROUND(MAX(JULIANDAY(o.order_delivered_customer_date)
              - JULIANDAY(o.order_purchase_timestamp)), 1)    AS entrega_mais_lenta_dias
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
HAVING pedidos >= 100
ORDER BY media_dias_entrega
LIMIT 15;


-- =============================================================================
-- SEÇÃO 7 | SCORE DE PERFORMANCE DO VENDEDOR (CTE MÚLTIPLOS)
-- Combina faturamento, volume de pedidos e satisfação do cliente
-- em um score ponderado para ranquear os melhores vendedores.
-- =============================================================================

WITH metricas_vendedor AS (
    SELECT
        s.seller_id,
        s.seller_state,
        COUNT(DISTINCT oi.order_id)          AS pedidos,
        ROUND(SUM(oi.price), 2)              AS faturamento,
        ROUND(AVG(r.review_score), 2)        AS nota_media,
        ROUND(100.0 * SUM(CASE
                WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
                THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_entrega_no_prazo
    FROM order_items oi
    JOIN sellers s          ON oi.seller_id  = s.seller_id
    JOIN orders o           ON oi.order_id   = o.order_id
    LEFT JOIN order_reviews r ON o.order_id  = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1, 2
    HAVING pedidos >= 20
),
normalizado AS (
    SELECT
        seller_id,
        seller_state,
        pedidos,
        faturamento,
        nota_media,
        pct_entrega_no_prazo,
        -- Score ponderado: 40% faturamento + 40% satisfação + 20% entrega no prazo
        ROUND(
            0.40 * (CAST(faturamento AS FLOAT) / MAX(faturamento) OVER ()) * 100
          + 0.40 * (nota_media / 5.0) * 100
          + 0.20 * (pct_entrega_no_prazo)
        , 1) AS score_performance
    FROM metricas_vendedor
)
SELECT
    RANK() OVER (ORDER BY score_performance DESC) AS posicao,
    seller_id,
    seller_state,
    pedidos,
    faturamento                                   AS faturamento_r$,
    nota_media,
    pct_entrega_no_prazo,
    score_performance
FROM normalizado
ORDER BY score_performance DESC
LIMIT 15;
