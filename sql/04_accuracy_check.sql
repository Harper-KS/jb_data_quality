-- Check 4: Country is a recognised value
-- Dimension: Accuracy
-- Severity: Warning
--
-- Verifies that country matches a known entry in the reference dimension table (dim_countries).
-- Free-text entry creates variants ("UK" vs "United Kingdom", typos, etc.) that
-- silently split one market into multiple rows in geo reports.
--
-- Returns a Warning — fix typically requires building a mapping table,
-- not deleting rows. Output should be reviewed and actioned before
-- the next reporting window.

SELECT DISTINCT country
FROM jb_quality
WHERE country NOT IN (
    SELECT country_name
    FROM dim_countries       -- reference / dimension table
)
ORDER BY country;

-- Review returned values for typos, aliases, or unknown entries.
-- Expected result: empty set after standardisation