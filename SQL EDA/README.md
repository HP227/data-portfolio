# DataCo Supply Chain — SQL Server Data Warehouse & Insight

Dự án xây dựng data warehouse dạng star schema từ bộ dữ liệu **DataCoSupplyChainDataset.csv** trên SQL Server, phục vụ phân tích Financial, Shipping/Logistics và Customer Segmentation (kết quả có thể trực quan hóa tiếp trên Power BI).

## Nguồn dữ liệu
- File: `DataCoSupplyChainDataset.csv`
- Quy mô: 180,519 dòng (order item), 65,752 order duy nhất

## Kiến trúc

```
CSV --> staging_raw_orders --> validate --> dim_* / fact_* (star schema) --> query insight
```

- **Dimension tables:** `dim_department`, `dim_category`, `dim_product`, `dim_customer`, `dim_order_location`
- **Fact tables:**
  - `fact_orders` — grain: 1 dòng / 1 order
  - `fact_order_items` — grain: 1 dòng / 1 line item

## Thứ tự chạy file (bắt buộc)

| # | File | Mục đích |
|---|------|----------|
| 00 | `00_staging.sql` | Tạo DB, tạo bảng staging, BULK INSERT CSV, kiểm tra sơ bộ sau load |
| 01 | `01_SQL_tiền_xử_lý_dữ_liệu_ban_đầu.sql` | Validate dữ liệu staging: NULL, inconsistency theo order, outlier, phân bố các cột phân loại |
| 02 | `02_schema.sql` | Tạo schema đích (dimension + fact tables), khai báo PK/FK |
| 03 | `03_dimension_etl.sql` | ETL nạp dimension theo thứ tự `department → category → product`, sau đó `customer`, `order_location` (độc lập) |
| 04 | `04_fact_etl.sql` | ETL nạp `fact_orders` trước, `fact_order_items` sau; validate orphan/đối chiếu tổng; tạo index sau cùng |
| 05 | `05_Query_insight.sql` | Các câu query insight: doanh thu, tăng trưởng MoM, top sản phẩm, ảnh hưởng discount, AOV, tỷ lệ trễ giao hàng, tỷ lệ hủy, phân khúc khách hàng, tỷ lệ mua lại |

Chạy tuần tự đúng thứ tự 00 → 05 vì có ràng buộc khóa ngoại (dimension phải có trước fact) và các bước validate ở giữa giúp phát hiện lỗi dữ liệu sớm trước khi build ETL.

## Cách chạy
1. Sửa đường dẫn CSV thực tế trong `00_staging.sql` (mục `BULK INSERT ... FROM`).
2. Chạy lần lượt từng file theo thứ tự bảng trên bằng SSMS (hoặc Azure Data Studio).
3. Sau mỗi bước ETL, kiểm tra các câu SELECT validation đi kèm (kỳ vọng = 0 dòng lệch/orphan).
4. Chạy `05_Query_insight.sql` để lấy kết quả phân tích, hoặc kết nối SQL Server này làm nguồn cho Power BI.

## Lưu ý dữ liệu quan trọng
- `order_zipcode` thiếu (~86% NULL) → các JOIN liên quan đến `dim_order_location` đều xử lý NULL-safe.
- Hai cột `benefit_per_order` và `order_profit_per_order` trong dataset gốc **lặp lại theo order** (không phải theo item). Khi cần tổng lợi nhuận theo order, phải `SELECT DISTINCT order_id, ...` trước khi `SUM`, tránh nhân đôi số item.
- Các query loại trừ `CANCELED` / `SUSPECTED_FRAUD` khi tính doanh thu/AOV/phân khúc khách hàng — cần áp dụng nhất quán cho mọi query đo hiệu suất kinh doanh.

## Known issues / TODO
- [ ] `dim_customer.login_type`: cột chưa được ETL populate, hiện luôn NULL — cân nhắc bỏ hoặc bổ sung nguồn dữ liệu.
- [ ] Query "Top N sản phẩm bán chạy nhất" trong `05_Query_insight.sql` thiếu JOIN `fact_orders` trước khi filter `order_status` — cần bổ sung JOIN.
- [ ] Rà soát lại tất cả query insight để đảm bảo tiêu chí loại trừ đơn hủy/gian lận nhất quán.
