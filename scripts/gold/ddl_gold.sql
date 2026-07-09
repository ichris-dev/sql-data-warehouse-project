-- ============================================================
-- Script: ddl_gold.sql
-- ============================================================
-- Purpose:
--   Creates the Gold Layer views for the data warehouse.
--   These views expose business-ready, star-schema-modeled data
--   built directly on top of the Silver layer. They are computed
--   on read (no physical storage) and always reflect the latest
--   Silver data. Surrogate keys are generated here via
--   ROW_NUMBER() and are not persisted source-system IDs.
-- ============================================================


-- ============================================================
-- View: gold.dim_customers
-- ============================================================
-- Customer dimension. Combines CRM customer master data with
-- ERP demographic (gender/birthdate) and location (country)
-- data. CRM gender is preferred; ERP gender is used as a
-- fallback whenever CRM has no value ('n/a').
-- ============================================================
DROP VIEW IF EXISTS gold.dim_customers;
CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER(ORDER BY cci.cst_id ) AS customer_key,     -- surrogate key for the dimension
	cci.cst_id AS customer_id,                                   -- source system customer id (CRM)
	cci.cst_key AS customer_number,                               -- business/alphanumeric customer number
	cci.cst_firstname  AS first_name,
	cci.cst_lastname AS last_name,
	ela.cntry AS country,                                         -- from ERP location data
	cci.cst_marital_status AS marital_status,
	-- Prefer CRM gender; fall back to ERP gender when CRM value is missing/unknown
	CASE
		WHEN cci.cst_gndr != 'n/a' THEN cci.cst_gndr
		ELSE COALESCE(eca.gen, 'n/a')
	END AS gender,
	eca.bdate AS birthdate,                                       -- from ERP demographic data
	cci.cst_create_date AS create_date
FROM silver.crm_cust_info cci
LEFT JOIN silver.erp_cust_az12 eca   -- ERP demographics (gender, birthdate)
ON        cci.cst_key = eca.cid
LEFT JOIN silver.erp_loc_a101 ela    -- ERP location (country)
ON        cci.cst_key = ela.cid;



-- ============================================================
-- View: gold.fact_sales
-- ============================================================
-- Sales fact view. One row per sales order line, with
-- product_key/customer_key resolved against the gold
-- dimension views so it can be joined straight into a star
-- schema for reporting.
-- ============================================================
DROP VIEW IF EXISTS gold.fact_sales ;
CREATE VIEW gold.fact_sales AS
SELECT
	csd.sls_ord_num AS order_number,
	dp.product_key ,                  -- resolved via dim_products (product_number match)
	dc.customer_key ,                 -- resolved via dim_customers (customer_id match)
	csd.sls_order_dt AS order_date ,
	csd.sls_ship_dt AS shipping_date ,
	csd.sls_due_dt AS due_date ,
	csd.sls_sales AS sales_amount ,
	csd.sls_quantity AS quantity ,
	csd.sls_price AS price
FROM silver.crm_sales_details csd
LEFT JOIN gold.dim_products dp       -- look up surrogate product_key
ON        csd.sls_prd_key = dp.product_number
LEFT JOIN gold.dim_customers dc      -- look up surrogate customer_key
ON        csd.sls_cust_id = dc.customer_id ;


-- ============================================================
-- View: gold.dim_products
-- ============================================================
-- Product dimension. Combines CRM product master data with ERP
-- category/subcategory/maintenance reference data. Only current
-- products are included (prd_end_dt IS NULL filters out
-- historical/superseded product versions).
-- ============================================================
DROP VIEW IF EXISTS gold.dim_products ;
CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER(ORDER BY cpi.prd_start_dt, cpi.prd_key ) AS product_key,  -- surrogate key for the dimension
	cpi.prd_id AS product_id,                                    -- source system product id (CRM)
	cpi.prd_key AS product_number,                                -- business/alphanumeric product key
	cpi.prd_nm AS product_name,
	cpi.cat_id AS category_id,
	epcgv.cat AS category,                                        -- from ERP category reference data
	epcgv.subcat AS subcategory,                                  -- from ERP category reference data
	epcgv.maintenance,
	cpi.prd_cost AS cost,
	cpi.prd_line AS product_line,
	cpi.prd_start_dt AS start_date
FROM silver.crm_prd_info cpi
LEFT JOIN silver.erp_px_cat_g1v2 epcgv    -- ERP category/subcategory/maintenance lookup
ON        cpi.cat_id  = epcgv.id
WHERE cpi.prd_end_dt IS NULL;   -- keep only the current (non-historical) version of each product
