
   -- Check 2: Negative or zero quantity / unitprice
-- Dimension: Validity
-- Severity: Critical
--
-- unitprice (numeric) must always be positive.
-- quantity (integer) must be positive except for cancellation invoices,
-- which use a 'C' prefix on invoice_no and carry negative quantities by design.

SELECT COUNT(*) AS failing_rows
FROM jb_quality
WHERE unitprice <= 0
   OR (quantity <= 0 AND invoice_no NOT LIKE 'C%');

-- Cancelled invoices (C prefix) carry negative quantities by design.
-- This check only flags unintended negatives.
-- Expected result: 0