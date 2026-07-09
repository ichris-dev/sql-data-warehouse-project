# Data Catalog for Gold Layer

## Overview

The Gold Layer is the business-ready layer of the warehouse. It is modeled as a **star schema** and consists of **dimension views** and a **fact view**. All Gold Layer objects are implemented as **SQL views** (not physical tables) — they read directly from the Silver layer and apply final relabeling, joins, and surrogate key generation at query time. This document provides a data dictionary for each view, including column details and how the views connect to one another.

---

## 1. gold.dim_customers

**Purpose:** Stores customer details enriched with demographic and geographic data, combining CRM and ERP customer sources.

**Type:** View

| Column Name     | Data Type | Description                                                                 |
|------------------|-----------|-------------------------------------------------------------------------------|
| customer_key     | INTEGER   | Surrogate key uniquely identifying each customer record in the dimension.     |
| customer_id      | INTEGER   | Source system unique identifier assigned to each customer.                    |
| customer_number  | NVARCHAR(50) | Alphanumeric identifier used to track/reference the customer (e.g. AW00011000). |
| first_name       | NVARCHAR(50) | Customer's first name, as recorded in the source system.                   |
| last_name        | NVARCHAR(50) | Customer's last name, as recorded in the source system.                    |
| country          | NVARCHAR(50) | Country of residence for the customer (e.g. 'Australia').                  |
| marital_status   | NVARCHAR(50) | Marital status of the customer (e.g. 'Married', 'Single').                 |
| gender           | NVARCHAR(50) | Gender of the customer (e.g. 'Male', 'Female', 'n/a').                     |
| birthdate        | DATE      | Customer's date of birth, formatted as YYYY-MM-DD.                            |
| create_date      | DATE      | Date the customer record was first created in the source system.              |

---

## 2. gold.dim_products

**Purpose:** Provides information about products and their attributes, including category, subcategory, and cost.

**Type:** View

| Column Name    | Data Type | Description                                                                    |
|------------------|-----------|-----------------------------------------------------------------------------|
| product_key      | INTEGER   | Surrogate key uniquely identifying each product record in the dimension.      |
| product_id       | INTEGER   | Source system unique identifier assigned to the product.                      |
| product_number   | NVARCHAR(50) | Structured alphanumeric code representing the product (e.g. category/style identifiers), used for categorization or inventory. |
| product_name     | NVARCHAR(50) | Descriptive name including key attributes such as type, color, and size.   |
| category_id      | NVARCHAR(50) | Code identifying the product's category (links to category grouping).      |
| category         | NVARCHAR(50) | Broader classification of the product (e.g. Bikes, Components, Clothing, Accessories) to group related items. |
| subcategory      | NVARCHAR(50) | More detailed classification within the category, e.g. product type (Road Frames, Mountain Bikes). |
| maintenance      | NVARCHAR(50) | Indicates whether the product requires maintenance ('Yes'/'No').           |
| cost             | INTEGER   | Cost or base price of the product, in whole currency units.                   |
| product_line     | NVARCHAR(50) | Product line/series the item belongs to (e.g. Road, Mountain, Touring, Other Sales, n/a). |
| start_date       | DATE      | Date the product became active/available for sale.                            |

---

## 3. gold.fact_sales

**Purpose:** Stores transactional sales data for analytical purposes, capturing order-level measures such as quantity, price, and sales amount.

**Type:** View

| Column Name    | Data Type | Description                                                                    |
|------------------|-----------|-----------------------------------------------------------------------------|
| order_number     | NVARCHAR(50) | Unique alphanumeric identifier for each sales order (e.g. SO43697).        |
| product_key      | INTEGER   | Surrogate key linking to `gold.dim_products.product_key`.                     |
| customer_key     | INTEGER   | Surrogate key linking to `gold.dim_customers.customer_key`.                   |
| order_date       | DATE      | Date the order was placed.                                                     |
| shipping_date    | DATE      | Date the order was shipped to the customer.                                    |
| due_date         | DATE      | Date by which payment or delivery was due.                                     |
| sales_amount     | INTEGER   | Total monetary value of the line item (quantity × price), in whole currency units. |
| quantity         | INTEGER   | Number of units of the product ordered in the line item.                       |
| price            | INTEGER   | Unit price of the product for this order line, in whole currency units.        |

---

## Connectivity Between Tables

`gold.fact_sales` is the central fact view in the star schema and connects to both dimension views through surrogate keys:

- **`fact_sales.product_key` → `dim_products.product_key`** (many-to-one)
  Each row in `fact_sales` represents one order line for a single product; each product in `dim_products` can appear in many sales rows.

- **`fact_sales.customer_key` → `dim_customers.customer_key`** (many-to-one)
  Each row in `fact_sales` is tied to a single customer; each customer in `dim_customers` can have many sales rows.

```
                dim_customers
                (customer_key) ─┐
                                 │  1
                                 │
                                 ▼  N
                            fact_sales
                                 ▲  N
                                 │
                                 │  1
                (product_key) ──┘
                dim_products
```

**Example join** — sales enriched with customer and product attributes:

```sql
SELECT
    f.order_number,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.first_name,
    c.last_name,
    c.country,
    p.product_name,
    p.category,
    p.subcategory
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key;
```

### Notes on the Gold Layer views

- All three objects are **views**, not physical tables — they are computed on read from the Silver layer, so they always reflect the latest Silver data without needing a separate load/refresh step.
- Surrogate keys (`customer_key`, `product_key`) are generated within the view definitions (e.g. via `ROW_NUMBER()`) and are stable only as long as the underlying Silver data ordering doesn't change — they are not persisted, durable IDs from the source systems.
- `dim_products` and `dim_customers` are grouped as SCD Type 1–style current-state dimensions (per the project scope, historization of source data is not required).
