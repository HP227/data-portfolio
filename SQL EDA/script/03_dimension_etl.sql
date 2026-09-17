   /* ============================================================
   ETL: staging_raw_orders -> DIMENSION TABLES
   Thứ tự chạy quan trọng vì có ràng buộc khóa ngoại:
   department -> category -> product
   customer, order_location: độc lập, chạy trước hay sau đều được
   ============================================================ */

-- ============================================================
-- 1. dim_department
-- ============================================================
INSERT INTO dim_department (department_id, department_name)
SELECT DISTINCT
    department_id,
    department_name
FROM staging_raw_orders
WHERE department_id IS NOT NULL;

-- Kiểm tra: 1 department_id có ứng với đúng 1 department_name không?
-- Nếu query dưới đây trả về dòng nào -> có dữ liệu cần xử lý riêng
SELECT department_id, COUNT(DISTINCT department_name) AS name_variations
FROM staging_raw_orders
GROUP BY department_id
HAVING COUNT(DISTINCT department_name) > 1;


-- ============================================================
-- 2. dim_category
-- ============================================================
INSERT INTO dim_category (category_id, category_name, department_id)
SELECT DISTINCT
    category_id,
    category_name,
    department_id
FROM staging_raw_orders
WHERE category_id IS NOT NULL;

-- Kiểm tra tương tự: category_id có bị nhiều department_id khác nhau không?
SELECT category_id, COUNT(DISTINCT department_id) AS dept_variations
FROM staging_raw_orders
GROUP BY category_id
HAVING COUNT(DISTINCT department_id) > 1;


-- ============================================================
-- 3. dim_product
-- Lưu ý: dùng product_category_id trong staging (không phải category_id)
-- vì đây là cột dùng để nối product với category theo cấu trúc CSV gốc
-- ============================================================
INSERT INTO dim_product (product_card_id, product_name, product_price, product_status, product_description, category_id)
SELECT DISTINCT
    product_card_id,
    product_name,
    product_price,
    product_status,
    product_description,
    product_category_id
FROM staging_raw_orders
WHERE product_card_id IS NOT NULL;

-- Kiểm tra product_card_id có bị trùng với giá/tên khác nhau không
SELECT product_card_id, COUNT(*) AS variations
FROM (
    SELECT DISTINCT product_card_id, product_name, product_price
    FROM staging_raw_orders
) t
GROUP BY product_card_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 4. dim_customer
-- ============================================================
INSERT INTO dim_customer (
    customer_id, fname, lname, email, segment,
    street, city, state, country, zipcode, latitude, longitude
)
SELECT DISTINCT
    customer_id,
    customer_fname,
    customer_lname,
    customer_email,
    customer_segment,
    customer_street,
    customer_city,
    customer_state,
    customer_country,
    customer_zipcode,
    latitude,
    longitude
FROM staging_raw_orders
WHERE customer_id IS NOT NULL;

-- Kiểm tra customer_id có bị trùng với thông tin khác nhau không
-- (thường XẢY RA vì 1 khách hàng có thể đặt hàng từ nhiều địa chỉ/toạ độ khác nhau)
SELECT customer_id, COUNT(*) AS variations
FROM (
    SELECT DISTINCT customer_id, customer_city, customer_state, latitude, longitude
    FROM staging_raw_orders
) t
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- ============================================================
-- 5. dim_order_location
-- ============================================================
INSERT INTO dim_order_location (order_city, order_state, order_country, order_region, order_zipcode, market)
SELECT DISTINCT
    order_city,
    order_state,
    order_country,
    order_region,
    order_zipcode,
    market
FROM staging_raw_orders;


-- ============================================================
-- VALIDATION TỔNG QUÁT
-- ============================================================
SELECT 'dim_department' AS table_name, COUNT(*) AS row_count FROM dim_department
UNION ALL
SELECT 'dim_category', COUNT(*) FROM dim_category
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'dim_order_location', COUNT(*) FROM dim_order_location;
