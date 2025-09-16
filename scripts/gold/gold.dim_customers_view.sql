--Join customer information tables
SELECT
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gender,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid

--Check for duplicates after joining
SELECT cst_id, COUNT(*) FROM (
SELECT
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gender,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid) AS qry GROUP BY cst_id HAVING COUNT(*) > 1

/*
Deal with repeated data by integrating it (customer gender):
INFO: The NULL gender comes from joining the tables,
because there is no customer in one table (null value) that matches the other table (value exists)
INFO2: The master table selected is the crm_cust_info, which overwrites other tables data (Gender in this case)
*/
SELECT DISTINCT
	ci.cst_gender,
	ca.gen,
	CASE
		WHEN ci.cst_gender != 'Unknown' THEN ci.cst_gender
		ELSE COALESCE(ca.gen, 'Unknown')
	END AS new_gender
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid
ORDER BY 1, 2

/*
Final Join with integrated data of customer information tables
and created view in gold layer
Info: generated surrogate key to connect the data model (customer_key)
*/
CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	ci.cst_marital_status AS marital_status,
	la.cntry AS country,
	CASE
		WHEN ci.cst_gender != 'Unknown' THEN ci.cst_gender
		ELSE COALESCE(ca.gen, 'Unknown')
	END AS gender,
	ca.bdate AS birth_date,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid