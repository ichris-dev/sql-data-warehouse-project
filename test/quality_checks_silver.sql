-- ============================================================
-- Script: quality_checks_silver.sql
-- ============================================================
-- Purpose:
--   Data quality checks on the silver layer tables. Each check
--   is a standalone SELECT — all are expected to return NO
--   ROWS. Any rows returned indicate bad/dirty data.
-- ============================================================


-- ============================================================
-- Table: silver.crm_prd_info
-- ============================================================

-- Check: Nulls and duplicate primary keys
-- Expectation: No Result
SELECT
	cpi.prd_id,
	COUNT(cpi.*)
FROM silver.crm_prd_info cpi
GROUP BY cpi.prd_id
HAVING COUNT(cpi.*) != 1 OR cpi.prd_id IS NULL;

-- Check: Unwanted leading/trailing spaces in product name
-- Expectation: No Results
SELECT
	cpi.prd_nm
FROM silver.crm_prd_info cpi
WHERE cpi.prd_nm != TRIM(cpi.prd_nm);

-- Check: Nulls or negative product cost
-- Expectation: No Result
SELECT
	cpi.prd_cost
FROM silver.crm_prd_info cpi
WHERE cpi.prd_cost < 0 OR cpi.prd_cost IS NULL;

-- Check: Data standardization & consistency of product line values
SELECT DISTINCT
	cpi.prd_line
FROM silver.crm_prd_info cpi;

-- Check: Invalid date order (end date before start date)
SELECT
	cpi.*
FROM silver.crm_prd_info cpi
WHERE cpi.prd_end_dt < cpi.prd_start_dt;

-- Check: Verify derived prd_end_dt logic (LEAD - 1 day) against actual stored value
SELECT
	cpi.prd_id ,
	cpi.prd_key ,
	cpi.prd_nm ,
	cpi.prd_cost ,
	cpi.prd_line ,
	cpi.prd_start_dt ,
	LEAD(cpi.prd_start_dt ) OVER(PARTITION BY cpi.prd_key ORDER BY cpi.prd_start_dt ) - INTERVAL 1 DAY AS test_end_date,
	cpi.prd_end_dt
FROM silver.crm_prd_info cpi
WHERE cpi.prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509');


-- ============================================================
-- Table: silver.crm_sales_details
-- ============================================================

-- Check: Invalid due dates (zero/negative, wrong length, out of plausible range)
SELECT
    NULLIF(csd.sls_due_dt, 0) AS sls_due_dt
FROM silver.crm_sales_details csd
WHERE csd.sls_due_dt <= 0
OR LENGTH(CAST(csd.sls_due_dt AS VARCHAR)) != 8
OR csd.sls_due_dt > 20500101
OR csd.sls_due_dt < 1900010;

-- Check: Order date later than ship date or due date (should never happen)
SELECT
 csd.*
FROM silver.crm_sales_details csd
WHERE csd.sls_order_dt > csd.sls_ship_dt OR csd.sls_order_dt > csd.sls_due_dt;

-- Check: Data consistency between sales, quantity and price
-- >> Sales = Quantity * Price
-- >> Values must not be Null, Zero or Negative
SELECT
	csd.sls_sales AS old_sales,
	csd.sls_quantity ,
	csd.sls_price AS old_price,
	CASE
		WHEN csd.sls_sales IS NULL OR csd.sls_sales <= 0 OR csd.sls_sales != (ABS(csd.sls_price) * csd.sls_quantity)
		THEN (ABS(csd.sls_price) * csd.sls_quantity)
		ELSE csd.sls_sales
	END sls_sales,
	CASE
		WHEN csd.sls_price IS NULL OR csd.sls_price <= 0
		THEN csd.sls_sales / NULLIF(csd.sls_quantity, 0)
		ELSE csd.sls_price
	END sls_price
FROM bronze.crm_sales_details csd
WHERE csd.sls_sales != (csd.sls_price * csd.sls_quantity)
OR csd.sls_sales <= 0 OR csd.sls_price <= 0 OR csd.sls_quantity <= 0
OR csd.sls_sales IS NULL OR csd.sls_price IS NULL OR csd.sls_quantity IS NULL
ORDER BY csd.sls_sales, csd.sls_price, csd.sls_quantity;

-- Check: Full table preview
SELECT csd.*
FROM silver.crm_sales_details csd;


-- ============================================================
-- Table: silver.erp_cust_az12
-- ============================================================

-- Check: Out-of-range birthdates (future dates)
SELECT DISTINCT eca.bdate
FROM silver.erp_cust_az12 eca
WHERE eca.bdate > NOW();

-- Check: Standardized gender values
SELECT DISTINCT
	CASE UPPER(TRIM(eca.gen))
	    WHEN 'M' THEN 'Male'
	    WHEN 'MALE' THEN 'Male'
	    WHEN 'F' THEN 'Female'
	    WHEN 'FEMALE' THEN 'Female'
	    ELSE 'n/a'
	END gen
FROM silver.erp_cust_az12 eca;

-- Check: Full table preview
SELECT eca.* FROM silver.erp_cust_az12 eca;


-- ============================================================
-- Table: silver.erp_loc_a101
-- ============================================================

-- Check: Data standardization of country values
SELECT DISTINCT ela.cntry
FROM silver.erp_loc_a101 ela;

-- Check: Full table preview
SELECT ela.* FROM silver.erp_loc_a101 ela;


-- ============================================================
-- Table: erp_px_cat_g1v2 (bronze / silver)
-- ============================================================

-- Check: Unwanted leading/trailing spaces in maintenance field (bronze source)
SELECT
	epcgv.*
FROM bronze.erp_px_cat_g1v2 epcgv
WHERE epcgv.maintenance != TRIM(epcgv.maintenance);

-- Check: Data standardization & consistency of maintenance values (bronze source)
SELECT DISTINCT
	epcgv.maintenance
FROM bronze.erp_px_cat_g1v2 epcgv;

-- Check: Full table preview (silver)
SELECT epcgv.* FROM silver.erp_px_cat_g1v2 epcgv;
