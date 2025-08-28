📌 Yêu Cầu Chi Tiết – Hệ Thống Đặt Hotel Cho Khách Du Lịch
I. Công Nghệ

Backend: Node.js (Express/NestJS), RESTful API

Database: MongoDB (Mongoose)

Frontend:

Mobile App (Khách + Chủ Hotel) → Kết nối API khách hàng & chủ hotel

Web React (Admin) → Kết nối API quản trị

Tích hợp:

Thanh toán: VNPAY (VN) + Stripe (quốc tế)

Xác minh OTP Gmail (Google SMTP hoặc dịch vụ mail server)

Chatbot: Gemini API

II. Tính Năng Chi Tiết
1. Khách (Người dùng App)
1.1. Xác thực & Tài khoản

Đăng ký tài khoản (email + mật khẩu, xác minh OTP Gmail)

Đăng nhập (JWT Token, refresh token)

Đa ngôn ngữ: Tiếng Việt / English (config đa ngôn ngữ ở client, backend trả dữ liệu gốc)

1.2. Khám phá khách sạn

Danh sách khách sạn (phân loại theo 3 sao – 5 sao)

Tìm kiếm theo tên, vị trí, giá, loại phòng, dịch vụ

Chi tiết khách sạn:

Hình ảnh

Mô tả

Loại phòng (standard, deluxe, suite, …)

Giá

Chính sách huỷ

Dịch vụ đi kèm

1.3. Danh sách yêu thích

Thêm/Xóa phòng/khách sạn vào “Yêu thích”

1.4. Đặt phòng

Chọn loại phòng, số lượng, ngày check-in/check-out

Đặt phòng bắt buộc thanh toán trước (VNPAY/Stripe)

Xác nhận thành công → Gửi email thông báo (Gmail API/SMTP)

1.5. Lịch sử đặt phòng

Xem danh sách booking

Trạng thái: Đang chờ, Đã xác nhận, Đã hủy, Đã thanh toán

1.6. Chatbot hỗ trợ

Tích hợp Gemini (trả lời gợi ý khách sạn theo dữ liệu hệ thống)

1.7. Đánh giá & Review

Người dùng có thể:

Đánh giá (1–5 sao)

Viết bình luận kèm hình ảnh

Hiển thị review trung bình cho khách sạn

1.8. Xếp hạng thành viên

Hạng Bạc, Vàng, Kim Cương (dựa trên tổng số tiền đặt phòng)

Kim Cương giảm 5% trên tổng hóa đơn

2. Chủ Khách Sạn (Người dùng App)
2.1. Quản lý hồ sơ khách sạn

Đăng ký khách sạn (thông tin cơ bản, giấy phép kinh doanh, CMND/CCCD)

Duyệt khách sạn (admin duyệt trước khi public)

2.2. Quản lý phòng

CRUD phòng (thêm, sửa, xóa)

Upload hình ảnh, mô tả, giá, tiện ích

2.3. Quản lý đặt phòng

Xem danh sách khách đặt phòng

Trạng thái: chờ xác nhận, đã đặt, đã hủy

Chủ hotel có thể xác nhận/huỷ booking

2.4. Quản lý lịch & số lượng phòng

Quản lý số lượng phòng trống theo ngày

Cập nhật tình trạng “còn phòng/hết phòng”

2.5. Doanh thu & báo cáo

Thống kê số lượng đặt phòng theo tháng/quý

Báo cáo doanh thu

2.6. Hỗ trợ khách hàng

Trả lời tin nhắn khách (chat nội bộ trong app)

3. Admin (Web React)
3.1. Quản trị người dùng

CRUD user (khách + chủ hotel)

Phân quyền (khách / chủ hotel / admin)

3.2. Quản trị khách sạn

Duyệt khách sạn đăng ký

Quản lý danh sách khách sạn (CRUD)

3.3. Quản trị phòng

CRUD tất cả phòng trên hệ thống

3.4. Quản trị đặt phòng

Xem thống kê booking toàn hệ thống

Quản lý trạng thái đặt phòng

3.5. Báo cáo & Thống kê

Tổng số khách sạn, phòng, booking

Doanh thu theo tháng/quý/năm

Thống kê hạng thành viên

3.6. Quản lý nội dung

CRUD review, đánh giá

Quản lý chatbot (import dữ liệu khách sạn vào Gemini)