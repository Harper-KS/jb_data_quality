-- Check 1: Null Values in Critical Fields
-- Dimension: Completeness
-- Severity: Critical
--
-- Verifies that no row is missing a value in fields that downstream analytics 
-- depend on: invoice_no, customer_id, quantity, unitprice, or country.
--
-- Why it matters:
-- * A null invoice_no makes the row unattributable to any transaction.
-- * A null quantity or unitprice makes revenue calculation impossible.
-- * A null country silently breaks all geographic segmentation.
-- Note: Not every column warrants a null check. 'description', for example, 
-- may be null without affecting any metric. Checks are scoped to impact.
--
-- Returns a Critical Error — missing critical identifiers invalidates the row.

SELECT * FROM jb_quality
WHERE invoice_no IS NULL 
   OR customer_id IS NULL   
   OR quantity IS NULL 
   OR unitprice IS NULL 
   OR country IS NULL;

-- Expected result: empty result set