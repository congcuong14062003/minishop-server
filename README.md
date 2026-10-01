# MiniShop backend

Spring Boot 4, Java 21, Maven, PostgreSQL. Backend có API health, luồng auth email/password với access token + refresh token và đăng nhập CMS cho tài khoản `ADMIN`. Xem [hướng dẫn auth](docs/AUTH_GUIDE.md) để cấu hình SMTP và gọi từng API.

## Cấu trúc

```text
src/main/java/com/minishop/server/
├── MinishopServerApplication.java   # Điểm khởi động
├── common/
│   ├── api/ApiResponse.java         # Envelope status/code/message/data
│   └── exception/                   # Business exception và xử lý lỗi chung
├── config/                           # Security và JWT
├── controller/                       # HealthController, AuthController...
├── service/                          # HealthService, AuthService, TokenService...
├── dto/
│   ├── request/                      # DTO đầu vào
│   └── response/                     # DTO đầu ra
├── entity/                            # JPA entity
├── repository/                        # Spring Data repository
├── mapper/                            # Chuyển entity ↔ DTO
└── security/                          # Hash token và mã email
src/main/resources/application.yml   # Cấu hình, không chứa mật khẩu thật
src/test/java/                      # Unit test
database/                           # SQL đã thiết kế, chạy thủ công
config/database.properties           # Cấu hình DB local, Git bỏ qua
```

Cấu trúc này chia theo tầng: `controller` chứa tất cả controller (`AuthController`, `ProductController`...), `service` chứa các service tương ứng, `repository` chứa truy cập dữ liệu. DTO của từng API được đặt theo tên rõ ràng trong `dto/request` và `dto/response`. Các package chưa có lớp nghiệp vụ dùng `package-info.java` để IntelliJ và Git nhận ra thư mục. `common` chỉ chứa mã dùng chung.

## Chạy local

1. Chọn JDK 21 cho Project SDK và Maven Runner trong IntelliJ.
2. PostgreSQL cần có database `minishop` và schema `minishop`. Nếu đã chạy `001_init.sql` trước đó, **không chạy lại**. Xem `database/README.md`.
3. Mở file `config/database.properties` và điền mật khẩu PostgreSQL vào `spring.datasource.password=`. File này được Git bỏ qua và Spring Boot nạp khi chạy từ thư mục `minishop-server`. `config/database.example.properties` là bản mẫu để chia sẻ.
4. Mở PowerShell tại `minishop-server`, chọn Java 21 và chạy:

```powershell
$env:JAVA_HOME = 'C:\Users\cuongkoi\.jdks\ms-21.0.12.1'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
.\mvnw.cmd spring-boot:run
```

Không commit mật khẩu. Nếu chạy từ IntelliJ, đặt **Working directory** của Run Configuration là `minishop-server` để Spring đọc đúng file trong `config/`. Ở môi trường triển khai, dùng các biến chuẩn `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD` thay vì file local; biến môi trường ghi đè cấu hình file. Có thể đổi cổng bằng `PORT`. JPA chỉ **validate** schema, không tự tạo/sửa bảng.

## Kiểm tra API

```powershell
Invoke-RestMethod http://localhost:8080/api/v1/health
Invoke-RestMethod http://localhost:8080/actuator/health
```

Khi khởi động thành công, log có dòng `MiniShop API (local): http://localhost:8080` và URL health. Domain public chỉ xác định được sau khi cấu hình domain/reverse proxy ở môi trường triển khai.

`/api/v1/health` trả HTTP 200 khi DB sẵn sàng:

```json
{"status":200,"code":200,"message":"Thành công.","data":{"service":"UP","database":"UP"}}
```

Khi DB lỗi, endpoint này trả HTTP 503 với `data.database = "DOWN"`. `/actuator/health` là endpoint chuẩn của Spring Boot, có định dạng riêng. Các API auth được mô tả trong [docs/AUTH_GUIDE.md](docs/AUTH_GUIDE.md).

CMS đăng nhập bằng `POST /api/v1/auth/admin/login` với JSON `{ "email": "...", "password": "..." }`. Tài khoản cần có vai trò `ADMIN` trong `minishop.user_roles`; tài khoản khách hàng bị từ chối. Gửi access token trong `Authorization: Bearer ...` khi gọi `GET /api/v1/admin/me` và các API tương lai dưới `/api/v1/admin/**`. Backend đọc quyền và trạng thái tài khoản từ database cho mỗi request quản trị, nên thu hồi `ADMIN` hoặc khóa tài khoản có hiệu lực ngay. Cách cấp quyền admin đầu tiên nằm trong [database/README.md](database/README.md); không cấp admin qua API đăng ký công khai.

## Log API khi chạy production

Mỗi request dưới `/api/` ghi một dòng gồm HTTP method, đường dẫn, status và thời gian xử lý (`durationMs`). Backend tự sinh `requestId` cho từng request, trả trong header `X-Request-Id` và gắn ID này vào log phát sinh trong cùng request. Khi báo lỗi, lấy `X-Request-Id` ở response để tìm đúng dòng log. Dòng access log này không ghi query string, request body hoặc header Authorization; không đặt mật khẩu, token hay mã xác minh trong đường dẫn URL.

Chạy với profile `prod` để log console ở định dạng JSON (Logstash), thuận tiện tìm kiếm trên hệ thống thu thập log. Để host lưu log ra file, có thể đặt thêm biến môi trường `LOGGING_FILE_NAME=logs/minishop-server.log`; file cũng dùng JSON. Nếu chạy trong container, thu thập stdout bằng hệ thống log của host/container. Ví dụ:

```powershell
$env:SPRING_PROFILES_ACTIVE = 'prod'
$env:LOGGING_FILE_NAME = 'logs/minishop-server.log' # tùy chọn
.\mvnw.cmd spring-boot:run
```

Trong IntelliJ, xem log ở cửa sổ **Run**. Nếu bật file log, có thể theo dõi và tìm request bằng PowerShell:

```powershell
Get-Content .\logs\minishop-server.log -Tail 100 -Wait
Select-String -Path .\logs\minishop-server.log -Pattern '<requestId trong response>'
```

Request bị từ chối bởi Spring Security (401/403) vẫn có log. Khi có lỗi 500, `GlobalExceptionHandler` ghi stack trace cùng `requestId` để đối chiếu. Cần giới hạn người được đọc log và cấu hình lưu giữ/xoay vòng theo môi trường triển khai. Không gửi mật khẩu hoặc token khi báo lỗi; chỉ cần `requestId`, thời điểm và URL API.

## Kiểm tra build

```powershell
.\mvnw.cmd test
```

File SQL trong `database/` là bản thiết kế hiện tại, **chưa** được Spring tự động chạy. Khi bắt đầu quản lý migration, cần baseline schema đang có trước khi đưa vào Flyway để tránh chạy lại `CREATE TABLE`.
