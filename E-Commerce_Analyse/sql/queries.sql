-- =============================================================
-- E-Commerce BI Analysis — SQL Layer
-- Business Question: "What drives revenue — and how can we
--                    reduce delivery failures?"
--
-- These queries complement the Python EDA by adding:
--   - Time-series patterns (rolling averages, MoM growth)
--   - Customer lifecycle analysis (cohorts, retention)
--   - Rankings and percentile segmentation
--   - Delivery failure root-cause signals
-- Compatible with: PostgreSQL 14+
-- =============================================================


-- ─────────────────────────────────────────────────────────────
-- 1. MONTHLY REVENUE TREND WITH ROLLING 3-MONTH AVERAGE
--    Why: Smooths noise to reveal structural revenue trends.
--    Useful for Tableau line charts comparing raw vs. smoothed.
-- ─────────────────────────────────────────────────────────────
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS month,
        SUM(order_value)                      AS revenue,
        COUNT(*)                              AS orders
    FROM ecommerce_data
    GROUP BY 1
)
SELECT
    month,
    revenue,
    orders,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )::NUMERIC, 2
    ) AS revenue_3m_rolling_avg,
    ROUND(
        (100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
              / NULLIF(LAG(revenue) OVER (ORDER BY month), 0))::NUMERIC,
        1
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;


-- ─────────────────────────────────────────────────────────────
-- 2. CUSTOMER COHORT RETENTION (MONTHLY)
--    Why: Shows whether customers return after their first
--    purchase — the single most important growth metric.
--    Feeds directly into a Tableau cohort heatmap.
-- ─────────────────────────────────────────────────────────────
WITH first_orders AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date))::DATE AS cohort_month
    FROM ecommerce_data
    GROUP BY customer_id
),
activity AS (
    SELECT
        e.customer_id,
        f.cohort_month,
        DATE_TRUNC('month', e.order_date)::DATE AS order_month,
        -- months since first purchase
        (DATE_PART('year',  DATE_TRUNC('month', e.order_date))
         - DATE_PART('year',  f.cohort_month)) * 12
        + DATE_PART('month', DATE_TRUNC('month', e.order_date))
        - DATE_PART('month', f.cohort_month)   AS month_number
    FROM ecommerce_data e
    JOIN first_orders   f USING (customer_id)
)
SELECT
    cohort_month,
    month_number,
    COUNT(DISTINCT customer_id)                         AS active_customers,
    FIRST_VALUE(COUNT(DISTINCT customer_id)) OVER (
        PARTITION BY cohort_month
        ORDER BY month_number
    )                                                   AS cohort_size,
    ROUND(
        100.0 * COUNT(DISTINCT customer_id)
              / FIRST_VALUE(COUNT(DISTINCT customer_id)) OVER (
                    PARTITION BY cohort_month
                    ORDER BY month_number
                ),
        1
    )                                                   AS retention_rate_pct
FROM activity
GROUP BY cohort_month, month_number
ORDER BY cohort_month, month_number;


-- ─────────────────────────────────────────────────────────────
-- 3. CUSTOMER LIFETIME VALUE RANKING (RFM-LITE)
--    Why: Identifies high-value customers to protect and
--    at-risk customers to re-engage. Python only did totals;
--    this adds per-customer ranking and spend percentiles.
-- ─────────────────────────────────────────────────────────────
WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(*)                        AS total_orders,
        ROUND(SUM(order_value)::NUMERIC, 2)      AS total_revenue,
        ROUND(AVG(order_value)::NUMERIC, 2)      AS avg_order_value,
        MIN(order_date)                          AS first_order,
        MAX(order_date)                          AS last_order,
        MAX(order_date) - MIN(order_date)        AS customer_lifespan_days,
        ROUND(AVG(delivered::NUMERIC) * 100, 1)  AS personal_delivery_rate_pct
    FROM ecommerce_data
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_orders,
    total_revenue,
    avg_order_value,
    customer_lifespan_days,
    personal_delivery_rate_pct,
    RANK()    OVER (ORDER BY total_revenue DESC)  AS revenue_rank,
    NTILE(4)  OVER (ORDER BY total_revenue DESC)  AS revenue_quartile,   -- 1 = top 25%
    PERCENT_RANK() OVER (ORDER BY total_revenue)  AS revenue_percentile
FROM customer_stats
ORDER BY revenue_rank;


-- ─────────────────────────────────────────────────────────────
-- 4. CATEGORY PERFORMANCE DASHBOARD (RANKED)
--    Why: Compares categories on revenue AND delivery health
--    simultaneously — crucial for prioritising operational fixes.
-- ─────────────────────────────────────────────────────────────
WITH category_stats AS (
    SELECT
        product_category,
        COUNT(*)                                   AS total_orders,
        ROUND(SUM(order_value)::NUMERIC, 2)                 AS total_revenue,
        ROUND(AVG(order_value)::NUMERIC, 2)                 AS avg_order_value,
        ROUND(AVG(delivered::NUMERIC) * 100, 1)             AS delivery_rate_pct,
        SUM(1 - delivered)                                  AS failed_deliveries,
        ROUND(SUM((1 - delivered) * order_value)::NUMERIC, 2) AS revenue_at_risk
    FROM ecommerce_data
    GROUP BY product_category
)
SELECT
    product_category,
    total_orders,
    total_revenue,
    avg_order_value,
    delivery_rate_pct,
    failed_deliveries,
    revenue_at_risk,
    RANK() OVER (ORDER BY total_revenue  DESC) AS revenue_rank,
    RANK() OVER (ORDER BY delivery_rate_pct)   AS delivery_risk_rank  -- 1 = worst delivery
FROM category_stats
ORDER BY total_revenue DESC;


-- ─────────────────────────────────────────────────────────────
-- 5. PAYMENT METHOD vs. DELIVERY FAILURE CORRELATION
--    Why: Tests whether certain payment methods are systematically
--    linked to failed deliveries — an operational/fraud signal.
-- ─────────────────────────────────────────────────────────────
WITH payment_delivery AS (
    SELECT
        payment_method,
        COUNT(*)                                   AS total_orders,
        SUM(delivered)                             AS delivered_count,
        SUM(1 - delivered)                         AS failed_count,
        ROUND(AVG(delivered::NUMERIC) * 100, 1)              AS delivery_rate_pct,
        ROUND(AVG(order_value)::NUMERIC, 2)                  AS avg_order_value,
        ROUND(SUM((1 - delivered) * order_value)::NUMERIC, 2) AS lost_revenue
    FROM ecommerce_data
    GROUP BY payment_method
),
overall AS (
    SELECT ROUND(AVG(delivered::NUMERIC) * 100, 1) AS overall_delivery_rate
    FROM ecommerce_data
)
SELECT
    p.*,
    o.overall_delivery_rate,
    ROUND(p.delivery_rate_pct - o.overall_delivery_rate, 1) AS vs_average_pct
FROM payment_delivery p
CROSS JOIN overall o
ORDER BY delivery_rate_pct;


-- ─────────────────────────────────────────────────────────────
-- 6. WEEKLY ORDER VOLUME WITH DAY-OF-WEEK PATTERN
--    Why: Identifies peak days for capacity planning and
--    targeted marketing campaigns.
-- ─────────────────────────────────────────────────────────────
SELECT
    TO_CHAR(order_date, 'Day')              AS day_of_week,
    EXTRACT(DOW FROM order_date)            AS dow_number,   -- 0=Sun
    COUNT(*)                                AS total_orders,
    ROUND(SUM(order_value)::NUMERIC, 2)              AS total_revenue,
    ROUND(AVG(order_value)::NUMERIC, 2)              AS avg_order_value,
    ROUND(AVG(delivered::NUMERIC) * 100, 1)          AS delivery_rate_pct,
    -- share of weekly volume
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        1
    ) AS pct_of_all_orders
FROM ecommerce_data
GROUP BY 1, 2
ORDER BY 2;


-- ─────────────────────────────────────────────────────────────
-- 7. RUNNING REVENUE & ORDER SHARE (TOP-N ANALYSIS)
--    Why: Classic Pareto check — do 20% of customers generate
--    80% of revenue? Quantifies customer concentration risk.
-- ─────────────────────────────────────────────────────────────
WITH customer_revenue AS (
    SELECT
        customer_id,
        ROUND(SUM(order_value)::NUMERIC, 2) AS revenue
    FROM ecommerce_data
    GROUP BY customer_id
),
ranked AS (
    SELECT
        customer_id,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
        COUNT(*) OVER ()                    AS total_customers,
        SUM(revenue) OVER ()                AS grand_total
    FROM customer_revenue
)
SELECT
    revenue_rank,
    customer_id,
    revenue,
    ROUND(100.0 * revenue_rank / total_customers, 1)                          AS pct_of_customers,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC) / grand_total, 1) AS cumulative_revenue_pct
FROM ranked
ORDER BY revenue_rank
LIMIT 50;


-- ─────────────────────────────────────────────────────────────
-- 8. DELIVERY FAILURE HEATMAP: CATEGORY × MONTH
--    Why: Pinpoints when and where delivery problems cluster —
--    could indicate seasonal supply-chain issues per category.
--    Perfect source for a Tableau highlight table.
-- ─────────────────────────────────────────────────────────────
SELECT
    product_category,
    TO_CHAR(order_date, 'YYYY-MM')          AS year_month,
    COUNT(*)                                AS total_orders,
    SUM(1 - delivered)                      AS failed_deliveries,
    ROUND(AVG(1 - delivered::NUMERIC) * 100, 1) AS failure_rate_pct
FROM ecommerce_data
GROUP BY product_category, TO_CHAR(order_date, 'YYYY-MM')
ORDER BY product_category, year_month;


-- ─────────────────────────────────────────────────────────────
-- 9. HIGH-VALUE ORDER ANALYSIS WITH PERCENTILE BANDS
--    Why: Revenue is rarely normally distributed — large orders
--    disproportionately drive totals. This segments the order
--    pool into value bands for targeted Tableau visualisations.
-- ─────────────────────────────────────────────────────────────
WITH percentiles AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY order_value) AS p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY order_value) AS p50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY order_value) AS p75,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY order_value) AS p90
    FROM ecommerce_data
),
banded AS (
    SELECT
        e.*,
        CASE
            WHEN e.order_value >= p.p90 THEN 'Top 10% — High Value'
            WHEN e.order_value >= p.p75 THEN 'Q4 — Above Average'
            WHEN e.order_value >= p.p50 THEN 'Q3 — Average'
            WHEN e.order_value >= p.p25 THEN 'Q2 — Below Average'
            ELSE                              'Q1 — Low Value'
        END AS value_band
    FROM ecommerce_data e
    CROSS JOIN percentiles p
)
SELECT
    value_band,
    COUNT(*)                                   AS orders,
    ROUND(SUM(order_value)::NUMERIC, 2)                 AS total_revenue,
    ROUND(AVG(order_value)::NUMERIC, 2)                 AS avg_order_value,
    ROUND(AVG(delivered::NUMERIC) * 100, 1)             AS delivery_rate_pct,
    ROUND((100.0 * SUM(order_value) / SUM(SUM(order_value)) OVER ())::NUMERIC, 1) AS revenue_share_pct
FROM banded
GROUP BY value_band
ORDER BY avg_order_value DESC;
