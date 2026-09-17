-- 1. DIMENSION TABLES
-- Department
CREATE TABLE dim_department (
    department_id     INT PRIMARY KEY,
    department_name   NVARCHAR(50) NOT NULL

);
-- Category
CREATE TABLE dim_category (
    category_id       INT PRIMARY KEY,
    category_name     VARCHAR(100) NOT NULL,
    department_id     INT REFERENCES dim_department(department_id)
);

-- Product
CREATE TABLE dim_product (
    product_card_id      INT PRIMARY KEY,
    product_name          VARCHAR(200) NOT NULL,
    product_price          NUMERIC(12,2),
    product_status         INT,               -- 0/1: còn bán hay ngừng bán
    product_description   VARCHAR(MAX),
    category_id            INT REFERENCES dim_category(category_id)
);

-- Customer
CREATE TABLE dim_customer (
    customer_id        INT PRIMARY KEY,
    fname               VARCHAR(100),
    lname               VARCHAR(100),
    email               VARCHAR(100),
    segment             VARCHAR(50),   -- Consumer / Corporate / Home Office
    login_type          VARCHAR(50),
    street              VARCHAR(150),
    city                VARCHAR(100),
    state               VARCHAR(50),
    country             VARCHAR(100),
    zipcode             VARCHAR(20),
    latitude            NUMERIC(10,6),
    longitude           NUMERIC(10,6)
);

-- Location/Region dùng cho order (đôi khi khác địa chỉ khách hàng gốc)
CREATE TABLE dim_order_location (
    location_id      INT IDENTITY(1,1) PRIMARY KEY,
    order_city       VARCHAR(100),
    order_state      VARCHAR(100),
    order_country    VARCHAR(100),
    order_region     VARCHAR(100),
    order_zipcode    VARCHAR(20),
    market           VARCHAR(50),      -- LATAM, Europe, Pacific Asia...
    UNIQUE (order_city, order_state, order_country, order_region, order_zipcode, market)
);


-- ============================================================
-- 3. FACT TABLES
-- ============================================================

-- Fact: 1 dòng = 1 order (header)
CREATE TABLE fact_orders (
    order_id                      INT PRIMARY KEY,
    customer_id                    INT REFERENCES dim_customer(customer_id),
    location_id                    INT REFERENCES dim_order_location(location_id),
    order_date                     DATETIME2 NOT NULL,
    shipping_date                  DATETIME2,
    shipping_mode                  VARCHAR(50),     -- Standard/First/Second Class, Same Day
    order_status                   VARCHAR(50),     -- COMPLETE, PENDING, CANCELED...
    delivery_status                VARCHAR(50),     -- Late/On time/Advance shipping...
    days_for_shipping_real         INT,
    days_for_shipment_scheduled    INT,
    late_delivery_risk             INT              -- 1 = trễ, 0 = đúng hẹn (dùng cho Risk Management)
);

-- Fact: 1 dòng = 1 item trong order (line item)
CREATE TABLE fact_order_items (
    order_item_id            INT PRIMARY KEY,
    order_id                  INT REFERENCES fact_orders(order_id),
    product_card_id           INT REFERENCES dim_product(product_card_id),
    order_item_quantity       INT,
    order_item_product_price  NUMERIC(12,2),
    order_item_discount       NUMERIC(12,2),
    order_item_discount_rate  NUMERIC(5,2),
    order_item_profit_ratio   NUMERIC(6,4),
    sales                     NUMERIC(12,2),        -- doanh thu item (chưa trừ discount)
    order_item_total          NUMERIC(12,2),        -- doanh thu sau discount -> dùng cho Demand
    order_profit_per_order    NUMERIC(12,2),         -- lợi nhuận -> dùng cho Planning/Risk
    benefit_per_order         NUMERIC(12,2)
);
