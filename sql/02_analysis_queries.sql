/* =====================================================
   Olist E-Commerce - Analysis Queries
   ===================================================== */
USE OlistEcommerce;
GO

/* 1. Monthly revenue trend */
SELECT
    FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
    COUNT(DISTINCT o.order_id)                    AS orders,
    CAST(SUM(p.payment_value) AS DECIMAL(12,2))   AS revenue
FROM orders o
JOIN order_payments p ON p.order_id = o.order_id
WHERE o.order_status <> 'canceled'
GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
ORDER BY order_month;

/* 2. Top 10 product categories by revenue */
SELECT TOP 10
    ISNULL(ct.product_category_name_english, pr.product_category_name) AS category,
    COUNT(DISTINCT oi.order_id)                 AS orders,
    CAST(SUM(oi.price) AS DECIMAL(12,2))        AS items_revenue,
    CAST(AVG(oi.price) AS DECIMAL(10,2))        AS avg_item_price
FROM order_items oi
JOIN products pr             ON pr.product_id = oi.product_id
LEFT JOIN category_translation ct ON ct.product_category_name = pr.product_category_name
GROUP BY ISNULL(ct.product_category_name_english, pr.product_category_name)
ORDER BY items_revenue DESC;

/* 3. Average delivery time vs promised, by state */
SELECT
    c.customer_state,
    COUNT(*)                                                                              AS delivered_orders,
    AVG(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date))       AS avg_delivery_days,
    AVG(DATEDIFF(DAY, o.order_delivered_customer_date, o.order_estimated_delivery_date))  AS avg_days_early
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

/* 4. Month-over-month revenue growth % (window function) */
WITH monthly AS (
    SELECT
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS m,
        SUM(p.payment_value)                          AS revenue
    FROM orders o
    JOIN order_payments p ON p.order_id = o.order_id
    WHERE o.order_status <> 'canceled'
    GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT
    m,
    CAST(revenue AS DECIMAL(12,2))                                        AS revenue,
    CAST(LAG(revenue) OVER (ORDER BY m) AS DECIMAL(12,2))                 AS prev_month,
    CAST(100.0 * (revenue - LAG(revenue) OVER (ORDER BY m))
         / NULLIF(LAG(revenue) OVER (ORDER BY m), 0) AS DECIMAL(12,1))    AS growth_pct
FROM monthly
ORDER BY m;

/* 5. Customer satisfaction: review score vs delivery delay */
SELECT
    r.review_score,
    COUNT(*) AS orders,
    AVG(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS avg_delivery_days,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
             THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS late_delivery_pct
FROM order_reviews r
JOIN orders o ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY r.review_score
ORDER BY r.review_score;

/* 6. RFM customer segmentation */
WITH rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(DAY, MAX(o.order_purchase_timestamp),
                 (SELECT MAX(order_purchase_timestamp) FROM orders)) AS recency_days,
        COUNT(DISTINCT o.order_id)                                   AS frequency,
        SUM(p.payment_value)                                         AS monetary
    FROM customers c
    JOIN orders o          ON o.customer_id = c.customer_id
    JOIN order_payments p  ON p.order_id = o.order_id
    WHERE o.order_status <> 'canceled'
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN recency_days <= 90  AND frequency >= 2 THEN 'Champions'
        WHEN recency_days <= 90                     THEN 'Recent'
        WHEN recency_days <= 365 AND frequency >= 2 THEN 'Loyal-at-risk'
        WHEN recency_days <= 365                    THEN 'Cooling down'
        ELSE 'Lost'
    END                                        AS segment,
    COUNT(*)                                   AS customers,
    CAST(AVG(monetary) AS DECIMAL(10,2))       AS avg_spend
FROM rfm
GROUP BY CASE
        WHEN recency_days <= 90  AND frequency >= 2 THEN 'Champions'
        WHEN recency_days <= 90                     THEN 'Recent'
        WHEN recency_days <= 365 AND frequency >= 2 THEN 'Loyal-at-risk'
        WHEN recency_days <= 365                    THEN 'Cooling down'
        ELSE 'Lost'
    END
ORDER BY customers DESC;
