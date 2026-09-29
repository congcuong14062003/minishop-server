-- Optional, repeatable reference data matching the current MiniShop UI.
BEGIN;
SET LOCAL search_path TO minishop, public;

INSERT INTO categories (slug, name, icon, sort_order) VALUES
    ('phone', 'Điện thoại', 'smartphone', 1),
    ('laptop', 'Laptop', 'monitor', 2),
    ('fashion', 'Thời trang', 'shopping-bag', 3),
    ('shoes', 'Giày dép', 'package', 4),
    ('beauty', 'Mỹ phẩm', 'droplet', 5),
    ('home', 'Đồ gia dụng', 'home', 6),
    ('accessories', 'Phụ kiện', 'headphones', 7),
    ('gaming', 'Gaming', 'cpu', 8)
ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order;

INSERT INTO collections (slug, title, sort_order) VALUES
    ('popular', 'Được yêu thích', 1),
    ('recommended', 'Gợi ý hôm nay', 2)
ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title,
    sort_order = EXCLUDED.sort_order;

INSERT INTO vouchers
    (code, title, description, minimum_subtotal_vnd, discount_vnd, starts_at, ends_at)
VALUES
    ('MINI50', 'Giảm 50.000 ₫', 'Cho đơn hàng từ 500.000 ₫', 500000, 50000,
     TIMESTAMPTZ '2026-01-01 00:00:00+07', TIMESTAMPTZ '2028-01-01 00:00:00+07'),
    ('MINI100', 'Giảm 100.000 ₫', 'Cho đơn hàng từ 2.000.000 ₫', 2000000, 100000,
     TIMESTAMPTZ '2026-01-01 00:00:00+07', TIMESTAMPTZ '2028-01-01 00:00:00+07'),
    ('MINI200', 'Giảm 200.000 ₫', 'Cho đơn hàng từ 10.000.000 ₫', 10000000, 200000,
     TIMESTAMPTZ '2026-01-01 00:00:00+07', TIMESTAMPTZ '2028-01-01 00:00:00+07')
ON CONFLICT (code) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    minimum_subtotal_vnd = EXCLUDED.minimum_subtotal_vnd,
    discount_vnd = EXCLUDED.discount_vnd,
    starts_at = EXCLUDED.starts_at,
    ends_at = EXCLUDED.ends_at;

COMMIT;
