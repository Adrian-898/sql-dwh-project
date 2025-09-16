/*
Create Sales Fact View

Connect both dimensions previously created (customers and products)
from gold layer to sales table from silver layer to create the Sales Fact.

INFO: make sure to put surrogate keys from each table in the new fact table,
INFO2: rename and reorder columns to improve readability
*/

CREATE VIEW gold.fact_sales AS
SELECT
sd.sls_ord_num AS order_number,
pr.product_key,
cr.customer_key,
sd.sls_order_date AS order_date,
sd.sls_ship_date AS shipping_date,
sd.sls_due_date AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cr
ON sd.sls_cust_id = cr.customer_id

--Foreign Key integrity check (dimensions):
SELECT * FROM gold.fact_sales AS sales
LEFT JOIN gold.dim_customers AS customers
ON customers.customer_key = sales.customer_key
LEFT JOIN gold.dim_products AS products
ON products.product_key = sales.product_key
WHERE customers.customer_key IS NULL OR products.product_key IS NULL
