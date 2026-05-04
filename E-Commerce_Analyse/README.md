# E-Commerce BI Analysis

**Business Question:** *What drives revenue — and how can we reduce delivery failures?*

A full-stack data analyst portfolio project covering the complete workflow:
**Python (EDA)  →  SQL (analytics)  →  Tableau (dashboards)**

---

## The Story

An e-commerce business with 1,000 orders spanning 2023–2025. Revenue is stable but stagnant, while delivery failures erode customer trust and create hidden revenue leakage. This project investigates both dimensions using three analytical layers, each building on the previous one.

---

## Tech Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| Data & EDA | Python 3 · pandas · matplotlib · seaborn | Data cleaning, descriptive statistics, distribution analysis |
| Database | PostgreSQL 14 · SQLAlchemy | Structured storage, advanced analytics queries |
| Visualisation | Tableau Public | Interactive dashboards for stakeholders |

---

## Dataset

**File:** `synthetic_ecommerce_dataset_multisheet.xlsx`  
**Rows:** 1,000 orders · **Period:** 2023–2025

| Column | Type | Description |
|--------|------|-------------|
| `order_id` | integer | Unique order identifier |
| `customer_id` | integer | Customer identifier (repeat purchases possible) |
| `order_date` | date | Date of order placement |
| `product_category` | string | Product category (Electronics, Clothing, …) |
| `order_value` | decimal | Order total in USD |
| `payment_method` | string | Payment type (Credit Card, Debit Card, UPI, Wallet, Cash) |
| `delivered` | 0 / 1 | Delivery success flag |

---

## Project Structure

```
E-Commerce_Analyse/
├── data/
│   └── synthetic_ecommerce_dataset_multisheet.xlsx
├── notebook/
│   └── analysis.ipynb        # Layer 1 — Python EDA
├── sql/
│   ├── schema.sql             # Layer 2 — Database schema (PostgreSQL)
│   ├── queries.sql            # Layer 2 — Business analytics queries
│   ├── views.sql              # Layer 2 — Reusable views
│   ├── tableau_queries.sql    # Layer 3 — Tableau data source queries
│   └── results.md             # Layer 2 — Query output + findings
├── requirements.txt
└── README.md
```

---

## Layer 1 — Python EDA (`analysis.ipynb`)

Covers the foundational questions:

- **Revenue distribution** — order value histogram, summary statistics
- **Category analysis** — revenue and order volume by product category
- **Payment methods** — distribution and revenue per method
- **Delivery performance** — overall delivery rate, breakdown by category
- **Time series** — daily/monthly revenue trend
- **Customer segments** — spending-based segmentation (high / mid / low value)

Run it:
```bash
pip install pandas matplotlib seaborn openpyxl sqlalchemy psycopg2-binary
jupyter notebook analysis.ipynb
```

---

## Layer 2 — SQL Analytics (`schema.sql` · `queries.sql`)

The SQL layer adds analyses that are either impractical or verbose in pandas:

### Schema setup
```bash
psql -U <user> -d <database> -f schema.sql
```
The notebook's Cell 2 loads the data automatically via `df.to_sql()`.

### Business queries

| # | Query | Technique | Business Value |
|---|-------|-----------|----------------|
| 1 | Monthly revenue + 3-month rolling average | Window function · `AVG() OVER` | Trend smoothing, MoM growth |
| 2 | Customer cohort retention | CTE · `FIRST_VALUE() OVER` | Repeat-purchase health |
| 3 | Customer LTV ranking | `RANK()` · `NTILE()` · `PERCENT_RANK()` | Identify top customers |
| 4 | Category performance dashboard | CTE · multi-column ranking | Revenue vs. delivery risk |
| 5 | Payment method × delivery failure | CTE · `CROSS JOIN` · deviation from mean | Fraud / ops signal |
| 6 | Day-of-week order pattern | `EXTRACT(DOW)` · `SUM() OVER ()` | Capacity planning |
| 7 | Pareto / cumulative revenue | Running sum · `SUM() OVER` | Customer concentration risk |
| 8 | Delivery failure heatmap (category × month) | Grouped aggregation | Seasonal supply-chain issues |
| 9 | Order value percentile banding | `PERCENTILE_CONT` · `CASE` · `CROSS JOIN` | Segment by order size |

Run all queries:
```bash
psql -U <user> -d <database> -f queries.sql
```

**Results:** See [`sql/results.md`](sql/results.md) for the full query output with findings for each of the 9 analyses.

---

## Layer 3 — Tableau Dashboards

*In progress.* Planned views:

1. **Revenue Overview** — monthly trend (rolling avg) + MoM growth bar chart
2. **Delivery Risk Matrix** — category × month failure rate heatmap (Query 8)
3. **Customer Cohort Heatmap** — retention by cohort month (Query 2)
4. **Customer LTV Distribution** — revenue quartile breakdown (Query 3)
5. **Payment Method Deep-Dive** — delivery rate vs. average (Query 5)

Data source: PostgreSQL direct connection or exported CSVs from `queries.sql`.

---

## Local Setup

### Prerequisites
- Python 3.10+
- PostgreSQL 14+
- Tableau Public (free) or Tableau Desktop

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/nxtno/data-analytics-portfolio.git
cd data-analytics-portfolio/E-Commerce_Analyse

# 2. Install Python dependencies
pip install pandas matplotlib seaborn openpyxl sqlalchemy psycopg2-binary jupyter

# 3. Create the database table
psql -U <user> -d <database> -f sql/schema.sql

# 4. Run the notebook — this loads the data into PostgreSQL
jupyter notebook notebook/analysis.ipynb
# Execute all cells (Cell 2 does the df.to_sql() insert)

# 5. Run the SQL queries
psql -U <user> -d <database> -f sql/queries.sql
```

---

## Key Findings (Python EDA)

- Total revenue concentrated in a few high-value orders — Pareto effect confirmed in SQL Query 7
- Delivery failure rate varies significantly by product category — detailed in SQL Query 4 & 8
- Payment method is correlated with delivery outcome — investigated in SQL Query 5

---

## Author

Gerrik B. · [GitHub](https://github.com/gerrikb)
