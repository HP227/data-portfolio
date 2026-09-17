/* ============================================================
   ETL: staging_raw_orders -> FACT TABLES
   Chay SAU 03_dimension_etl.sql (fact co FK tro toi dim_customer,
   dim_order_location, dim_product).
   Thu tu bat buoc: fact_orders TRUOC, fact_order_items SAU
   (vi fact_order_items co FK toi fact_orders.order_id).
   ============================================================ */

-- ============================================================
-- 1. fact_orders (grain: 1 dong = 1 order, 65752 dong ky vong)
-- ============================================================
INSERT INTO fact_orders (
    order_id, customer_id, location_id, order_date, shipping_date,
    shipping_mode, order_status, delivery_status,
    days_for_shipping_real, days_for_shipment_scheduled, late_delivery_risk
)
SELECT
    h.order_id,
    h.customer_id,
    loc.location_id,
    CONVERT(datetime2, h.order_date_raw, 101)    AS order_date,     -- style 101 = mm/dd/yyyy (US)
    CONVERT(datetime2, h.shipping_date_raw, 101) AS shipping_date,
    h.shipping_mode,
    h.order_status,
    h.delivery_status,
    h.days_for_shipping_real,
    h.days_for_shipment_scheduled,
    h.late_delivery_risk
FROM (
    -- Rut gon staging ve muc order-header (khu trung theo tung item)
    SELECT DISTINCT
        order_id, customer_id, order_date_raw, shipping_date_raw,
        shipping_mode, order_status, delivery_status,
        days_for_shipping_real, days_for_shipment_scheduled, late_delivery_risk,
        order_city, order_state, order_country, order_region, order_zipcode, market
    FROM staging_raw_orders
) h
INNER JOIN dim_order_location loc
    ON  loc.order_city    = h.order_city
    AND loc.order_state   = h.order_state
    AND loc.order_country = h.order_country
    AND loc.order_region  = h.order_region
    AND loc.market        = h.market
    -- NULL-safe: order_zipcode co ~86% NULL, "=" thuong se khong khop
    -- 2 gia tri NULL voi nhau nen phai xu ly rieng
    AND (
        loc.order_zipcode = h.order_zipcode
        OR (loc.order_zipcode IS NULL AND h.order_zipcode IS NULL)
    );

-- Kiem tra: so dong insert phai = so order_id duy nhat trong staging
SELECT
    (SELECT COUNT(*) FROM fact_orders)                          AS fact_orders_count,
    (SELECT COUNT(DISTINCT order_id) FROM staging_raw_orders)   AS staging_distinct_orders;
-- Neu 2 so nay lech nhau -> co order bi JOIN mat (thuong do NULL-safe
-- join chua bao phu het truong hop, hoac header khong dong nhat)


-- ============================================================
-- 2. fact_order_items (grain: 1 dong = 1 item, 180519 dong ky vong)
-- ============================================================
INSERT INTO fact_order_items (
    order_item_id, order_id, product_card_id,
    order_item_quantity, order_item_product_price,
    order_item_discount, order_item_discount_rate,
    order_item_profit_ratio, sales, order_item_total,
    order_profit_per_order, benefit_per_order
)
SELECT
    s.order_item_id,
    s.order_id,
    s.product_card_id,
    s.order_item_quantity,
    s.order_item_product_price,
    s.order_item_discount,
    s.order_item_discount_rate,
    s.order_item_profit_ratio,
    s.sales,
    s.order_item_total,
    s.order_profit_per_order,
    s.benefit_per_order
FROM staging_raw_orders s;

-- Kiem tra: so dong phai = tong so dong staging (moi dong CSV = 1 item)
SELECT
    (SELECT COUNT(*) FROM fact_order_items)      AS fact_items_count,
    (SELECT COUNT(*) FROM staging_raw_orders)    AS staging_total_rows;


-- ============================================================
-- 3. VALIDATION TONG QUAT SAU KHI NAP FACT
-- ============================================================

-- Moi order_item phai tro duoc ve 1 order hop le (khong co orphan)
SELECT COUNT(*) AS orphan_items
FROM fact_order_items foi
LEFT JOIN fact_orders fo ON fo.order_id = foi.order_id
WHERE fo.order_id IS NULL;
-- Ky vong = 0

-- Moi order phai tro duoc ve 1 customer va 1 location hop le
SELECT COUNT(*) AS orphan_orders
FROM fact_orders fo
LEFT JOIN dim_customer dc ON dc.customer_id = fo.customer_id
LEFT JOIN dim_order_location dl ON dl.location_id = fo.location_id
WHERE dc.customer_id IS NULL OR dl.location_id IS NULL;
-- Ky vong = 0

-- Doi chieu tong Sales giua staging va fact (phat hien loi lam tron/mat dong)
SELECT
    (SELECT SUM(sales) FROM staging_raw_orders) AS staging_total_sales,
    (SELECT SUM(sales) FROM fact_order_items)   AS fact_total_sales;


-- ============================================================
-- 4. TAO INDEX (chay SAU KHI da nap xong toan bo fact, de insert
--    o buoc tren khong bi cham do phai maintain index song song)
-- ============================================================
CREATE INDEX idx_orders_date       ON fact_orders(order_date);
CREATE INDEX idx_orders_customer   ON fact_orders(customer_id);
CREATE INDEX idx_orders_status     ON fact_orders(order_status);
CREATE INDEX idx_orders_late_risk  ON fact_orders(late_delivery_risk);
CREATE INDEX idx_items_order       ON fact_order_items(order_id);
CREATE INDEX idx_items_product     ON fact_order_items(product_card_id);
CREATE INDEX idx_product_category  ON dim_product(category_id);
