
-- Check 5: InvoiceDate within the expected operational window
-- Dimension: Consistency
-- Severity: Warning
--
-- invoicedate is stored as a varchar and must be parsed before comparison.
-- Dates in the future or implausibly far in the past indicate parsing errors 
-- or bad imports that will severely skew time-series and cohort analysis.
--
-- We use PostgreSQL's TO_TIMESTAMP() function to accurately cast the string 
-- on the fly based on the specific 'MM/DD/YYYY HH24:MI' format of this dataset. 
-- The lower bound is set to the known dataset start date (2010).

SELECT * FROM jb_quality
WHERE TO_TIMESTAMP(invoicedate, 'MM/DD/YYYY HH24:MI') < '2010-01-01'   
   OR TO_TIMESTAMP(invoicedate, 'MM/DD/YYYY HH24:MI') > CURRENT_TIMESTAMP;

-- Expected result: empty result set