-- =============================================================
-- Tableau Data Sources — E-Commerce BI Dashboard
-- Connect: Tableau → PostgreSQL → Custom SQL (je Query)
-- Dashboard Theme: "What drives revenue & delivery failures?"
-- =============================================================


-- ─────────────────────────────────────────────────────────────
-- DS 1: REVENUE TREND (Sheet: Monthly Revenue + Rolling Avg)
-- Marks: Line | Dim: month | Measures: revenue, rolling_avg, mom_growth_pct
-- ─────────────────────────────────────────────────────────────
SELECT
    DATE_TRUNC('month', order_date)::DATE AS month,
    SUM(order_value)                      AS revenue,
    COUNT(*)                              AS orders,
    ROUND(AVG(SUM(order_value)) OVER (
        ORDER BY DATE_TRUNC('month', order_date)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                 AS rolling_avg_3m,
    ROUND(100.0 * (SUM(order_value) - LAG(SUM(order_value)) OVER (ORDER BY DATE_TRUNC('month', order_date)))
        / NULLIF(LAG(SUM(order_value)) OVER (ORDER BY DATE_TRUNC('month', order_date)), 0), 1) AS mom_growth_pct
FROM ecommerce_data
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;


-- ─────────────────────────────────────────────────────────────
-- DS 2: CATEGORY SCORECARD (Sheet: Revenue vs. Delivery Risk)
-- Marks: Bar + Color | Dim: product_category
-- Measures: total_revenue, delivery_rate_pct, revenue_at_risk
-- ─────────────────────────────────────────────────────────────
SELECT
    product_category,
    COUNT(*)                                     AS total_orders,
    ROUND(SUM(order_value), 2)                   AS total_revenue,
    ROUND(AVG(order_value), 2)                   AS avg_order_value,
    ROUND(AVG(delivered::NUMERIC) * 100, 1)      AS delivery_rate_pct,
    SUM(1 - delivered)                           AS failed_deliveries,
    ROUND(SUM((1 - delivered) * order_value), 2) AS revenue_at_risk
FROM ecommerce_data
GROUP BY product_category
ORDER BY total_revenue DESC;


-- ─────────────────────────────────────────────────────────────
-- DS 3: DELIVERY FAILURE HEATMAP (Sheet: Category × Month)
-- Marks: Square/Highlight Table | Dim: product_category, year_month
-- Measure: failure_rate_pct (Color)
-- ─────────────────────────────────────────────────────────────
SELECT
    product_category,
    TO_CHAR(order_date, 'YYYY-MM')               AS year_month,
    COUNT(*)                                     AS total_orders,
    SUM(1 - delivered)                           AS failed_deliveries,
    ROUND(AVG(1 - delivered::NUMERIC) * 100, 1)  AS failure_rate_pct
FROM ecommerce_data
GROUP BY product_category, TO_CHAR(order_date, 'YYYY-MM')
ORDER BY product_category, year_month;


-- ─────────────────────────────────────────────────────────────
-- DS 4: PAYMENT METHOD ANALYSIS (Sheet: Payment vs. Delivery)
-- Marks: Bar | Dim: payment_method
-- Measures: delivery_rate_pct, avg_order_value, lost_revenue
-- ─────────────────────────────────────────────────────────────
SELECT
    payment_method,
    COUNT(*)                                     AS total_orders,
    ROUND(AVG(delivered::NUMERIC) * 100, 1)      AS delivery_rate_pct,
    ROUND(AVG(order_value), 2)                   AS avg_order_value,
    ROUND(SUM((1 - delivered) * order_value), 2) AS lost_revenue,
    ROUND(AVG(delivered::NUMERIC) * 100, 1)
        - ROUND(AVG(AVG(delivered::NUMERIC)) OVER () * 100, 1) AS vs_avg_pct
FROM ecommerce_data
GROUP BY payment_method
ORDER BY delivery_rate_pct;


-- ─────────────────────────────────────────────────────────────
-- DS 5: CUSTOMER COHORT RETENTION (Sheet: Cohort Heatmap)
-- Marks: Highlight Table | Dim: cohort_month, month_number
-- Measure: retention_rate_pct (Color), active_customers (Label)
-- ─────────────────────────────────────────────────────────────
SELECT
    f.cohort_month,
    (DATE_PART('year',  DATE_TRUNC('month', e.order_date))
     - DATE_PART('year',  f.cohort_month)) * 12
    + DATE_PART('month', DATE_TRUNC('month', e.order_date))
    - DATE_PART('month', f.cohort_month)          AS month_number,
    COUNT(DISTINCT e.customer_id)                 AS active_customers,
    FIRST_VALUE(COUNT(DISTINCT e.customer_id)) OVER (
        PARTITION BY f.cohort_month
        ORDER BY
            (DATE_PART('year',  DATE_TRUNC('month', e.order_date))
             - DATE_PART('year',  f.cohort_month)) * 12
            + DATE_PART('month', DATE_TRUNC('month', e.order_date))
            - DATE_PART('month', f.cohort_month)
    )                                             AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT e.customer_id)
        / FIRST_VALUE(COUNT(DISTINCT e.customer_id)) OVER (
            PARTITION BY f.cohort_month
            ORDER BY
                (DATE_PART('year',  DATE_TRUNC('month', e.order_date))
                 - DATE_PART('year',  f.cohort_month)) * 12
                + DATE_PART('month', DATE_TRUNC('month', e.order_date))
                - DATE_PART('month', f.cohort_month)
        ), 1)                                     AS retention_rate_pct
FROM ecommerce_data e
JOIN (
    SELECT customer_id, DATE_TRUNC('month', MIN(order_date))::DATE AS cohort_month
    FROM ecommerce_data GROUP BY customer_id
) f USING (customer_id)
GROUP BY f.cohort_month, DATE_TRUNC('month', e.order_date)
ORDER BY f.cohort_month, month_number;


-- ─────────────────────────────────────────────────────────────
-- DS 6: CUSTOMER LTV SEGMENTS (Sheet: Revenue by Value Band)
-- Marks: Bar / Treemap | Dim: value_band, customer_id
-- Measures: total_revenue, revenue_share_pct
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_id,
    c.total_revenue,
    c.total_orders,
    c.avg_order_value,
    c.personal_delivery_rate_pct,
    CASE
        WHEN c.total_revenue >= p.p90 THEN '1 — Top 10%'
        WHEN c.total_revenue >= p.p75 THEN '2 — Top 25%'
        WHEN c.total_revenue >= p.p50 THEN '3 — Above Median'
        ELSE                               '4 — Below Median'
    END AS value_band
FROM (
    SELECT
        customer_id,
        ROUND(SUM(order_value), 2)             AS total_revenue,
        COUNT(*)                               AS total_orders,
        ROUND(AVG(order_value), 2)             AS avg_order_value,
        ROUND(AVG(delivered::NUMERIC) * 100,1) AS personal_delivery_rate_pct
    FROM ecommerce_data
    GROUP BY customer_id
) c
CROSS JOIN (
    SELECT
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY rev) AS p50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY rev) AS p75,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY rev) AS p90
    FROM (SELECT customer_id, SUM(order_value) AS rev FROM ecommerce_data GROUP BY customer_id) x
) p
ORDER BY c.total_revenue DESC;


-- ─────────────────────────────────────────────────────────────
-- DS 7: KPI SUMMARY (Sheet: KPI Tiles / Big Numbers)
-- Use as single-row data source for BANs in Tableau
-- ─────────────────────────────────────────────────────────────
SELECT
    COUNT(*)                                     AS total_orders,
    COUNT(DISTINCT customer_id)                  AS total_customers,
    ROUND(SUM(order_value), 2)                   AS total_revenue,
    ROUND(AVG(order_value), 2)                   AS avg_order_value,
    ROUND(AVG(delivered::NUMERIC) * 100, 1)      AS overall_delivery_rate_pct,
    SUM(1 - delivered)                           AS total_failed_deliveries,
    ROUND(SUM((1 - delivered) * order_value), 2) AS total_revenue_at_risk
FROM ecommerce_data;
