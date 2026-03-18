# Data Quality Checks — Online Retail Transactions

> A set of SQL-based data quality checks designed to ensure the reliability of an online retail transactions dataset for analytics and reporting.



## Context

This project was designed as part of a data quality engineering exercise.
The dataset contains online retail transactions, including invoices, quantities, prices, customer IDs, and countries.

The goal was to identify **five data quality checks** that would catch real issues before they reach dashboards or aggregate reports — each targeting a specific failure mode that would silently corrupt analytics if undetected.



## Repository Structure

```
.
├── README.md
└── sql/
    ├── 01_null_check.sql
    ├── 02_validity_check.sql
    ├── 03_uniqueness_check.sql
    ├── 04_accuracy_check.sql
    └── 05_consistency_check.sql
```



## Check Overview

| # | Check | Dimension | Severity |
|---|-------|-----------|----------|
| 1 | Null values in critical fields | Completeness | 🔴 Critical |
| 2 | Negative or zero Quantity / UnitPrice | Validity | 🔴 Critical |
| 3 | Duplicate invoice line items | Uniqueness | 🔴 Critical |
| 4 | Country is a recognised value | Accuracy | 🟡 Warning |
| 5 | InvoiceDate within expected range | Consistency | 🟡 Warning |

**Severity definitions used throughout this project:**
- 🔴 **Critical** — pipeline should not proceed; would trigger an incident in a production system
- 🟡 **Warning** — logged for investigation; must be reviewed before the next reporting window closes



## Check 1 — Null Values in Critical Fields

**Dimension:** Completeness
**Severity:** 🔴 Critical

**What it verifies:**
No row is missing a value in any field that downstream analytics depends on: `invoice_no`, `customer_id`, `quantity`, `unitprice`, or `country`.

**Why it matters:**
- A null `invoice_no` makes the row unattributable to any transaction
- A null `quantity` or `unitprice` makes revenue calculation impossible
- A null `country` silently breaks all geographic segmentation

> **Note:** Not every column warrants a null check. `description`, for example, may be null without affecting any metric. Checks are scoped to fields with a concrete downstream impact.

**SQL:** [`sql/01_null_check.sql`](sql/01_null_check.sql)

```sql
SELECT * FROM jb_quality
WHERE invoice_no IS NULL 
   OR customer_id IS NULL   
   OR quantity IS NULL 
   OR unitprice IS NULL 
   OR country IS NULL

-- Expected result: 0
```



## Check 2 — Negative or Zero Quantity / UnitPrice

**Dimension:** Validity
**Severity:** 🔴 Critical

**What it verifies:**
`unitprice` is always positive. `quantity` is positive except for cancellation invoices, which carry negative quantities by design.

**Why it matters:**
Zero or negative prices are never valid and would corrupt revenue totals. Negative quantities on non-cancellation rows indicate a data entry or pipeline error.

> **Design decision:** Cancelled invoices in this dataset use a `C` prefix on `invoice_no` (e.g. `C536379`). Flagging those as errors would generate constant false positives. The check explicitly excludes them to avoid alert fatigue — a blanket rule would mask real issues behind noise.

**SQL:** [`sql/02_validity_check.sql`](sql/02_validity_check.sql)

```sql
SELECT * FROM jb_quality
WHERE unitprice <= 0   
   OR (quantity <= 0 AND invoice_no NOT LIKE 'C%')

-- Cancelled invoices (C prefix) carry negative quantities by design.
-- This check only flags unintended negatives.
-- Expected result: 0
```



## Check 3 — Duplicate Invoice Line Items

**Dimension:** Uniqueness
**Severity:** 🔴 Critical

**What it verifies:**
The expected grain of this table is one row per `(invoice_no, stockcode)` combination. No pair should appear more than once.

**Why it matters:**
Duplicates would double-count both revenue and unit volumes in every downstream aggregation — and because they are exact copies, they are silent: no error is thrown, totals are simply wrong.

**SQL:** [`sql/03_uniqueness_check.sql`](sql/03_uniqueness_check.sql)

```sql
SELECT invoice_no, stockcode, COUNT(*) AS cnt
FROM jb_quality
GROUP BY invoice_no, stockcode
HAVING COUNT(*) > 1

-- Expected result: empty set
```



## Check 4 — Country Is a Recognised Value

**Dimension:** Accuracy
**Severity:** 🟡 Warning

**What it verifies:**
Every value in the `country` field matches a recognised entry in a reference table of valid country names.

**Why it matters:**
Free-text country entry leads to variants ("UK" vs "United Kingdom"), abbreviations, and typos that break country-level segmentation. A dashboard grouping by country would silently split one market into several rows.

> **This check returns a Warning**, not a Critical, because the fix typically involves building a mapping table rather than deleting rows. The output surfaces candidates for investigation and standardisation.

**SQL:** [`sql/04_accuracy_check.sql`](sql/04_accuracy_check.sql)

```sql

SELECT DISTINCT country
FROM jb_quality
WHERE country NOT IN (
    SELECT country_name
    FROM dim_countries       -- reference / dimension table
)

-- Review returned values for typos, aliases, or unknown entries.
-- Expected result: empty set after standardisation
```



## Check 5 — InvoiceDate Within Expected Range

**Dimension:** Consistency
**Severity:** 🟡 Warning

**What it verifies:**
Every `invoicedate` falls within the known operational window of the dataset — no dates in the future, and none implausibly far in the past.

**Why it matters:**
Out-of-range dates indicate parsing errors or import mistakes. A single transaction dated 2099 would skew any time-series chart or cohort analysis without triggering any aggregation error.

**SQL:** [`sql/05_consistency_check.sql`](sql/05_consistency_check.sql)

```sql
SELECT * FROM jb_quality
WHERE TO_TIMESTAMP(invoicedate, 'MM/DD/YYYY HH24:MI') < '2010-01-01'   
   OR TO_TIMESTAMP(invoicedate, 'MM/DD/YYYY HH24:MI') > CURRENT_TIMESTAMP

-- Expected result: 0
```


## About

Designed as part of a data quality engineering exercise mapping to real production DQ patterns: completeness, validity, uniqueness, accuracy, and consistency.

Each check is scoped intentionally — not every column is checked for every rule, only where a concrete downstream impact can be named.