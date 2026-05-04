-- =============================================================
-- E-Commerce BI Analysis — Schema
-- Compatible with: PostgreSQL 14+
-- =============================================================

CREATE TABLE IF NOT EXISTS ecommerce_data (
    order_id         INTEGER        PRIMARY KEY,
    customer_id      INTEGER        NOT NULL,
    order_date       DATE           NOT NULL,
    product_category VARCHAR(100)   NOT NULL,
    order_value      NUMERIC(10, 2) NOT NULL CHECK (order_value >= 0),
    payment_method   VARCHAR(50)    NOT NULL,
    delivered        SMALLINT       NOT NULL CHECK (delivered IN (0, 1))
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_order_date       ON ecommerce_data (order_date);
CREATE INDEX IF NOT EXISTS idx_customer_id      ON ecommerce_data (customer_id);
CREATE INDEX IF NOT EXISTS idx_product_category ON ecommerce_data (product_category);
CREATE INDEX IF NOT EXISTS idx_delivered        ON ecommerce_data (delivered);

-- =============================================================
-- Load data via Python / psycopg2 (see README.md)
-- The notebook's Cell 2 handles the initial load with:
--   df.to_sql('ecommerce_data', engine, if_exists='replace', index=False)
-- =============================================================
