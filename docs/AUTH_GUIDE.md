# Làm auth cho MiniShop, từ database đến API

Các file code của luồng này đã được tạo trong project để anh mở từng file và đọc theo thứ tự. Luồng gồm đăng ký bằng mã 6 số gửi qua SMTP, đăng nhập bằng email/mật khẩu, access token JWT, refresh token ngẫu nhiên có xoay vòng, đăng xuất và lấy thông tin người dùng.

## Bước 1 — Database

Đọc `database/004_auth.sql`. Script bổ sung hai bảng vào schema `minishop` đang có:

- `email_registration_codes`: lưu email, tên, mật khẩu **đã băm**, HMAC của mã, hạn dùng và số lần nhập sai. Chưa tạo `users` ở bước xin mã; chỉ tạo sau khi xác minh thành công.
- `refresh_tokens`: lưu **SHA-256 của refresh token**, người sở hữu, hạn dùng và `family_id`. Token thô chỉ gửi cho client, không lưu trong database.

Database local của dự án này đã được chạy `004_auth.sql` ngày 29/09/2026. Với database khác, chạy **một lần** sau `001_init.sql`:

```powershell
psql -U postgres -d minishop -v ON_ERROR_STOP=1 -f database/004_auth.sql
```

Đừng chạy lại `001_init.sql` trên database đã có bảng. Hiện SQL vẫn quản lý thủ công; trước khi triển khai nhiều môi trường nên đưa các thay đổi tiếp theo vào Flyway và baseline database hiện có.

## Bước 2 — Đọc code theo luồng

1. `dto/request/RegisterRequest.java`, `VerifyEmailRequest.java`, `LoginRequest.java`, `RefreshTokenRequest.java`: dữ liệu client gửi vào và ràng buộc validation.
2. `controller/AuthController.java`: định nghĩa URL, nhận DTO, gọi service, trả `ApiResponse` có `status`, `code`, `message`, `data`.
3. `service/AuthService.java`: nghiệp vụ đăng ký, xác minh, đăng nhập, refresh, logout; transaction bao quanh các thay đổi database.
4. `entity/UserEntity.java`, `EmailRegistrationCodeEntity.java`, `RefreshTokenEntity.java` và các lớp trong `repository/`: ánh xạ và truy vấn PostgreSQL.
5. `service/VerificationEmailService.java`: dùng `JavaMailSender` của `spring-boot-starter-mail` để gửi mã. Không ghi mã vào log.
6. `service/TokenService.java`, `config/JwtConfig.java`, `config/SecurityConfig.java`: phát hành access JWT HS256, kiểm tra Bearer token, tạo refresh token và bảo vệ API.

`service/AuthCleanupJob.java` dọn mã xác minh và refresh token hết hạn mỗi giờ để bảng tạm không tăng mãi.

`/register/request-code`, `/register/verify`, `/login`, `/refresh`, `/logout`, `/password/forgot`, `/password/reset` là API công khai. `/me` cần `Authorization: Bearer <accessToken>`. Response lỗi cũng theo mẫu chung của backend.

Quên mật khẩu cần chạy thêm `database/005_password_reset.sql` một lần. `POST /api/v1/auth/password/forgot` nhận `{"email":"anh@example.com"}`, luôn trả thông báo chung để không lộ email có tài khoản hay chưa. Nếu tài khoản tồn tại, email nhận mã 6 số. `POST /api/v1/auth/password/reset` nhận `{"email":"anh@example.com","code":"123456","newPassword":"MatKhauMoi123!"}`. Mã dùng một lần, hết hạn sau 10 phút và tối đa 5 lần nhập sai. Đặt lại thành công sẽ thu hồi mọi refresh token của tài khoản; access token cũ vẫn có thể dùng đến khi hết hạn tối đa 15 phút.

## Bước 3 — Cấu hình local

`config/auth.properties` đã được tạo với **hai khóa ngẫu nhiên riêng** cho JWT và HMAC mã email. File này và `config/mail.properties` được `.gitignore` bỏ qua. Đừng đưa khóa thật hoặc mật khẩu SMTP vào Git. Trên server triển khai, dùng biến môi trường `APP_AUTH_JWT_SECRET`, `APP_AUTH_OTP_SECRET` và các biến `SPRING_MAIL_*`.

Mở `config/mail.properties` và điền thông tin SMTP do dịch vụ email cấp:

```properties
spring.mail.host=smtp.example.com
spring.mail.port=587
spring.mail.username=YOUR_SMTP_USERNAME
spring.mail.password=YOUR_SMTP_PASSWORD
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
spring.mail.properties.mail.smtp.connectiontimeout=5000
spring.mail.properties.mail.smtp.timeout=5000
spring.mail.properties.mail.smtp.writetimeout=5000
app.mail.from=no-reply@your-verified-domain.com
```

Địa chỉ `app.mail.from` phải được dịch vụ SMTP cho phép. Khi chưa cấu hình mail, server vẫn chạy và `/health` vẫn hoạt động, nhưng API xin mã trả HTTP 503 với thông báo `Dịch vụ email chưa được cấu hình.`. Mẫu không có bí mật nằm ở `config/mail.example.properties`.

Chạy `MinishopServerApplication` bằng IntelliJ với Working directory `D:\project\minishop\minishop-server`, hoặc tại thư mục đó chạy `mvn spring-boot:run` với JDK 21. API local mặc định ở `http://localhost:8080`.

## Bước 4 — Gọi API theo thứ tự

Ví dụ PowerShell. Thay email, tên, mật khẩu bằng dữ liệu thử của anh. Dùng hộp thư thật để nhận mã; không gửi mã cho người khác.

```powershell
$base = 'http://localhost:8080/api/v1/auth'
$register = @{ email='anh@example.com'; fullName='Nguyen Van A'; password='MatKhauManh123!' } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$base/register/request-code" -ContentType 'application/json' -Body $register
```

Response 200 có `data: null` và thông báo chung. Mã 6 số đến email, có hiệu lực 10 phút. Gửi lại cùng email trước 60 giây sẽ không gửi thêm. Nhập sai tối đa 5 lần.

```powershell
$verifyBody = @{ email='anh@example.com'; code='123456' } | ConvertTo-Json
$verified = Invoke-RestMethod -Method Post -Uri "$base/register/verify" -ContentType 'application/json' -Body $verifyBody
$accessToken = $verified.data.accessToken
$refreshToken = $verified.data.refreshToken
```

Thay `123456` bằng mã thực nhận. Xác minh thành công mới tạo dòng trong `minishop.users`; response trả access token (15 phút), refresh token (tối đa 30 ngày), `tokenType: Bearer` và `expiresInSeconds`.

```powershell
$loginBody = @{ email='anh@example.com'; password='MatKhauManh123!' } | ConvertTo-Json
$login = Invoke-RestMethod -Method Post -Uri "$base/login" -ContentType 'application/json' -Body $loginBody
$accessToken = $login.data.accessToken
$refreshToken = $login.data.refreshToken

Invoke-RestMethod -Method Get -Uri "$base/me" -Headers @{ Authorization="Bearer $accessToken" }

$refreshBody = @{ refreshToken=$refreshToken } | ConvertTo-Json
$renewed = Invoke-RestMethod -Method Post -Uri "$base/refresh" -ContentType 'application/json' -Body $refreshBody
$accessToken = $renewed.data.accessToken
$refreshToken = $renewed.data.refreshToken

$logoutBody = @{ refreshToken=$refreshToken } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$base/logout" -ContentType 'application/json' -Body $logoutBody
```

**Mỗi lần refresh phải lưu đè cả hai token mới.** Refresh token cũ bị vô hiệu ngay; dùng lại token cũ sẽ thu hồi cả nhóm token của phiên đó. Logout thu hồi refresh token của phiên. Access JWT đã phát hành vẫn hợp lệ đến khi hết hạn (tối đa 15 phút); nếu cần vô hiệu ngay access token, phải thêm cơ chế tra cứu thu hồi hoặc phiên ở server.

## Bước 5 — Kết nối app React Native

App gửi JSON đến các URL trên. Chỉ gắn `Authorization: Bearer <accessToken>` cho API cần đăng nhập. Khi API trả 401 vì access token hết hạn, gọi `/refresh` **một lần**, lưu cả hai token mới rồi thử lại request. Nếu refresh trả 401, xóa token và đưa người dùng về đăng nhập. Lưu refresh token trong vùng lưu trữ bảo mật của thiết bị; không đưa token vào log hay AsyncStorage thường. `localhost` trên điện thoại là chính điện thoại: emulator Android dùng địa chỉ host dành cho emulator, máy thật dùng IP LAN của máy chạy backend.

## Kiểm tra và giới hạn trước khi public

`mvn test` chạy unit test; luồng register → verify → login → me → refresh → phát hiện replay → logout đã được thử trên PostgreSQL local với SMTP giả, rồi xóa dữ liệu thử. Chưa kiểm tra nhà cung cấp SMTP thật vì chưa có tài khoản/credential của anh.

Trước khi mở API ra Internet, bổ sung rate limit theo IP/email ở gateway hoặc Redis cho xin mã và đăng nhập, giám sát gửi mail, cơ chế quên mật khẩu, HTTPS, quy trình xoay khóa ký và integration test trên PostgreSQL dùng riêng cho test. Các secret local phải được thay bằng secret của môi trường triển khai.
