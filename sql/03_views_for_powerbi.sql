/* =====================================================
   Views feeding the Power BI dashboard (star-ish schema)
   ===================================================== */
USE OlistEcommerce;
GO

/* ---------- Fact: orders (grain = order) ---------- */
CREATE OR ALTER VIEW vw_fact_orders AS
SELECT
    o.order_id,
    o.order_status,
    CAST(o.order_purchase_timestamp AS DATE)          AS order_date,
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    pay.payment_total,
    pay.payment_types,
    r.review_score,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)      AS delivery_days,
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 1 ELSE 0 END                                                          AS is_late,
    CASE WHEN o.order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END         AS is_delivered
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
OUTER APPLY (
    SELECT SUM(p.payment_value) AS payment_total,
           STRING_AGG(p.payment_type, ', ') AS payment_types
    FROM order_payments p WHERE p.order_id = o.order_id
) pay
OUTER APPLY (
    SELECT TOP 1 review_score
    FROM order_reviews rv WHERE rv.order_id = o.order_id
    ORDER BY rv.review_creation_date DESC
) r;
GO

/* ---------- Fact: order items (grain = item) ---------- */
CREATE OR ALTER VIEW vw_fact_order_items AS
SELECT
    oi.order_id,
    oi.order_item_id,
    CAST(o.order_purchase_timestamp AS DATE)                            AS order_date,
    o.order_status,
    ISNULL(ct.product_category_name_english, pr.product_category_name)  AS category,
    s.seller_state,
    oi.price,
    oi.freight_value
FROM order_items oi
JOIN orders o    ON o.order_id  = oi.order_id
JOIN products pr ON pr.product_id = oi.product_id
LEFT JOIN category_translation ct ON ct.product_category_name = pr.product_category_name
LEFT JOIN sellers s ON s.seller_id = oi.seller_id;
GO

/* ---------- Dim: customer RFM segments ---------- */
CREATE OR ALTER VIEW vw_customer_rfm AS
WITH rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(DAY, MAX(o.order_purchase_timestamp),
                 (SELECT MAX(order_purchase_timestamp) FROM orders)) AS recency_days,
        COUNT(DISTINCT o.order_id)                                   AS frequency,
        SUM(p.payment_value)                                         AS monetary
    FROM customers c
    JOIN orders o         ON o.customer_id = c.customer_id
    JOIN order_payments p ON p.order_id = o.order_id
    WHERE o.order_status <> 'canceled'
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    CASE
        WHEN recency_days <= 90  AND frequency >= 2 THEN 'Champions'
        WHEN recency_days <= 90                     THEN 'Recent'
        WHEN recency_days <= 365 AND frequency >= 2 THEN 'Loyal-at-risk'
        WHEN recency_days <= 365                    THEN 'Cooling down'
        ELSE 'Lost'
    END AS segment
FROM rfm;
GO

SELECT 'vw_fact_orders' v, COUNT(*) n FROM vw_fact_orders
UNION ALL SELECT 'vw_fact_order_items', COUNT(*) FROM vw_fact_order_items
UNION ALL SELECT 'vw_customer_rfm', COUNT(*) FROM vw_customer_rfm;
GO
