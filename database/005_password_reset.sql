BEGIN;

CREATE TABLE minishop.password_reset_codes (
    email TEXT PRIMARY KEY,
    code_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL,
    failed_attempts INTEGER NOT NULL DEFAULT 0 CHECK (failed_attempts >= 0)
);
CREATE INDEX password_reset_codes_expires_idx ON minishop.password_reset_codes (expires_at);

COMMENT ON TABLE minishop.password_reset_codes IS 'Mã khôi phục mật khẩu gửi qua email, xóa sau khi sử dụng hoặc hết hạn.';
COMMENT ON COLUMN minishop.password_reset_codes.email IS 'Email tài khoản đã chuẩn hóa chữ thường.';
COMMENT ON COLUMN minishop.password_reset_codes.code_hash IS 'HMAC của mã khôi phục, không lưu mã gốc.';
COMMENT ON COLUMN minishop.password_reset_codes.expires_at IS 'Thời điểm mã hết hiệu lực.';
COMMENT ON COLUMN minishop.password_reset_codes.sent_at IS 'Thời điểm gửi gần nhất để giới hạn gửi lại.';
COMMENT ON COLUMN minishop.password_reset_codes.failed_attempts IS 'Số lần nhập sai mã.';

COMMIT;
