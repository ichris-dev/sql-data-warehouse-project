-- ============================================================
-- Script: quality_checks_gold.sql
-- ============================================================
-- Purpose:
--   Data quality / sanity checks on the gold layer views.
--   These validate the source data feeding dim_customers and
--   spot-check the resulting gold views and their join
--   integrity.
-- ============================================================


-- ============================================================
-- Source check: silver.crm_cust_info / silver.erp_cust_az12
-- ============================================================

-- Check: Compare CRM vs ERP gender values and preview the
-- fallback logic used in gold.dim_customers (CRM gender
-- preferred, ERP gender used when CRM is 'n/a').
-- Filtered to rows where either source is missing gender, to
-- inspect how the fallback resolves those cases.
SELECT
	cci.cst_gndr ,
	eca.gen ,
	CASE
		WHEN cci.cst_gndr != 'n/a' THEN cci.cst_gndr
		ELSE COALESCE(eca.gen, 'n/a')
	END new_gen
FROM silver.crm_cust_info cci
LEFT JOIN silver.erp_cust_az12 eca
ON        cci.cst_key = eca.cid
LEFT JOIN silver.erp_loc_a101 ela
ON        cci.cst_key = ela.cid
WHERE eca.gen = 'n/a' OR cci.cst_gndr = 'n/a';


-- ============================================================
-- Table: gold.dim_customers
-- ============================================================

-- Check: Data standardization & consistency of resolved gender
-- values in the view (should only be 'Male', 'Female', 'n/a')
SELECT DISTINCT dc.gender FROM gold.dim_customers dc;


-- ============================================================
-- Table: gold.dim_products
-- ============================================================

-- Check: Full table preview
SELECT dp.* FROM gold.dim_products dp;


-- ============================================================
-- Table: gold.fact_sales
-- ============================================================

-- Check: Referential integrity — every fact row should
-- successfully join to both dimensions via product_key /
-- customer_key. Rows with NULLs in dc.* or dp.* after the
-- join indicate a fact row whose key didn't resolve to a
-- dimension member.
SELECT fs.*
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc
ON        fs.customer_key = dc.customer_key
LEFT JOIN gold.dim_products dp
ON        fs.product_key = dp.product_key;
