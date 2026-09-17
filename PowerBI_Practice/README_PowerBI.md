# README — Power BI Dashboard: DataCo Supply Chain

Dashboard phân tích chuỗi cung ứng, xây dựng trên dữ liệu đã qua ETL từ
`DataCoSupplyChainDataset.csv` vào SQL Server (star schema — xem
`README.md` ở phần SQL để biết chi tiết pipeline).

## 1. Nguồn dữ liệu & Mô hình dữ liệu

- **Kết nối:** SQL Server (Import mode), lấy từ 7 bảng: `fact_orders`,
  `fact_order_items`, `dim_customer`, `dim_product`, `dim_category`,
  `dim_department`, `dim_order_location`.
- **Bảng bổ sung tạo trong Power BI (không có ở SQL):**
  - `DimDate` — bảng ngày tháng riêng, đánh dấu Mark as Date Table, phục vụ
    time-intelligence (YoY, MoM).
  - `CustomerRFM` — bảng tính Recency/Frequency/Monetary theo từng khách
    hàng, dùng mốc snapshot = ngày lớn nhất trong `fact_orders[order_date]`
- **Quan hệ:** toàn bộ theo star schema, hướng lọc 1 chiều từ dimension
  sang fact, đúng theo sơ đồ FK đã thiết kế ở SQL.

## 2. Cấu trúc Dashboard

| Trang | Nội dung chính | Insight nổi bật nhất |
|---|---|---|
| **Revenue & Profit** | KPI tổng, Doanh thu theo tháng/YoY, Top sản phẩm, Profit Margin theo category | Xem lưu ý ở mục 4 |
| **Shipping & Logistics** | Tỷ lệ trễ theo Shipping Mode/khu vực, Cancel Rate theo category | **First Class trễ 95.27% vs Standard 38.13%** — insight actionable nhất dashboard |
| **Customer Segmentation** | RFM (Champions/At Risk/New/Lost), Repeat vs One-time, Segment theo Consumer/Corporate/Home Office | **At Risk: 41% khách hàng nhưng chiếm ~70% doanh thu** — cần chiến dịch win-back ngay |

## 3. Danh sách Measures (DAX) chính

| Measure | Công thức tóm tắt |
|---|---|
| `Total Sales` | `SUM(fact_order_items[sales])` |
| `Total Orders` | `DISTINCTCOUNT(fact_orders[order_id])` | 
| `AOV` | `DIVIDE([Total Sales],[Total Orders])` |
| `Sales YoY %` | `SAMEPERIODLASTYEAR` trên `DimDate` |
| `Late Delivery Rate` | `AVERAGE(fact_orders[late_delivery_risk])` |
| `Cancel Rate` | Tỷ lệ item có `order_status` = CANCELED/SUSPECTED_FRAUD |
| `Total Profit` / `Profit Margin %` | `SUM(benefit_per_order)` / chia `Total Sales` |
| `Repeat Customer Rate` | % khách có `Frequency > 1` |

## 4. ⚠️ Giới hạn dữ liệu quan trọng — đọc trước khi diễn giải số liệu

**a) 4 tháng cuối dataset (10/2017 – 01/2018) có cấu trúc dữ liệu khác biệt bất thường.**
Từ tháng 11/2017, mỗi đơn hàng luôn chỉ có đúng 1 item với số lượng = 1
(so với trung bình ~2.7 item/đơn, số lượng ~2.2 ở toàn bộ giai đoạn trước
đó). Điều này khiến `Sales`/`AOV` giai đoạn này giảm mạnh, kéo `Sales YoY %`
sụt về gần -100% — **đây là hiện tượng do cấu trúc sinh dữ liệu thay đổi ở
đuôi dataset, không phản ánh doanh nghiệp sụt giảm thật**. Không dùng đoạn
này để kết luận xu hướng kinh doanh.

**b) `Customer Segment` (Consumer/Corporate/Home Office) không phân hoá hành vi thật.**
AOV, tỷ lệ trễ giao hàng, shipping mode ưa chuộng, category mua nhiều nhất
gần như giống hệt nhau giữa 3 segment — segment chỉ phản ánh **tỷ trọng quy
mô** (~52/30/18%), không phải đặc điểm hành vi khác biệt. → Ưu tiên dùng
**RFM** (tính từ hành vi mua thật) làm căn cứ chiến dịch marketing, không
dùng nhãn Segment có sẵn.

## 5. Cách cập nhật dữ liệu (Refresh)

1. Đảm bảo pipeline SQL (`00` → `04`) đã chạy xong, dữ liệu mới đã nạp vào
   `fact_orders`/`fact_order_items`.
2. Trong Power BI Desktop: **Home → Refresh**.
3. Nếu đổi cấu trúc bảng SQL (thêm/xoá cột), vào **Transform data** để cập
   nhật lại query, sau đó kiểm tra lại toàn bộ Measures/Relationships có bị
   gãy không trước khi publish.
