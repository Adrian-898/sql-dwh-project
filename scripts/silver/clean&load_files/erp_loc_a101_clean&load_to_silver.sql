/*
Data cleaning and loading

includes Data cleaning, Standardization, Validation etc...
the Cleaned Data is then loaded to the same table in the silver layer schema.
*/

-- Show the whole table:
-- SELECT * FROM bronze.erp_loc_a101;

--Check for nulls and duplicates:
--Expectation: NO results
SELECT cid, COUNT(*) FROM bronze.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1 or cid IS NULL;

--Check for unmatching customer id between tables in order to connect them later
--Expectation: NO results
SELECT 
cid,
cntry
FROM bronze.erp_loc_a101
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

--Check for consistency and standardization in low cardinality values
--Expectation: 1 of 2 values (or Unknown in case it does not exist)
SELECT DISTINCT cntry FROM bronze.erp_loc_a101;

--Make corrections to data and insert it into the table in silver layer schema
INSERT INTO silver.erp_loc_a101 (
cid,
cntry
)
SELECT 
REPLACE(cid, '-', '') AS cid,
CASE
	WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
	WHEN UPPER(TRIM(cntry)) IN ('USA', 'US') THEN 'United States'
	WHEN cntry IS NULL OR cntry = '' THEN 'Unknown'
ELSE TRIM(cntry) 
END AS cntry
FROM bronze.erp_loc_a101

--Check loaded data for correctness:
--SELECT * FROM silver.erp_loc_a101;

--Check for unmatching customer id between tables in order to connect them later
--Expectation: NO results
SELECT
cid,
cntry
FROM silver.erp_loc_a101
WHERE cid NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)

--Check for consistency and standardization in low cardinality values
--Expectation: 1 of 2 values (or Unknown in case it does not exist)
SELECT DISTINCT cntry FROM silver.erp_loc_a101;
