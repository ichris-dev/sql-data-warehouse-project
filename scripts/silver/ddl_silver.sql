-- ============================================================
-- Script: ddl_silver.sql
-- ============================================================
-- Purpose:
--   This script creates tables in the "silver" schema, dropping
--   existing tables, if they exist
--
-- Run this script to redefine the ddl structre
-- ============================================================

-- Cleaned customer master data (from CRM source)
-- id, name, marital status, gender, and account create date
DROP TABLE IF EXISTS silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info(
	cst_id INTEGER,
	cst_key NVARCHAR(50),
	cst_firstname NVARCHAR(50),
	cst_lastname NVARCHAR(50),
	cst_marital_status NVARCHAR(50),
	cst_gndr NVARCHAR(50),
	cst_create_date DATE,
	dwh_create_date DATETIME DEFAULT CURRENT_DATE
);

-- Cleaned product master data (from CRM source)
-- includes product line/cost and the start/end validity dates
-- for each version of a product (SCD-style history)
DROP TABLE IF EXISTS silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info(
	prd_id INTEGER,
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INTEGER,
	prd_line NVARCHAR(50),
	prd_start_dt Datetime,
	prd_end_dt Datetime,
	dwh_create_date DATETIME DEFAULT CURRENT_DATE
);

-- Cleaned sales order line data (from CRM source)
-- order/ship/due dates, quantity, price, and total sales per line item
DROP TABLE IF EXISTS silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details(
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INTEGER,
	sls_order_dt INTEGER,
	sls_ship_dt INTEGER,
	sls_due_dt INTEGER,
	sls_sales INTEGER,
	sls_quantity INTEGER,
	sls_price INTEGER,
	dwh_create_date DATETIME DEFAULT CURRENT_DATE
);

-- Cleaned customer demographic data (from ERP source, AZ12)
-- birthdate and gender, keyed by customer id
DROP TABLE IF EXISTS silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12(
	cid NVARCHAR(50),
	bdate DATE,
	gen NVARCHAR(50),
	dwh_create_date DATETIME DEFAULT CURRENT_DATE
);

-- Cleaned customer location data (from ERP source, A101)
-- country per customer id
DROP TABLE IF EXISTS silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101(
	cid NVARCHAR(50),
	cntry NVARCHAR(50),
	dwh_create_date DATETIME DEFAULT CURRENT_DATE
);

-- Product category reference data (from ERP source, G1V2)
-- category, subcategory, and maintenance flag per product id
DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2(
	id NVARCHAR(50),
	cat NVARCHAR(50),
	subcat NVARCHAR(50),
	maintenance NVARCHAR(50),
	dwh_create_date DATETIME DEFAULT CURRENT_DATE
);
