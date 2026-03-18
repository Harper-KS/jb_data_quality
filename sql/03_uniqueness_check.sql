-- Check 3: Duplicate invoice line items
-- Dimension: Uniqueness
-- Severity: Critical
--
-- The expected grain of this table is one row per (invoice_no, stockcode).
-- Duplicates silently inflate revenue and unit volumes in all aggregations.

SELECT invoice_no, stockcode, COUNT(*) AS cnt
FROM jb_quality
GROUP BY invoice_no, stockcode
HAVING COUNT(*) > 1;

-- Expected result: empty set