-- =============================================================================
-- PROJETO 1 | Análise de KPIs Básicos — Olist E-commerce
-- Banco de dados: db_olist.sqlite
-- Ferramentas: SQL (JOINs, GROUP BY, HAVING, funções de agregação)
-- Autor: Portfólio Jr Data Analyst
-- =============================================================================


-- =============================================================================
-- SEÇÃO 1 | KPIs GERAIS DO NEGÓCIO
-- Visão geral de pedidos, clientes e faturamento (somente pedidos entregues)
-- =============================================================================

SELECT
    COUNT(DISTINCT o.order_id)                                          AS total_pedidos,
    COUNT(DISTINCT c.customer_unique_id)                                AS total_clientes_unicos,
    ROUND(SUM(op.payment_value), 2)                                     AS faturamento_total_r$,
    ROUND(SUM(op.payment_value) / COUNT(DISTINCT o.order_id), 2)       AS ticket_medio_r$,
    ROUND(SUM(oi.freight_value), 2)                                     AS frete_total_r$,
    ROUND(AVG(or2.review_score), 2)                                     AS nota_media_clientes
FROM orders o
JOIN customer c             ON o.customer_id    = c.customer_id
JOIN order_payments op      ON o.order_id       = op.order_id
JOIN order_items oi         ON o.order_id       = oi.order_id
LEFT JOIN order_reviews or2 ON o.order_id       = or2.order_id
WHERE o.order_status = 'delivered';


-- =============================================================================
-- SEÇÃO 2 | EVOLUÇÃO MENSAL DE RECEITA E PEDIDOS
-- Quanto vendemos a cada mês? Volume e receita lado a lado.
-- =============================================================================

SELECT
    strftime('%Y-%m', o.order_purchase_timestamp)   AS mes_ano,
    COUNT(DISTINCT o.order_id)                       AS total_pedidos,
    COUNT(DISTINCT c.customer_unique_id)             AS clientes_unicos,
    ROUND(SUM(op.payment_value), 2)                  AS receita_r$,
    ROUND(AVG(op.payment_value), 2)                  AS ticket_medio_r$
FROM orders o
JOIN customer c        ON o.customer_id = c.customer_id
JOIN order_payments op ON o.order_id   = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;


-- =============================================================================
-- SEÇÃO 3 | TOP 10 CATEGORIAS POR RECEITA
-- Quais categorias geram mais dinheiro?
-- Usamos COALESCE para exibir o nome em inglês quando disponível.
-- =============================================================================

SELECT
    COALESCE(pc.product_category_name_english,
             p.product_category_name)            AS categoria,
    COUNT(DISTINCT oi.order_id)                  AS total_pedidos,
    COUNT(DISTINCT oi.product_id)                AS produtos_distintos,
    ROUND(SUM(oi.price), 2)                      AS receita_r$,
    ROUND(AVG(oi.price), 2)                      AS preco_medio_r$
FROM order_items oi
JOIN products p                 ON oi.product_id          = p.product_id
LEFT JOIN product_category_name pc ON p.product_category_name = pc.product_category_name
JOIN orders o                   ON oi.order_id            = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY receita_r$ DESC
LIMIT 10;


-- =============================================================================
-- SEÇÃO 4 | PERFORMANCE POR ESTADO
-- Quais estados do Brasil mais compram? Receita e volume por UF.
-- =============================================================================

SELECT
    c.customer_state                            AS estado,
    COUNT(DISTINCT o.order_id)                  AS total_pedidos,
    COUNT(DISTINCT c.customer_unique_id)         AS clientes_unicos,
    ROUND(SUM(op.payment_value), 2)              AS receita_r$,
    ROUND(AVG(op.payment_value), 2)              AS ticket_medio_r$
FROM orders o
JOIN customer c        ON o.customer_id = c.customer_id
JOIN order_payments op ON o.order_id   = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY total_pedidos DESC
LIMIT 15;


-- =============================================================================
-- SEÇÃO 5 | FORMAS DE PAGAMENTO
-- Como os clientes preferem pagar?
-- =============================================================================

SELECT
    payment_type                                    AS forma_pagamento,
    COUNT(DISTINCT order_id)                         AS total_transacoes,
    ROUND(SUM(payment_value), 2)                     AS volume_total_r$,
    ROUND(AVG(payment_installments), 1)              AS media_parcelas,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_total
FROM order_payments
GROUP BY 1
ORDER BY total_transacoes DESC;


-- =============================================================================
-- SEÇÃO 6 | STATUS DOS PEDIDOS
-- Qual a distribuição de status dos pedidos?
-- =============================================================================

SELECT
    order_status                                         AS status,
    COUNT(*)                                              AS quantidade,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)   AS pct_total
FROM orders
GROUP BY 1
ORDER BY quantidade DESC;


-- =============================================================================
-- SEÇÃO 7 | SATISFAÇÃO DOS CLIENTES (REVIEW SCORES)
-- Como os clientes avaliam seus pedidos?
-- =============================================================================

-- Distribuição das notas
SELECT
    review_score                                          AS nota,
    COUNT(*)                                               AS quantidade,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_total
FROM order_reviews
GROUP BY 1
ORDER BY 1;

-- Nota média por categoria (top 10 categorias com mais avaliações)
SELECT
    COALESCE(pc.product_category_name_english,
             p.product_category_name)        AS categoria,
    COUNT(r.review_id)                        AS total_avaliacoes,
    ROUND(AVG(r.review_score), 2)             AS nota_media,
    SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) AS avaliacoes_positivas,
    SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) AS avaliacoes_negativas
FROM order_reviews r
JOIN orders o                       ON r.order_id             = o.order_id
JOIN order_items oi                 ON o.order_id             = oi.order_id
JOIN products p                     ON oi.product_id          = p.product_id
LEFT JOIN product_category_name pc  ON p.product_category_name = pc.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY 1
HAVING total_avaliacoes >= 100
ORDER BY nota_media DESC
LIMIT 10;
