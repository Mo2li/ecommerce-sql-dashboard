/* =====================================================
   Olist E-Commerce — Create database & load all tables
   Dataset: Brazilian E-Commerce Public Dataset (Kaggle)
   ===================================================== */

IF DB_ID('OlistEcommerce') IS NULL
    CREATE DATABASE OlistEcommerce;
GO

USE OlistEcommerce;
GO

/* ---------- drop in FK-safe order on re-run ---------- */
DROP TABLE IF EXISTS order_reviews, order_payments, order_items, orders,
                     customers, sellers, products, category_translation, geolocation;
GO

CREATE TABLE customers (
    customer_id              VARCHAR(50)  NOT NULL PRIMARY KEY,
    customer_unique_id       VARCHAR(50)  NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city            NVARCHAR(100),
    customer_state           CHAR(2)
);

CREATE TABLE sellers (
    seller_id              VARCHAR(50) NOT NULL PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city            NVARCHAR(100),
    seller_state           CHAR(2)
);

CREATE TABLE products (
    product_id                 VARCHAR(50) NOT NULL PRIMARY KEY,
    product_category_name      NVARCHAR(100),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

CREATE TABLE category_translation (
    product_category_name         NVARCHAR(100) NOT NULL PRIMARY KEY,
    product_category_name_english NVARCHAR(100)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat             FLOAT,
    geolocation_lng             FLOAT,
    geolocation_city            NVARCHAR(100),
    geolocation_state           CHAR(2)
);

CREATE TABLE orders (
    order_id                      VARCHAR(50) NOT NULL PRIMARY KEY,
    customer_id                   VARCHAR(50) NOT NULL,
    order_status                  VARCHAR(20),
    order_purchase_timestamp      DATETIME2(0),
    order_approved_at             DATETIME2(0),
    order_delivered_carrier_date  DATETIME2(0),
    order_delivered_customer_date DATETIME2(0),
    order_estimated_delivery_date DATETIME2(0)
);

CREATE TABLE order_items (
    order_id            VARCHAR(50) NOT NULL,
    order_item_id       INT         NOT NULL,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date DATETIME2(0),
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id             VARCHAR(50) NOT NULL,
    payment_sequential   INT,
    payment_type         VARCHAR(30),
    payment_installments INT,
    payment_value        DECIMAL(10,2)
);

CREATE TABLE order_reviews (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50),
    review_score            INT,
    review_comment_title    NVARCHAR(200),
    review_comment_message  NVARCHAR(MAX),
    review_creation_date    DATETIME2(0),
    review_answer_timestamp DATETIME2(0)
);
GO

/* =============== BULK LOAD (UTF-8 CSVs) =============== */
DECLARE @dir NVARCHAR(200) = N'D:\projectes\Data_Analysis\ecommerce-sql-dashboard\data\';

DECLARE @sql NVARCHAR(MAX) = N'
BULK INSERT customers            FROM ''' + @dir + N'olist_customers_dataset.csv''            WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDQUOTE=''"'', CODEPAGE=''65001'', ROWTERMINATOR=''0x0a'', TABLOCK);
BULK INSERT sellers              FROM ''' + @dir + N'olist_sellers_dataset.csv''              WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDQUOTE=''"'', CODEPAGE=''65001'', ROWTERMINATOR=''0x0a'', TABLOCK);
BULK INSERT products             FROM ''' + @dir + N'olist_products_dataset.csv''             WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDQUOTE=''"'', CODEPAGE=''65001'', ROWTERMINATOR=''0x0a'', TABLOCK);
BULK INSERT category_translation FROM ''' + @dir + N'product_category_name_translation.csv''  WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDQUOTE=''"'', CODEPAGE=''65001'', ROWTERMINATOR=''0x0a'', TABLOCK);
BULK INSERT geolocation          FROM ''' + @dir + N'olist_geolocation_dataset.csv''          WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDQUOTE=''"'', CODEPAGE=''65001'', ROWTERMINATOR=''0x0a'', TABLOCK);
BULK INSERT orders               FROM ''' + @dir + N'olist_orders_dataset.csv''               WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDQUOTE=''"'', CODEPAGE=''65001'', ROWTERMINATOR=''0x0a'', TABLOCK);
BULK INSERT order_items          FROM ''' + @dir + N'olist_order_items_dataset.csv''          WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDQUOTE=''"'', CODEPAGE=''65001'', ROWTERMINATOR=''0x0a'', TABLOCK);
BULK INSERT order_payments       FROM ''' + @dir + N'olist_order_payments_dataset.csv''       WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDQUOTE=''"'', CODEPAGE=''65001'', ROWTERMINATOR=''0x0a'', TABLOCK);
BULK INSERT order_reviews        FROM ''' + @dir + N'olist_order_reviews_dataset.csv''        WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDQUOTE=''"'', CODEPAGE=''65001'', ROWTERMINATOR=''0x0a'', TABLOCK);';
EXEC sp_executesql @sql;
GO

/* =============== row counts =============== */
SELECT 'customers' AS tbl, COUNT(*) AS rows_loaded FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
ORDER BY tbl;
GO
