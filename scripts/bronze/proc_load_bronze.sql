-- ============================================================
-- Script: proc_load_bronze.sql
-- ============================================================
-- Purpose:
--    This script loads data into bronze schama table from extarnal
--    CSV file
--    It performs the following actions:
--      - Truncates existing table if they exist with data for each table in bronze layer
--      - Bulk inser data from specific csv files passed using file paths
-- Usage:
--   - The script can be runned directly in a duckdb editor os normal script eg: Ctlr + Enter in dbeaver
--   - it can be saved and runned using an automating system eg: apache airflow
--
-- =============================================================


SELECT '==============================================' AS message;
SELECT 'Loading Bronze Layer' AS message;
SELECT '==============================================' AS message;


SELECT '----------------------------------------------' AS message;
SELECT 'Loading CRM Tables' AS message;
SELECT '----------------------------------------------' AS message;

SELECT 'Truncating Table: bronze.crm_cust_info' AS message;
TRUNCATE TABLE bronze.crm_cust_info;
SELECT 'Inserting Data Into: bronze.crm_cust_info' AS message;
COPY bronze.crm_cust_info
FROM "C:\Users\timot\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv"
(FORMAT CSV, HEADER TRUE);



SELECT 'Truncating Table: bronze.crm_prd_info' AS message;
TRUNCATE TABLE bronze.crm_prd_info;
SELECT 'Inserting Data Into: bronze.crm_prd_info' AS message;
COPY bronze.crm_prd_info
FROM "C:\Users\timot\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv"
(FORMAT CSV, HEADER TRUE);



SELECT 'Truncating Table: bronze.crm_sales_details' AS message;
TRUNCATE TABLE bronze.crm_sales_details;
SELECT 'Inserting Data Into: bronze.crm_sales_details' AS message;
COPY bronze.crm_sales_details
FROM "C:\Users\timot\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv"
(FORMAT CSV, HEADER TRUE);



SELECT '----------------------------------------------' AS message;
SELECT 'Loading ERP Tables' AS message;
SELECT '----------------------------------------------' AS message;


SELECT 'Truncating Table: bronze.erp_cust_az12' AS message;
TRUNCATE TABLE bronze.erp_cust_az12;
SELECT 'Inserting Data Into: bronze.erp_cust_az12' AS message;
COPY bronze.erp_cust_az12
FROM "C:\Users\timot\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv"
(FORMAT CSV, HEADER TRUE);



SELECT 'Truncating Table: bronze.erp_loc_a101' AS message;
TRUNCATE TABLE bronze.erp_loc_a101;
SELECT 'Inserting Data Into: bronze.erp_loc_a101' AS message;
COPY bronze.erp_loc_a101
FROM "C:\Users\timot\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv"
(FORMAT CSV, HEADER TRUE);



SELECT 'Truncating Table: bronze.erp_px_cat_g1v2' AS message;
TRUNCATE TABLE bronze.erp_px_cat_g1v2;
SELECT 'Inserting Data Into: bronze.erp_px_cat_g1v2' AS message;
COPY bronze.erp_px_cat_g1v2
FROM "C:\Users\timot\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv"
(FORMAT CSV, HEADER TRUE);








