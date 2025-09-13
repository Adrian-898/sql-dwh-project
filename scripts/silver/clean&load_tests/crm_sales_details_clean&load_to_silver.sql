/*
Data cleaning and loading

includes Data cleaning, Standardization, Validation etc...
the Cleaned Data is then loaded to the same table in the silver layer schema.
*/

-- Show the whole table:
-- SELECT * FROM bronze.crm_sales_details;

--Check for unwanted spaces:
--Expectation: NO results
SELECT sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

SELECT sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key != TRIM(sls_prd_key);

--Check if all records from sales exist in the crm_cust_info and crm_prd_info tables in order to create relationship.
--Expectation: NO results
SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_date,
sls_ship_date,
sls_due_date,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
--WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);
--WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

--Check for invalid dates
--Expectation: NO negative numbers or Zeros, 8 digits long, in date range.
SELECT 
NULLIF(sls_order_date, 0) AS sls_order_date
FROM bronze.crm_sales_details
WHERE sls_order_date <= 0 
OR LEN(sls_order_date) != 8
OR sls_order_date > 20300101
OR sls_order_date < 20000101;

--Check for invalid date orders
--Expectation: order date must be earlier than ship or due date
SELECT * FROM bronze.crm_sales_details
WHERE CASE WHEN sls_order_date = 0 OR LEN(sls_order_date) != 8 THEN NULL
ELSE CAST(CAST(sls_order_date AS VARCHAR) AS DATE) END > sls_ship_date;

/*
Check data consistency between sales, quantity and price
Sales = Quantity * Price
Expectation: NO nulls, negatives or zeros

Rules for fixing the errors: 
Sales: Derive value from quantity and price
Price: if negative, transform to positive
Price: if Null or zero, derive from quantity and sales
*/
SELECT DISTINCT
sls_sales AS old_sales,
sls_price AS old_price,
CASE 
	WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
ELSE sls_sales 
END AS sls_sales,
sls_quantity,
CASE 
	WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity, 0)
ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;

--Drop and recreate the table DDL to accommodate the changes to be made:
--Changed the sls_order_date data type from INT to DATE.
IF OBJECT_ID ('silver.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_date DATE,
	sls_ship_date DATE,
	sls_due_date DATE,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

-- Clean all errors and load the data to the silver layer table:
INSERT INTO silver.crm_sales_details
(
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_date,
sls_ship_date,
sls_due_date,
sls_sales,
sls_quantity,
sls_price
)
SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_date = 0 OR LEN(sls_order_date) != 8 THEN NULL
ELSE CAST(CAST(sls_order_date AS VARCHAR) AS DATE)
END AS sls_order_date,
sls_ship_date,
sls_due_date,
CASE 
	WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
ELSE sls_sales 
END AS sls_sales,
sls_quantity,
CASE 
	WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity, 0)
ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details

--Check Loaded data in silver layer is correct:
SELECT * FROM silver.crm_sales_details

--Check for invalid date orders
--Expectation: order date must be earlier than ship or due date
SELECT * FROM silver.crm_sales_details
WHERE sls_order_date > sls_ship_date OR sls_order_date > sls_due_date;

/*
Check data consistency between sales, quantity and price
Sales = Quantity * Price
Expectation: NO nulls, negatives or zeros
*/
SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;