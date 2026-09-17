/* ============================================================
   00_staging.sql
   Muc dich: tao bang staging va nap nguyen file
             DataCoSupplyChainDataset.csv vao SQL Server.
   ============================================================ */

CREATE DATABASE DataCoSupplyChain;
GO

USE DataCoSupplyChain;
GO

CREATE TABLE staging_raw_orders (
    payment_type                   VARCHAR(20),      
    days_for_shipping_real         INT,
    days_for_shipment_scheduled    INT,
    benefit_per_order              NUMERIC(12,2),
    sales_per_customer             NUMERIC(12,2),
    delivery_status                VARCHAR(50),
    late_delivery_risk             INT,
    category_id                    INT,
    category_name                  VARCHAR(100),
    customer_city                  VARCHAR(100),
    customer_country               VARCHAR(100),
    customer_email                 VARCHAR(100),
    customer_fname                 VARCHAR(100),
    customer_id                    INT,
    customer_lname                 VARCHAR(100),
    customer_password              VARCHAR(100),   
    customer_segment                VARCHAR(50),
    customer_state                  VARCHAR(50),
    customer_street                 VARCHAR(150),
    customer_zipcode                VARCHAR(20),
    department_id                   INT,
    department_name                 VARCHAR(50),
    latitude                        NUMERIC(10,6),
    longitude                       NUMERIC(10,6),
    market                          VARCHAR(50),
    order_city                      VARCHAR(100),
    order_country                   VARCHAR(100),
    order_customer_id               INT,              -- luon = customer_id
    order_date_raw                  VARCHAR(30),       -- CSV: order date (DateOrders), text tho
    order_id                        INT,
    order_item_cardprod_id          INT,               -- luon = product_card_id
    order_item_discount             NUMERIC(12,2),
    order_item_discount_rate        NUMERIC(5,2),
    order_item_id                   INT,
    order_item_product_price        NUMERIC(12,2),
    order_item_profit_ratio         NUMERIC(6,4),
    order_item_quantity             INT,
    sales                           NUMERIC(12,2),
    order_item_total                NUMERIC(12,2),
    order_profit_per_order          NUMERIC(12,2),
    order_region                    VARCHAR(100),
    order_state                     VARCHAR(100),
    order_status                    VARCHAR(50),
    order_zipcode                   VARCHAR(20),
    product_card_id                 INT,
    product_category_id             INT,               -- luon = category_id
    product_description             VARCHAR(MAX),        -- CSV goc: 100% NULL, giu de dung cau truc
    product_image                   VARCHAR(500),
    product_name                    VARCHAR(200),
    product_price                   NUMERIC(12,2),
    product_status                  INT,
    shipping_date_raw               VARCHAR(30),         -- CSV: shipping date (DateOrders)
    shipping_mode                   VARCHAR(50)
);
GO

/* ============================================================
   NAP DU LIEU
   BULK INSERT (file phai nam tren may SQL Server hoac
   share ma SQL Server service account doc duoc). FORMAT='CSV'
   (SQL Server 2017+) giup xu ly dung cac truong co dau ngoac kep.
   ============================================================ */
BULK INSERT staging_raw_orders
FROM 'C:\Users\Ha Phuong\Documents\2. Practice\SQL\Project\Data-Portfolio\SQL EDA\datasets\DataCoSupplyChainDataset.csv'  --- Nhập đường dẫn thực tế
WITH (
    FIRSTROW      = 2,
    FORMAT        = 'CSV',
    FIELDQUOTE    = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',      -- neu loi, thu doi thanh '\n' hoac '0x0d0a'
    CODEPAGE      = '1252',
    TABLOCK
);
GO

/* ============================================================
   KIEM TRA SAU KHI NAP
   ============================================================ */
SELECT COUNT(*) AS total_rows FROM staging_raw_orders;
-- Total: 180519 dong

SELECT COUNT(DISTINCT order_id) AS total_orders FROM staging_raw_orders;
-- Total: 65752 don hang duy nhat

-- Kiem tra encoding load dung: cac ten co dau/ky tu dac biet
-- (neu bi loi encode se hien thi dau ? hoac ky tu la)
SELECT DISTINCT order_country FROM staging_raw_orders
WHERE order_country LIKE '%[^a-zA-Z0-9 ,.\-()'']%'

-- Kiem tra 2 cap cot "trung nhau"
SELECT COUNT(*) AS mismatch_category
FROM staging_raw_orders WHERE category_id <> product_category_id;   -- ky vong = 0

SELECT COUNT(*) AS mismatch_product
FROM staging_raw_orders WHERE order_item_cardprod_id <> product_card_id;  -- ky vong = 0
