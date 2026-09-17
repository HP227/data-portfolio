SELECT top 5 *
FROM fact_order_items
SELECT top 5 *
FROM fact_orders
SELECT top 5 *
FROM dim_category
SELECT top 5 *
FROM dim_product
SELECT top 5 *
FROM dim_customer
SELECT top 5 *
FROM dim_order_location
--1. Financial & Profitability
-- Doanh thu theo thời gian tháng/năm   
SELECT YEAR(o.order_date) as year_, MONTH(o.order_date) as month_, 
		FORMAT(SUM(oi.sales), 'N2') as Total_Sale
FROM fact_order_items oi
INNER JOIN fact_orders o ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD')
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY year_, month_

-- Tăng trưởng MoM/YoY (% thay đổi so với kỳ trước)
WITH monthly AS (
	SELECT YEAR(o.order_date) as year_, MONTH(o.order_date) as month_, 
			SUM(oi.sales) as Total_Sale
	FROM fact_order_items oi
	INNER JOIN fact_orders o ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD')
	GROUP BY YEAR(o.order_date), MONTH(o.order_date)
	)
SELECT *, 
	LAG(Total_Sale) OVER (ORDER BY year_, month_) AS prev_month_sales,
	CAST((Total_sale - LAG(Total_Sale) OVER (ORDER BY year_, month_)) * 100.0 / NULLIF(LAG(Total_Sale) OVER (ORDER BY year_, month_), 0) AS DECIMAL(10,2)) AS growth_pct
FROM monthly
 /*`LAG()` = lấy giá trị dòng liền x, NULLIFF: để tránh lỗi chia cho 0 khi tháng trước = 0. */

-- Top N sản phẩm/category bán chạy nhất

SELECT TOP (10) dp.product_name, 
    CAST(SUM(oi.sales) AS DECIMAL(10,2)) AS total_sales
FROM fact_order_items oi
JOIN fact_orders o ON o.order_id = oi.order_id
JOIN dim_product dp ON dp.product_card_id = oi.product_card_id
WHERE o.order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD')
GROUP BY dp.product_name

-- Discount ảnh hưởng Profit - chia nhóm discount để so sánh
SELECT
    CASE
        WHEN order_item_discount_rate = 0 THEN '0%'
        WHEN order_item_discount_rate <= 0.1 THEN '1-10%'
        WHEN order_item_discount_rate <= 0.2 THEN '11-20%'
        ELSE '20%+'
    END AS discount_bucket,
    AVG(order_item_profit_ratio) AS avg_profit_ratio,
    COUNT(*) AS num_items
FROM fact_order_items
GROUP BY
    CASE
        WHEN order_item_discount_rate = 0 THEN '0%'
        WHEN order_item_discount_rate <= 0.1 THEN '1-10%'
        WHEN order_item_discount_rate <= 0.2 THEN '11-20%'
        ELSE '20%+'
    END;

-- Average order value
WITH order_level AS (
    SELECT 
        oi.order_id, 
        SUM(oi.sales) AS order_sales
    FROM fact_order_items oi
    JOIN fact_orders o ON oi.order_id = o.order_id 
    WHERE o.order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD') 
    GROUP BY oi.order_id
)
SELECT CAST(AVG(order_sales) AS DECIMAL(10,2)) AS aov
FROM order_level;

-- 2. Shipping & Logistics
-- Tỷ lệ trễ giao hàng (%) theo shipping mode 
	--late_delivery_risk (0/1) 
SELECT shipping_mode,
	AVG(CAST(late_delivery_risk AS DECIMAL(10,2)))*100 AS pct_late_delivery
FROM fact_orders
GROUP BY shipping_mode

-- Khu vực nào giao trễ nhiều nhất city/country
SELECT lo.location_id, lo.order_city, lo.order_country,
	AVG(CAST(late_delivery_risk AS DECIMAL(10,2)))*100 AS pct_late_delivery
FROM fact_orders o
INNER JOIN dim_order_location lo ON o.location_id = lo.location_id
GROUP BY lo.location_id, lo.order_city, lo.order_country
ORDER BY pct_late_delivery DESC

-- Tỷ lệ hoàn hủy CANCELED nhóm hàng
SELECT dc.category_name,
       COUNT(*) AS total_items,
       SUM(CASE WHEN fo.order_status IN ('CANCELED','SUSPECTED_FRAUD') THEN 1 ELSE 0 END) AS canceled_items,
       CAST(SUM(CASE WHEN fo.order_status IN ('CANCELED','SUSPECTED_FRAUD') THEN 1 ELSE 0 END) * 100.0 
            / COUNT(*) AS DECIMAL(10,2)) AS pct_canceled
FROM fact_order_items foi
JOIN fact_orders fo ON fo.order_id = foi.order_id
JOIN dim_product dp ON dp.product_card_id = foi.product_card_id
JOIN dim_category dc ON dc.category_id = dp.category_id
GROUP BY dc.category_name
ORDER BY pct_canceled DESC

-- 3.Customer Segmentation
-- Phân nhóm khách hàng có dòng tiền cao/ổn định
WITH customer_segment AS (
    SELECT 
        o.customer_id, 
        SUM(oi.sales) AS total_spend
    FROM fact_order_items oi 
    INNER JOIN fact_orders o ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD') -- Thêm dòng này
    GROUP BY o.customer_id
)
SELECT customer_id, total_spend,
    CASE 
        WHEN total_spend < 1000 THEN 'standard'
        WHEN total_spend BETWEEN 1000 AND 2000 THEN 'premium'
        ELSE 'VIP'
    END AS customer_type
FROM customer_segment;

-- Tỷ lệ khách mua lại
SELECT
    CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
    COUNT(*) AS num_customers
FROM (
    SELECT customer_id, COUNT(DISTINCT order_id) AS order_count
    FROM fact_orders
    GROUP BY customer_id
) t
GROUP BY CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-time' END





