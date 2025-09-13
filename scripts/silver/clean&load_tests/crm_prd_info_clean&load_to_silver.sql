/*
Data cleaning and loading

includes Data cleaning, Standardization, Validation etc...
the Cleaned Data is then loaded to the same table in the silver layer schema.
*/

-- Show the whole table:
-- SELECT * FROM bronze.crm_prd_info;

--Check for nulls and duplicates:
--Expectation: NO results
SELECT prd_id, COUNT(*) FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 or prd_id IS NULL;

--Check for unwanted spaces:
--Expectation: NO results
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

--Check for Nulls or negative numbers:
--Expectation: NO results
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

--Check for consistency and standardization in low cardinality values
--Expectation: 1 of 4 values (or Unknown in case it does not exist)
SELECT DISTINCT prd_line FROM bronze.crm_prd_info;

/*
Modify silver table to correctly accommodate changes that will be made to insert the data.

Modification: ADDED cat_id to the table, this separates product category from product key and helps to make
later relationships between tables
*/
IF OBJECT_ID ('silver.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
	prd_id INT,
	cat_id NVARCHAR(50),
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(50),
	prd_start_date DATE,
	prd_end_date DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

--Clean any found errors and INSERT into silver layer Table:

INSERT INTO silver.crm_prd_info (
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_date,
prd_end_date
)
SELECT
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
ELSE 'Unknown'
END AS prd_line,
prd_start_date,
DATEADD(day, -1, LEAD(prd_start_date) OVER (PARTITION BY prd_key ORDER BY prd_start_date)) AS prd_end_date
FROM bronze.crm_prd_info;

--Check the loaded data for correctness:
--SELECT * FROM silver.crm_prd_info;

--Check for nulls and duplicates:
--Expectation: NO results
SELECT prd_id, COUNT(*) FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 or prd_id IS NULL;

--Check for unwanted spaces:
--Expectation: NO results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

--Check for Nulls or negative numbers:
--Expectation: NO results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

--Check for consistency and standardization in low cardinality values
--Expectation: 1 of 4 values (or Unknown in case it does not exist)
SELECT DISTINCT prd_line FROM silver.crm_prd_info;