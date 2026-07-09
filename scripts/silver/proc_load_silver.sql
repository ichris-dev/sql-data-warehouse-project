-- =========================================================
-- CRM: Customer Info
-- Cleans customer records: trims names, standardizes marital
-- status and gender codes, keeps only the MOST RECENT record
-- per customer (via ROW_NUMBER), and casts create_date to DATE.
-- =========================================================
TRUNCATE TABLE silver.crm_cust_info;
INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
)
SELECT 
 t.cst_id,
 t.cst_key,
 TRIM(t.cst_firstname) AS cst_firstname,
 TRIM(t.cst_lastname) AS cst_lastname,
 CASE 
 	WHEN UPPER(TRIM(t.cst_marital_status)) = 'S' THEN 'Single'
 	WHEN UPPER(TRIM(t.cst_marital_status)) = 'M' THEN 'Married'
 	ELSE 'n/a'
 END cst_marital_status,
 CASE 
 	WHEN UPPER(TRIM(t.cst_gndr)) = 'F' THEN 'Female'
 	WHEN UPPER(TRIM(t.cst_gndr)) = 'M' THEN 'MALE'
 	ELSE 'n/a'
 END cst_gndr,
 CAST(t.cst_create_date AS DATE) AS cst_create_date
FROM (
	-- Dedup subquery: rank rows per customer, newest create_date first
	SELECT  
		cci.*,
		ROW_NUMBER() OVER(PARTITION BY cci.cst_id ORDER BY cci.cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info cci
	WHERE cci.cst_id IS NOT NULL
)t WHERE t.flag_last = 1;  -- keep only the latest record per customer


-- =========================================================
-- CRM: Product Info
-- Rebuilds the product table: splits prd_key into a category
-- ID (cat_id) and the actual product key, defaults null cost
-- to 0, expands product line codes into readable labels, and
-- derives prd_end_dt as "the day before the next version of
-- this product starts" using LEAD().
-- =========================================================
DROP TABLE IF EXISTS silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info(
	prd_id INTEGER,
	cat_id NVARCHAR(50),
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INTEGER,
	prd_line NVARCHAR(50),
	prd_start_dt DATE,
	prd_end_dt DATE,
	dwh_create_date DATETIME DEFAULT CURRENT_DATE
);

TRUNCATE TABLE silver.crm_prd_info;
INSERT INTO silver.crm_prd_info (
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
SELECT 
	cpi.prd_id,
	REPLACE(SUBSTRING(cpi.prd_key, 1, 5), '-', '_') AS cat_id,        -- first 5 chars = category id (dashes -> underscores)
	SUBSTRING(cpi.prd_key , 7, LENGTH(prd_key)) AS prd_key,           -- remainder = the real product key
	cpi.prd_nm,
	IFNULL(cpi.prd_cost, 0) AS prd_cost,                              -- null cost -> 0
	CASE UPPER(TRIM(cpi.prd_line))                                    -- map single-letter product line codes to names
		WHEN 'M' THEN 'Mountain'
		WHEN 'R' THEN 'Road'
		WHEN 'S' THEN 'Other Sales'
		WHEN 'T' THEN 'Touring'
		ELSE 'n/a'
	END prd_line,
	cpi.prd_start_dt,
	-- end date = one day before the next row's start date for the same prd_key (i.e. history versioning)
	CAST(LEAD(cpi.prd_start_dt ) OVER(PARTITION BY cpi.prd_key ORDER BY cpi.prd_start_dt ) - INTERVAL 1 DAY AS DATE) AS  prd_end_dt
FROM bronze.crm_prd_info cpi;


-- =========================================================
-- CRM: Sales Details
-- Parses integer-encoded dates (YYYYMMDD) into real DATEs
-- (nulling out anything invalid/zero/wrong length), recomputes
-- sls_sales when it's missing or inconsistent with price*qty,
-- and backfills sls_price from sales/quantity when it's
-- missing or non-positive.
-- =========================================================
DROP TABLE IF EXISTS silver.crm_sales_details; 
CREATE TABLE silver.crm_sales_details(
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INTEGER,
	sls_order_dt DATE,
	sls_ship_dt DATE,
	sls_due_dt DATE,
	sls_sales INTEGER,
	sls_quantity INTEGER,
	sls_price INTEGER,
	dwh_create_date DATETIME DEFAULT CURRENT_DATE
);

TRUNCATE TABLE silver.crm_sales_details;
INSERT INTO silver.crm_sales_details (
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)
SELECT 
	csd.sls_ord_num ,
	csd.sls_prd_key ,
	csd.sls_cust_id ,
	-- order/ship/due dates come in as 8-digit ints (YYYYMMDD); null out anything malformed, else parse
	CASE
		WHEN csd.sls_order_dt <= 0 OR LENGTH(CAST(csd.sls_order_dt AS VARCHAR)) != 8 THEN NULL
		ELSE STRPTIME(CAST(csd.sls_order_dt AS VARCHAR), '%Y%m%d')
	END sls_order_dt,
	CASE
		WHEN csd.sls_ship_dt <= 0 OR LENGTH(CAST(csd.sls_ship_dt AS VARCHAR)) != 8 THEN NULL
		ELSE STRPTIME(CAST(csd.sls_ship_dt AS VARCHAR), '%Y%m%d')
	END sls_ship_dt,
	CASE
		WHEN csd.sls_due_dt <= 0 OR LENGTH(CAST(csd.sls_due_dt AS VARCHAR)) != 8 THEN NULL
		ELSE STRPTIME(CAST(csd.sls_due_dt AS VARCHAR), '%Y%m%d')
	END sls_due_dt,
	-- sales must equal |price| * quantity; if it's null/zero/inconsistent, recompute it
	CASE
		WHEN csd.sls_sales IS NULL OR csd.sls_sales <= 0 OR csd.sls_sales != (ABS(csd.sls_price) * csd.sls_quantity)
		THEN (ABS(csd.sls_price) * csd.sls_quantity)
		ELSE csd.sls_sales
	END sls_sales,
	csd.sls_quantity ,
	-- if price is missing/invalid, derive it from sales / quantity instead
	CASE
		WHEN csd.sls_price IS NULL OR csd.sls_price <= 0 
		THEN csd.sls_sales  / NULLIF(csd.sls_quantity, 0)
		ELSE csd.sls_price
	END sls_price
FROM bronze.crm_sales_details csd;


-- =========================================================
-- ERP: Customer (AZ12)
-- Strips a 'NAS' prefix from customer IDs where present,
-- nulls out future birthdates (bad data), and standardizes
-- gender codes/labels into 'Male'/'Female'/'n/a'.
-- =========================================================
TRUNCATE TABLE silver.erp_cust_az12;
INSERT INTO silver.erp_cust_az12 (
	cid ,
	bdate ,
	gen
)
SELECT 
 CASE 
 	WHEN eca.cid LIKE 'NAS%' THEN SUBSTRING(eca.cid , 4, LENGTH(eca.cid))   -- drop leading 'NAS' prefix
 	ELSE eca.cid 
 END cid_new,
 CASE 
 	WHEN eca.bdate > NOW() THEN NULL   -- birthdate in the future is invalid
 	ELSE eca.bdate 
 END bdate,
 CASE UPPER(TRIM(eca.gen))
	    WHEN 'M' THEN 'Male'
	    WHEN 'MALE' THEN 'Male'
	    WHEN 'F' THEN 'Female'
	    WHEN 'FEMALE' THEN 'Female'
	    ELSE 'n/a'
 END gen
FROM bronze.erp_cust_az12 eca;


-- =========================================================
-- ERP: Location (A101)
-- Removes dashes from customer IDs and normalizes country
-- codes/blank values into full readable country names.
-- =========================================================
TRUNCATE TABLE silver.erp_loc_a101;
INSERT INTO silver.erp_loc_a101 (
	cid,
	cntry
)
SELECT
	REPLACE(ela.cid , '-', '') AS cid,   -- strip dashes from id
	CASE 
		WHEN TRIM(ela.cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(ela.cntry) IN ('US', 'USA') THEN 'United States'
		WHEN TRIM(ela.cntry) IS NULL OR TRIM(ela.cntry) = '' THEN 'n/a'
		ELSE TRIM(ela.cntry)
	END cntry
FROM bronze.erp_loc_a101 ela;


-- =========================================================
-- ERP: Product Category (G1V2)
-- Straight passthrough load of category/subcategory/
-- maintenance reference data — no transformation needed.
-- =========================================================
TRUNCATE TABLE silver.erp_px_cat_g1v2;
INSERT INTO silver.erp_px_cat_g1v2 (
	id,
	cat,
	subcat,
	maintenance
)
SELECT 
	epcgv.id ,
	epcgv.cat ,
	epcgv.subcat ,
	epcgv.maintenance 
FROM bronze.erp_px_cat_g1v2 epcgv;
