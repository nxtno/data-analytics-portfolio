# SQL Query Results — E-Commerce BI Analysis

**Database:** PostgreSQL 14 · **Dataset:** 1,000 orders · **Period:** 2023–2025  
**Business Question:** *What drives revenue — and how can we reduce delivery failures?*

---

## Query 1 — Monthly Revenue Trend + 3-Month Rolling Average

> Smooths noise to reveal structural revenue trends. Window function: `AVG() OVER`.

| Month | Revenue ($) | Orders | 3M Rolling Avg ($) | MoM Growth % |
|---|---|---|---|---|
| 2023-01 | 1,374.87 | 31 | 1,374.87 | — |
| 2023-02 | 1,753.03 | 28 | 1,563.95 | +27.5 |
| 2023-03 | 1,619.85 | 31 | 1,582.58 | -7.6 |
| 2023-04 | 1,301.37 | 30 | 1,558.08 | -19.7 |
| 2023-05 | 1,381.18 | 31 | 1,434.13 | +6.1 |
| 2023-06 | 1,474.72 | 30 | 1,385.76 | +6.8 |
| 2023-07 | 1,453.85 | 31 | 1,436.58 | -1.4 |
| 2023-08 | 1,495.71 | 31 | 1,474.76 | +2.9 |
| 2023-09 | 1,326.74 | 30 | 1,425.43 | -11.3 |
| 2023-10 | 1,332.69 | 31 | 1,385.05 | +0.4 |
| 2023-11 | 1,398.07 | 30 | 1,352.50 | +4.9 |
| 2023-12 | 1,582.10 | 31 | 1,437.62 | +13.2 |
| 2024-01 | 1,655.21 | 31 | 1,545.13 | +4.6 |
| 2024-02 | 1,432.97 | 29 | 1,556.76 | -13.4 |
| 2024-03 | 1,707.83 | 31 | 1,598.67 | +19.2 |
| 2024-04 | 1,213.85 | 30 | 1,451.55 | -28.9 |
| 2024-05 | 1,394.47 | 31 | 1,438.72 | +14.9 |
| 2024-06 | 1,551.79 | 30 | 1,386.70 | +11.3 |
| 2024-07 | 1,678.98 | 31 | 1,541.75 | +8.2 |
| 2024-08 | 1,420.08 | 31 | 1,550.28 | -15.4 |
| 2024-09 | 1,113.42 | 30 | 1,404.16 | -21.6 |
| 2024-10 | 962.70 | 31 | 1,165.40 | -13.5 |
| 2024-11 | 1,491.51 | 30 | 1,189.21 | +54.9 |
| 2024-12 | 1,793.91 | 31 | 1,416.04 | +20.3 |
| 2025-01 | 1,227.28 | 31 | 1,504.23 | -31.6 |
| 2025-02 | 1,361.27 | 28 | 1,460.82 | +10.9 |
| 2025-03 | 1,759.89 | 31 | 1,449.48 | +29.3 |
| 2025-04 | 1,582.27 | 30 | 1,567.81 | -10.1 |
| 2025-05 | 1,037.08 | 31 | 1,459.75 | -34.5 |
| 2025-06 | 1,686.82 | 30 | 1,435.39 | +62.7 |
| 2025-07 | 1,776.60 | 31 | 1,500.17 | +5.3 |
| 2025-08 | 1,335.04 | 31 | 1,599.49 | -24.9 |
| 2025-09 | 1,050.36 | 26 | 1,387.33 | -21.3 |

**Finding:** Revenue oscillates between ~$960 and ~$1,810 per month with no clear long-term growth trend. The 3-month rolling average stays consistently in the $1,350–$1,600 band, indicating a stable but stagnant business. High MoM volatility (e.g. +62.7% in Jun 2025, -34.5% in May 2025) suggests demand spikes rather than organic growth.

---

## Query 2 — Customer Cohort Retention

> Measures whether customers return after their first purchase. Technique: CTE + `FIRST_VALUE() OVER`.

Sample — January 2023 cohort (cohort size: 29 customers):

| Month Number | Active Customers | Retention % |
|---|---|---|
| 0 (acquisition) | 29 | 100.0 |
| 1 | 3 | 10.3 |
| 2 | 2 | 6.9 |
| 4 | 4 | 13.8 |
| 7 | 4 | 13.8 |
| 9 | 6 | 20.7 |
| 12 | 3 | 10.3 |

**Finding:** Month-1 retention sits at ~10% across all cohorts — typical for non-subscription e-commerce, but a clear signal that repeat-purchase incentives (loyalty programs, follow-up campaigns) are not in place. No cohort recovers above 30% retention at any point.

---

## Query 3 — Customer Lifetime Value Ranking

> Per-customer revenue ranking with quartile segmentation. Technique: `RANK()`, `NTILE(4)`, `PERCENT_RANK()`.

Top 10 customers by total revenue:

| Revenue Rank | Customer ID | Total Revenue ($) | Avg Order ($) | Lifespan (days) | Delivery Rate % | Quartile |
|---|---|---|---|---|---|---|
| 1 | 255 | 901.19 | 112.65 | 808 | 87.5 | 1 |
| 2 | 265 | 629.40 | 157.35 | 394 | 100.0 | 1 |
| 3 | 26 | 623.26 | 89.04 | 868 | 100.0 | 1 |
| 4 | 166 | 541.07 | 60.12 | 887 | 100.0 | 1 |
| 5 | 29 | 524.62 | 65.58 | 473 | 87.5 | 1 |
| 6 | 146 | 514.60 | 73.51 | 803 | 100.0 | 1 |
| 7 | 22 | 464.50 | 116.13 | 478 | 100.0 | 1 |
| 8 | 42 | 460.54 | 65.79 | 889 | 100.0 | 1 |
| 9 | 211 | 447.93 | 63.99 | 610 | 85.7 | 1 |
| 10 | 182 | 442.66 | 88.53 | 554 | 100.0 | 1 |

**Finding:** The top customer (ID 255) generates $901 — roughly 1.9% of total revenue alone. Top 10 customers account for ~11.6% of total revenue despite representing only 3.6% of the customer base. Classic Pareto concentration confirmed (see Query 7).

---

## Query 4 — Category Performance Dashboard

> Revenue vs. delivery risk per category. Technique: Multi-column `RANK()` in a single CTE.

| Category | Orders | Revenue ($) | Avg Order ($) | Delivery Rate % | Failed | Revenue at Risk ($) | Revenue Rank | Delivery Risk Rank |
|---|---|---|---|---|---|---|---|---|
| Electronics | 207 | 10,848.50 | 52.41 | 95.7 | 9 | 631.41 | 1 | 4 |
| Home | 202 | 9,756.01 | 48.30 | 96.0 | 8 | 501.84 | 2 | 5 |
| Clothing | 211 | 9,645.18 | 45.71 | 94.8 | 11 | 412.48 | 3 | 1 |
| Books | 190 | 9,257.56 | 48.72 | 95.3 | 9 | 385.73 | 4 | 2 |
| Beauty | 190 | 8,220.26 | 43.26 | 95.3 | 9 | 417.60 | 5 | 2 |

**Finding:** Electronics is the top revenue category but also carries the highest revenue-at-risk ($631). Clothing has the worst delivery rate (94.8%) despite being the highest-volume category. Home is the safest operationally. A focused fix on Electronics and Clothing delivery would protect ~$1,044 in at-risk revenue.

---

## Query 5 — Payment Method × Delivery Failure Correlation

> Tests whether payment type is linked to failed deliveries. Technique: CTE + `CROSS JOIN` for deviation from mean.

| Payment Method | Orders | Delivery Rate % | Avg Order ($) | Lost Revenue ($) | vs. Average % |
|---|---|---|---|---|---|
| UPI | 200 | 93.5 | 50.26 | 776.42 | -1.9 |
| Wallet | 204 | 93.6 | 48.56 | 631.43 | -1.8 |
| Debit Card | 190 | 94.7 | 43.34 | 535.92 | -0.7 |
| Cash | 222 | 96.8 | 44.76 | 203.68 | +1.4 |
| Credit Card | 184 | 98.4 | 52.17 | 201.61 | +3.0 |

**Finding:** UPI and Wallet payments have a delivery rate ~1.8–1.9 percentage points below average, resulting in $776 and $631 in lost revenue respectively. Credit Card has the highest delivery success (98.4%). This could indicate a fraud or fulfilment correlation worth investigating with the operations team.

---

## Query 6 — Day-of-Week Order Pattern

> Identifies peak days for capacity planning. Technique: `EXTRACT(DOW)` + `SUM() OVER ()`.

| Day | Orders | Revenue ($) | Avg Order ($) | Delivery Rate % | Share of Orders % |
|---|---|---|---|---|---|
| Sunday | 143 | 6,714.17 | 46.95 | 97.2 | 14.3 |
| Monday | 143 | 6,913.40 | 48.35 | 94.4 | 14.3 |
| Tuesday | 143 | 7,202.38 | 50.37 | 93.0 | 14.3 |
| Wednesday | 143 | 6,666.30 | 46.62 | 92.3 | 14.3 |
| Thursday | 143 | 5,887.40 | 41.17 | 95.8 | 14.3 |
| Friday | 143 | 7,220.39 | 50.49 | 98.6 | 14.3 |
| Saturday | 142 | 7,123.47 | 50.17 | 96.5 | 14.2 |

**Finding:** Order volume is perfectly uniform across weekdays (~143/day), suggesting no demand pattern to exploit for marketing. However, delivery rates vary significantly: Wednesday is the weakest (92.3%) while Friday is the strongest (98.6%). This mid-week delivery dip warrants a logistics investigation.

---

## Query 7 — Pareto / Cumulative Revenue (Top-N Analysis)

> Tests the 80/20 rule across customers. Technique: Running `SUM() OVER`.

| Revenue Rank | Customer ID | Revenue ($) | % of Customers | Cumulative Revenue % |
|---|---|---|---|---|
| 1 | 255 | 901.19 | 0.4 | 1.9 |
| 2 | 265 | 629.40 | 0.7 | 3.2 |
| 3 | 26 | 623.26 | 1.1 | 4.5 |
| 4 | 166 | 541.07 | 1.4 | 5.6 |
| 5 | 29 | 524.62 | 1.8 | 6.7 |
| 6 | 146 | 514.60 | 2.1 | 7.8 |
| 7 | 22 | 464.50 | 2.5 | 8.8 |
| 8 | 42 | 460.54 | 2.8 | 9.8 |
| 9 | 211 | 447.93 | 3.2 | 10.7 |
| 10 | 182 | 442.66 | 3.6 | 11.6 |

**Finding:** The top 3.6% of customers generate 11.6% of total revenue — a moderate but present Pareto effect. The distribution is less extreme than the classic 80/20 rule, suggesting a relatively even customer base without dangerous concentration risk.

---

## Query 8 — Delivery Failure Heatmap (Category × Month)

> Pinpoints when and where delivery failures cluster. Technique: Grouped aggregation for Tableau highlight table.

Sample — Electronics (highest revenue-at-risk category):

| Category | Month | Orders | Failed | Failure Rate % |
|---|---|---|---|---|
| Electronics | 2023-02 | 4 | 2 | 50.0 |
| Electronics | 2023-03 | 9 | 1 | 11.1 |
| Electronics | 2023-04 | 7 | 1 | 14.3 |
| Electronics | 2023-10 | 3 | 1 | 33.3 |
| Electronics | 2024-08 | 5 | 1 | 20.0 |
| Electronics | 2024-12 | 7 | 1 | 14.3 |
| Electronics | 2025-03 | 5 | 1 | 20.0 |
| Electronics | 2025-06 | 10 | 1 | 10.0 |

**Finding:** Electronics failure months are sporadic rather than seasonal — no consistent cluster around a specific season. The worst single month is Feb 2023 (50%, but only 4 orders — small sample). October 2023 shows 33.3% failure on 3 orders. Most months have zero failures, suggesting isolated incidents rather than a systemic supply-chain issue.

---

## Query 9 — Order Value Percentile Banding

> Segments orders into revenue bands for targeted analysis. Technique: `PERCENTILE_CONT` + `CASE` + `CROSS JOIN`.

| Value Band | Orders | Total Revenue ($) | Avg Order ($) | Delivery Rate % | Revenue Share % |
|---|---|---|---|---|---|
| Top 10% — High Value | 100 | 15,505.34 | 155.05 | 96.0 | 32.5 |
| Q4 — Above Average | 150 | 13,072.32 | 87.15 | 95.3 | 27.4 |
| Q3 — Average | 250 | 11,674.64 | 46.70 | 93.2 | 24.5 |
| Q2 — Below Average | 250 | 5,813.21 | 23.25 | 95.2 | 12.2 |
| Q1 — Low Value | 250 | 1,662.00 | 6.65 | 97.6 | 3.5 |

**Finding:** The top 10% of orders (by value) generate 32.5% of total revenue — a clear concentration in high-value transactions. Notably, the Q3 "Average" band has the lowest delivery rate (93.2%), meaning mid-range orders are disproportionately affected by fulfilment failures. Protecting delivery quality for the Top 10% band (96.0%) appears to be working; the middle tier needs attention.
