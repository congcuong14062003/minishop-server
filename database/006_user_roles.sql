-- Apply once after 005_password_reset.sql on an existing MiniShop database.
-- Keep users as the single identity table; roles are assigned separately.
BEGIN;

CREATE TABLE minishop.roles (
    code TEXT PRIMARY KEY CHECK (code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
    name TEXT NOT NULL CHECK (length(btrim(name)) > 0),
    description TEXT NOT NULL DEFAULT ''
);

CREATE TABLE minishop.user_roles (
    user_id UUID NOT NULL REFERENCES minishop.users(id) ON DELETE CASCADE,
    role_code TEXT NOT NULL REFERENCES minishop.roles(code) ON UPDATE CASCADE ON DELETE RESTRICT,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    granted_by UUID REFERENCES minishop.users(id) ON DELETE SET NULL,
    PRIMARY KEY (user_id, role_code)
);
CREATE INDEX user_roles_role_user_idx ON minishop.user_roles (role_code, user_id);

INSERT INTO minishop.roles (code, name, description) VALUES
    ('CUSTOMER', 'Khách hàng', 'Mua hàng và quản lý thông tin cá nhân.'),
    ('STAFF', 'Nhân viên', 'Thực hiện các nghiệp vụ được cấp trong CMS.'),
    ('ADMIN', 'Quản trị viên', 'Quản lý toàn bộ cửa hàng và phân quyền nhân viên.');

-- Existing accounts retain their identity and receive only the baseline role.
INSERT INTO minishop.user_roles (user_id, role_code)
SELECT id, 'CUSTOMER' FROM minishop.users;

-- Future email, phone and OAuth registrations all start as CUSTOMER.
CREATE FUNCTION minishop.assign_default_customer_role() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO minishop.user_roles (user_id, role_code)
    VALUES (NEW.id, 'CUSTOMER');
    RETURN NEW;
END;
$$;

CREATE TRIGGER users_assign_default_role
AFTER INSERT ON minishop.users
FOR EACH ROW EXECUTE FUNCTION minishop.assign_default_customer_role();

COMMENT ON TABLE minishop.users IS 'Tài khoản dùng chung để đăng nhập MiniShop và CMS; quyền được lưu trong user_roles.';
COMMENT ON COLUMN minishop.users.id IS 'Mã định danh duy nhất của tài khoản.';
COMMENT ON COLUMN minishop.users.full_name IS 'Họ tên hiển thị của người dùng.';

COMMENT ON TABLE minishop.roles IS 'Danh mục vai trò dùng chung cho tài khoản MiniShop và CMS.';
COMMENT ON COLUMN minishop.roles.code IS 'Mã vai trò ổn định để backend kiểm tra quyền: CUSTOMER, STAFF, ADMIN.';
COMMENT ON COLUMN minishop.roles.name IS 'Tên vai trò hiển thị bằng tiếng Việt.';
COMMENT ON COLUMN minishop.roles.description IS 'Mô tả phạm vi sử dụng của vai trò.';

COMMENT ON TABLE minishop.user_roles IS 'Gán một hoặc nhiều vai trò cho một tài khoản trong minishop.users.';
COMMENT ON COLUMN minishop.user_roles.user_id IS 'Tài khoản được cấp vai trò; xóa user sẽ xóa các liên kết vai trò.';
COMMENT ON COLUMN minishop.user_roles.role_code IS 'Mã vai trò được cấp, tham chiếu minishop.roles.code.';
COMMENT ON COLUMN minishop.user_roles.granted_at IS 'Thời điểm cấp vai trò.';
COMMENT ON COLUMN minishop.user_roles.granted_by IS 'User thực hiện cấp quyền; để trống khi gán mặc định hoặc bootstrap ban đầu.';

COMMENT ON FUNCTION minishop.assign_default_customer_role() IS 'Tự gán CUSTOMER cho mọi tài khoản mới, không cấp quyền CMS qua đăng ký công khai.';
COMMENT ON TRIGGER users_assign_default_role ON minishop.users IS 'Sau khi tạo user, gán vai trò CUSTOMER mặc định.';

COMMIT;
