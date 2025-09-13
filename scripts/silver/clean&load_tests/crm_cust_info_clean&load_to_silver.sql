/*
Data cleaning and loading

includes Data cleaning, Standardization, Validation etc...
the Cleaned Data is then loaded to the same table in the silver layer schema.
*/

-- Show the whole table:
-- SELECT * FROM bronze.crm_cust_info;

--Check for nulls and duplicates:
--Expectation: NO results
SELECT cst_id, COUNT(*) FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 or cst_id IS NULL;

--Check for unwanted spaces:
--Expectation: NO results
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT cst_marital_status
FROM bronze.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

SELECT cst_gender
FROM bronze.crm_cust_info
WHERE cst_gender != TRIM(cst_gender);

--Check for consistency and standardization in low cardinality values
--Expectation: 1 of 2 values (or Unknown in case it does not exist)
SELECT DISTINCT cst_marital_status FROM bronze.crm_cust_info;
SELECT DISTINCT cst_gender FROM bronze.crm_cust_info;

--Clean any found errors and INSERT into silver layer Table:
INSERT INTO silver.crm_cust_info
(
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gender,
cst_create_date
)

SELECT
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE UPPER(TRIM(cst_marital_status))
	WHEN 'M' THEN 'Married'
	WHEN 'S' THEN 'Single'
ELSE 'Unknown' 
END AS cst_marital_status,
CASE UPPER(TRIM(cst_gender))
	WHEN 'M' THEN 'Male'
	WHEN 'F' THEN 'Female'
ELSE 'Unknown' 
END AS cst_gender,
cst_create_date
FROM
(
SELECT *, 
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL
) AS qry where flag_last = 1;

--Check that the load to silver layer worked:

--Check for nulls and duplicates:
--Expectation: NO results
SELECT cst_id, COUNT(*) FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 or cst_id IS NULL;

--Check for unwanted spaces:
--Expectation: NO results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

SELECT cst_gender
FROM silver.crm_cust_info
WHERE cst_gender != TRIM(cst_gender);

--check for consistency and standardization in low cardinality values
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;
SELECT DISTINCT cst_gender FROM silver.crm_cust_info;

--Finally, check the whole table in the silver layer:
SELECT * FROM silver.crm_cust_info;