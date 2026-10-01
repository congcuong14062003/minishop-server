-- Apply once to an existing MiniShop database after 001_init.sql.
BEGIN;

CREATE TABLE minishop.email_registration_codes (
    email TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    code_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL,
    failed_attempts INTEGER NOT NULL DEFAULT 0 CHECK (failed_attempts >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX email_registration_codes_expires_idx
    ON minishop.email_registration_codes (expires_at);

CREATE TABLE minishop.refresh_tokens (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES minishop.users(id) ON DELETE CASCADE,
    family_id UUID NOT NULL,
    token_hash TEXT NOT NULL UNIQUE CHECK (length(token_hash) = 64),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX refresh_tokens_user_idx ON minishop.refresh_tokens (user_id);
CREATE INDEX refresh_tokens_family_idx ON minishop.refresh_tokens (family_id);
CREATE INDEX refresh_tokens_expires_idx ON minishop.refresh_tokens (expires_at);

COMMENT ON TABLE minishop.email_registration_codes IS 'Mã xác minh email tạm thời trước khi tạo tài khoản.';
COMMENT ON COLUMN minishop.email_registration_codes.email IS 'Email đã chuẩn hóa chữ thường; chỉ lưu đến khi xác minh hoặc hết hạn.';
COMMENT ON COLUMN minishop.email_registration_codes.full_name IS 'Tên người dùng sẽ tạo sau khi xác minh.';
COMMENT ON COLUMN minishop.email_registration_codes.password_hash IS 'Mật khẩu đã băm bằng BCrypt; không lưu mật khẩu gốc.';
COMMENT ON COLUMN minishop.email_registration_codes.code_hash IS 'HMAC của mã xác minh, không lưu mã thô.';
COMMENT ON COLUMN minishop.email_registration_codes.expires_at IS 'Hạn dùng mã xác minh.';
COMMENT ON COLUMN minishop.email_registration_codes.sent_at IS 'Thời điểm gửi gần nhất để giới hạn gửi lại.';
COMMENT ON COLUMN minishop.email_registration_codes.failed_attempts IS 'Số lần nhập sai để chặn thử mã liên tục.';
COMMENT ON COLUMN minishop.email_registration_codes.created_at IS 'Thời điểm tạo yêu cầu xác minh.';
COMMENT ON TABLE minishop.refresh_tokens IS 'Refresh token ngẫu nhiên; chỉ lưu SHA-256 để hạn chế rò rỉ.';
COMMENT ON COLUMN minishop.refresh_tokens.id IS 'Mã bản ghi refresh token.';
COMMENT ON COLUMN minishop.refresh_tokens.user_id IS 'Người dùng sở hữu phiên đăng nhập.';
COMMENT ON COLUMN minishop.refresh_tokens.family_id IS 'Nhóm token cùng một phiên để phát hiện dùng lại token đã xoay vòng.';
COMMENT ON COLUMN minishop.refresh_tokens.token_hash IS 'SHA-256 dạng hex của refresh token.';
COMMENT ON COLUMN minishop.refresh_tokens.expires_at IS 'Hạn tuyệt đối của phiên.';
COMMENT ON COLUMN minishop.refresh_tokens.revoked_at IS 'Thời điểm token bị thu hồi hoặc xoay vòng.';
COMMENT ON COLUMN minishop.refresh_tokens.created_at IS 'Thời điểm phát hành token.';

COMMIT;
