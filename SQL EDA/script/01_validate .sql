-- ============================================================
-- CHECKLIST DATA VALIDATION (PHASE STAGING)
-- ============================================================

-- 1. KIEM TRA QUY MO & NULL RUI RO
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)      AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)   AS null_customer_id,
    SUM(CASE WHEN order_date_raw IS NULL THEN 1 ELSE 0 END)    AS null_order_date,
    SUM(CASE WHEN shipping_date_raw IS NULL THEN 1 ELSE 0 END) AS null_shipping_date
FROM dbo.staging_raw_orders;
GO

-- 2. KIEM TRA BAT DONG BO THONG TIN CAP ORDER (INCONSISTENCY)
-- (Mot Order Id khong duoc phep chua nhieu hon 1 Status/Shipping Mode)
SELECT 
    Order_Id, 
    COUNT(DISTINCT order_status) AS status_count,
    COUNT(DISTINCT Shipping_Mode) AS shipping_mode_count
FROM dbo.staging_raw_orders
GROUP BY Order_Id
HAVING 
    COUNT(DISTINCT order_status) > 1
    OR COUNT(DISTINCT Shipping_Mode) > 1;
GO

-- 3. KIEM TRA LOI LOGIC VA DAI GIA TRI (OUTLIERS)
SELECT
    -- Loi logic ngay: Shipping_Date < Order_Date
    SUM(CASE WHEN Days_for_shipping_real < 0 THEN 1 ELSE 0 END)   AS invalid_negative_date,
    -- Kiem tra nhi phan late_delivery_risk
    SUM(CASE WHEN late_delivery_risk NOT IN (0,1) 
              OR late_delivery_risk IS NULL THEN 1 ELSE 0 END)    AS invalid_risk_flag
FROM dbo.staging_raw_orders;
GO

-- 4. KIEM TRA DANH MUC PHAN LOAI (DISTINCT CATEGORIES) -> phuc vu truy van

-- Kiem tra cac gia tri cua Order Status
SELECT order_status, COUNT(*) AS record_count
FROM dbo.staging_raw_orders
GROUP BY order_status
ORDER BY record_count DESC;
GO

-- Kiem tra cac gia tri cua Delivery Status
SELECT Delivery_Status, COUNT(*) AS record_count
FROM dbo.staging_raw_orders
GROUP BY Delivery_Status
ORDER BY record_count DESC;
GO

-- Kiem tra cac gia tri cua Shipping Mode
SELECT Shipping_Mode, COUNT(*) AS record_count
FROM dbo.staging_raw_orders
GROUP BY Shipping_Mode
ORDER BY record_count DESC;
GO

-- Kiem tra cac gia tri cua Customer_Segment
SELECT DISTINCT Customer_Segment
FROM dbo.staging_raw_orders
GO
