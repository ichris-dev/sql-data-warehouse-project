-- ============================================================
-- Creating a DuckDB Database in DBeaver
-- ============================================================
--
-- This guide explains how to create a new DuckDB database
-- (.duckdb file) using DBeaver.
--
-- ============================================================
-- Prerequisites
-- ============================================================
--
-- • DBeaver installed
-- • Internet connection (only required the first time to
--   download the DuckDB JDBC driver)
--
-- ============================================================
-- Step 1: Open DBeaver
-- ============================================================
--
-- Launch DBeaver on your computer.
--
-- ============================================================
-- Step 2: Create a New Database Connection
-- ============================================================
--
-- • Click "New Database Connection".
-- • Alternatively, press Ctrl + Shift + N.
--
-- ============================================================
-- Step 3: Select DuckDB
-- ============================================================
--
-- 1. Search for DuckDB.
-- 2. Select DuckDB from the list.
-- 3. Click Next.
--
-- If prompted, allow DBeaver to download the DuckDB JDBC driver.
--
-- ============================================================
-- Step 4: Create the Database File
-- ============================================================
--
-- 1. In the Database/File field, click Browse.
-- 2. Navigate to the folder where you want to save the database.
-- 3. Enter a file name ending with ".duckdb".


-- If the file does not already exist, DuckDB will create it
-- automatically.
-- • DuckDB is a file-based database, not a database server.
-- • A ".duckdb" file IS the database.
-- • To create another database, simply create another .duckdb file.
-- • Schemas such as bronze, silver, and gold help organize data
--   according to the Medallion Architecture.
-- ============================================================


-- Showinf that we are using the DataWarehouse db
USE DataWarehouse;

-- Create the Bronze schema
CREATE SCHEMA bronze;

-- Create the Silver schema
CREATE SCHEMA silver;

-- Create the Gold schema
CREATE SCHEMA gold;
