# MiniShop backend

Spring Boot 4, Java 21, Maven, PostgreSQL. Đây là base API cho MiniShop; chưa có chức năng đăng ký/đăng nhập hay JWT.

## Cấu trúc

```text
src/main/java/com/minishop/server/
├── MinishopServerApplication.java   # Điểm khởi động
├── common/
│   ├── api/ApiResponse.java         # Envelope status/code/message/data
│   └── exception/                   # Business exception và xử lý lỗi chung
├── config/SecurityConfig.java       # Quy tắc truy cập API
└── health/                            # Ví dụ module theo tính năng
    ├── HealthController.java
    └── HealthService.java
src/main/resources/application.yml   # Cấu hình, không chứa mật khẩu thật
src/test/java/                      # Unit test
database/                           # SQL đã thiết kế, chạy thủ công
```

Khi thêm tính năng, tạo package cùng cấp `health` như `auth`, `product`, `cart`. Trong từng package chỉ tạo các lớp thực sự dùng (`Controller`, `Service`, `Repository`, `Entity`, `dto`); không cần tạo hàng loạt thư mục rỗng. `common` dành cho mã dùng chung, không chứa logic nghiệp vụ.

## Chạy local

1. Chọn JDK 21 cho Project SDK và Maven Runner trong IntelliJ.
2. PostgreSQL cần có database `minishop` và schema `minishop`. Nếu đã chạy `001_init.sql` trước đó, **không chạy lại**. Xem `database/README.md`.
3. Mở PowerShell tại `minishop-server`, cung cấp mật khẩu bằng biến môi trường của phiên terminal:

```powershell
$env:JAVA_HOME = 'C:\Users\cuongkoi\.jdks\ms-21.0.12.1'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
$env:DB_PASSWORD = 'MAT_KHAU_POSTGRES_CUA_ANH'
.\mvnw.cmd spring-boot:run
```

Không commit mật khẩu. Có thể đổi `DB_URL`, `DB_USER`, `PORT` bằng biến môi trường. Nếu chạy từ IntelliJ, thêm `DB_PASSWORD` vào Environment variables của Run Configuration. URL mặc định là `jdbc:postgresql://localhost:5432/minishop?currentSchema=minishop`. JPA chỉ **validate** schema, không tự tạo/sửa bảng.

## Kiểm tra API

```powershell
Invoke-RestMethod http://localhost:8080/api/v1/health
Invoke-RestMethod http://localhost:8080/actuator/health
```

`/api/v1/health` trả HTTP 200 khi DB sẵn sàng:

```json
{"status":200,"code":200,"message":"Thành công.","data":{"service":"UP","database":"UP"}}
```

Khi DB lỗi, endpoint này trả HTTP 503 với `data.database = "DOWN"`. `/actuator/health` là endpoint chuẩn của Spring Boot, có định dạng riêng. Các API khác bị chặn mặc định cho đến khi làm auth. `SecurityConfig` phải được cập nhật khi có endpoint công khai và xác thực token; hiện chưa phải luồng đăng nhập hoàn chỉnh.

## Kiểm tra build

```powershell
.\mvnw.cmd test
```

File SQL trong `database/` là bản thiết kế hiện tại, **chưa** được Spring tự động chạy. Khi bắt đầu quản lý migration, cần baseline schema đang có trước khi đưa vào Flyway để tránh chạy lại `CREATE TABLE`.
