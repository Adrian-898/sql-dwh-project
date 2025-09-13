/*
Data cleaning and loading

includes Data cleaning, Standardization, Validation etc...
the Cleaned Data is then loaded to the same table in the silver layer schema.
*/

-- Show the whole table:
--SELECT * FROM bronze.erp_px_cat_g1v2;

--Check for nulls and duplicates:
--Expectation: NO results
SELECT id, COUNT(*) FROM bronze.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1 or id IS NULL;

--Check for unwanted spaces:
--Expectation: NO results
SELECT cat
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat);

SELECT subcat
FROM bronze.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat);

SELECT maintenance
FROM bronze.erp_px_cat_g1v2
WHERE maintenance != TRIM(maintenance);

--Check for consistency and standardization in low cardinality values
--Expectation: 1 of 4 values (or Unknown in case it does not exist)
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;

--Insert the data into the silver layer table (No needed corrections):
INSERT INTO silver.erp_px_cat_g1v2 (
id,
cat,
subcat,
maintenance
)
SELECT 
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2;

--Check loaded data:
SELECT * FROM silver.erp_px_cat_g1v2;