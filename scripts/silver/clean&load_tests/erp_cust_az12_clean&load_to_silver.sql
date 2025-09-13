/*
Data cleaning and loading

includes Data cleaning, Standardization, Validation etc...
the Cleaned Data is then loaded to the same table in the silver layer schema.
*/

-- Show the whole table:
-- SELECT * FROM bronze.erp_cust_az12;

--Check for nulls and duplicates:
--Expectation: NO results
SELECT cid, COUNT(*) FROM bronze.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1 or cid IS NULL;

--Check for unmatching customer id between tables in order to connect them later
--Expectation: NO results
SELECT
cid,
bdate,
gen
FROM bronze.erp_cust_az12
WHERE cid NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)

--Check for invalid dates
--Expectation: in logical date range (No future birthdays).
SELECT
bdate
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE()

--Check for consistency and standardization in low cardinality values
--Expectation: 1 of 2 values (or Unknown in case it does not exist)
SELECT DISTINCT gen FROM bronze.erp_cust_az12;

--Make corrections to data and insert it into the table in silver layer schema
INSERT INTO silver.erp_cust_az12 (
cid,
bdate,
gen
)
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
ELSE bdate
END AS bdate,
CASE
	WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
ELSE 'Unknown'
END AS gen
FROM bronze.erp_cust_az12

--Check loaded data for correctness:
--SELECT * FROM silver.erp_cust_az12;

--Check for unmatching customer id between tables in order to connect them later
--Expectation: NO results
SELECT
cid,
bdate,
gen
FROM silver.erp_cust_az12
WHERE cid NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)

--Check for invalid dates
--Expectation: in logical date range (No future bdate or more then 100 years old bdate).
SELECT
bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE()

--Check for consistency and standardization in low cardinality values
--Expectation: 1 of 2 values (or Unknown in case it does not exist)
SELECT DISTINCT gen FROM silver.erp_cust_az12;