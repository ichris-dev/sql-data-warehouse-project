-- ============================================================
-- Script: ddl_bronze.sql
-- ============================================================
-- Purpose:
--   This script creates tables in the "bronze" schema, dropping
--   existing tables, if they exist
--
-- Run this script to redefine the ddl structre
-- ============================================================

DROP TABLE IF EXISTS bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info(
	cst_id INTEGER,
	cst_key NVARCHAR(50),
	cst_firstname NVARCHAR(50),
	cst_lastname NVARCHAR(50),
	cst_marital_status NVARCHAR(50),
	cst_gndr NVARCHAR(50),
	cst_create_date DATE
);

DROP TABLE IF EXISTS bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info(
	prd_id INTEGER,
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INTEGER,
	prd_line NVARCHAR(50),
	prd_start_dt Datetime,
	prd_end_dt Datetime
);

DROP TABLE IF EXISTS bronze.crm_sales_details; 
CREATE TABLE bronze.crm_sales_details(
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INTEGER,
	sls_order_dt INTEGER,
	sls_ship_dt INTEGER,
	sls_due_dt INTEGER,
	sls_sales INTEGER,
	sls_quantity INTEGER,
	sls_price INTEGER
);

DROP TABLE IF EXISTS bronze.erp_cust_az12; 
CREATE TABLE bronze.erp_cust_az12(
	cid NVARCHAR(50),
	bdate DATE,
	gen NVARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_loc_a101; 
CREATE TABLE bronze.erp_loc_a101(
	cid NVARCHAR(50),
	cntry NVARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2; 
CREATE TABLE bronze.erp_px_cat_g1v2(
	id NVARCHAR(50),
	cat NVARCHAR(50),
	subcat NVARCHAR(50),
	maintenance NVARCHAR(50)
);







