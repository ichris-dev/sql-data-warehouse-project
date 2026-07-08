-- ============================================================
-- Script: create_schemas.sql
-- ============================================================
-- Purpose:
--   This script creates the three core schemas (bronze, silver,
--   gold) inside the "DataWarehouse" DuckDB database, following
--   the Medallion Architecture pattern.
--
--   It assumes the DataWarehouse.duckdb database has already
--   been created and connected to in DBeaver using the steps
--   below:
--
--     Step 1: Open DBeaver
--     Step 2: Create a New Database Connection (Ctrl+Shift+N)
--     Step 3: Select DuckDB as the driver
--     Step 4: Create the Database File (DataWarehouse.duckdb)
--
--   Since DuckDB is a file-based database (the .duckdb file IS
--   the database), this script does not create the database
--   itself — only the schemas within it.
--
-- Schemas created:
--   • bronze  – raw, unprocessed source data (CRM, ERP extracts)
--   • silver  – cleaned, standardized, and conformed data
--   • gold    – business-ready, aggregated/reporting data
--
-- Usage:
--   Run this script after connecting to the DataWarehouse
--   database in DBeaver, before loading any bronze layer tables.
-- ============================================================

USE DataWarehouse;

-- Create the Bronze schema
CREATE SCHEMA bronze;

-- Create the Silver schema
CREATE SCHEMA silver;

-- Create the Gold schema
CREATE SCHEMA gold;
