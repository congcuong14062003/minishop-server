-- MiniShop, PostgreSQL 16+. Run once on an empty database with ON_ERROR_STOP=1.
-- Monetary values are whole Vietnamese dong (BIGINT), never floating point.
BEGIN;

CREATE SCHEMA minishop;
SET LOCAL search_path TO minishop, public;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT,
    phone TEXT,
    full_name TEXT NOT NULL CHECK (length(btrim(full_name)) > 0),
    password_hash TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'blocked')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (email IS NOT NULL OR phone IS NOT NULL),
    CHECK (email IS NULL OR length(btrim(email)) > 3),
    CHECK (phone IS NULL OR phone ~ '^\+?[0-9]{9,15}$')
);
CREATE UNIQUE INDEX users_email_unique ON users (lower(email)) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX users_phone_unique ON users (phone) WHERE phone IS NOT NULL;

CREATE TABLE oauth_accounts (
    provider TEXT NOT NULL,
    provider_subject TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (provider, provider_subject),
    UNIQUE (user_id, provider)
);
CREATE INDEX oauth_accounts_user_idx ON oauth_accounts (user_id);

CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    theme_mode TEXT NOT NULL DEFAULT 'system'
        CHECK (theme_mode IN ('light', 'dark', 'system'))
);

CREATE TABLE addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_name TEXT NOT NULL CHECK (length(btrim(recipient_name)) > 0),
    recipient_phone TEXT NOT NULL CHECK (recipient_phone ~ '^\+?[0-9]{9,15}$'),
    address_line TEXT NOT NULL CHECK (length(btrim(address_line)) > 0),
    ward TEXT,
    district TEXT,
    province TEXT,
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX addresses_user_idx ON addresses (user_id);
CREATE UNIQUE INDEX addresses_one_default_per_user ON addresses (user_id)
    WHERE is_default;

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL CHECK (length(btrim(name)) > 0),
    icon TEXT,
    parent_id UUID REFERENCES categories(id) ON DELETE RESTRICT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    CHECK (parent_id IS NULL OR parent_id <> id)
);
CREATE INDEX categories_parent_idx ON categories (parent_id);

CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    name TEXT NOT NULL CHECK (length(btrim(name)) > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    brand_id UUID REFERENCES brands(id) ON DELETE RESTRICT,
    name TEXT NOT NULL CHECK (length(btrim(name)) > 0),
    description TEXT NOT NULL DEFAULT '',
    ship_from TEXT,
    status TEXT NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'active', 'archived')),
    rating_average NUMERIC(3,2) NOT NULL DEFAULT 0
        CHECK (rating_average BETWEEN 0 AND 5),
    review_count INTEGER NOT NULL DEFAULT 0 CHECK (review_count >= 0),
    sold_count BIGINT NOT NULL DEFAULT 0 CHECK (sold_count >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX products_category_status_idx ON products (category_id, status);
CREATE INDEX products_brand_idx ON products (brand_id);
CREATE INDEX products_active_sold_idx ON products (sold_count DESC)
    WHERE status = 'active';

CREATE TABLE product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL CHECK (length(btrim(image_url)) > 0),
    alt_text TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
    UNIQUE (product_id, sort_order)
);

-- Every product has at least one variant; use '{}' for a product without options.
-- Example attributes: {"Màu sắc":"Đen","Dung lượng":"256GB"}.
CREATE TABLE product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    sku TEXT NOT NULL UNIQUE CHECK (length(btrim(sku)) > 0),
    attributes JSONB NOT NULL DEFAULT '{}'::jsonb
        CHECK (jsonb_typeof(attributes) = 'object'),
    price_vnd BIGINT NOT NULL CHECK (price_vnd >= 0),
    original_price_vnd BIGINT NOT NULL CHECK (original_price_vnd >= price_vnd),
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (product_id, attributes),
    UNIQUE (id, product_id)
);
CREATE INDEX product_variants_product_price_idx ON product_variants
    (product_id, price_vnd) WHERE is_active;
CREATE INDEX product_variants_product_idx ON product_variants (product_id);

CREATE TABLE collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    title TEXT NOT NULL CHECK (length(btrim(title)) > 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE collection_products (
    collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (collection_id, product_id),
    UNIQUE (collection_id, sort_order)
);
CREATE INDEX collection_products_product_idx ON collection_products (product_id);

CREATE TABLE banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    eyebrow TEXT,
    title TEXT NOT NULL CHECK (length(btrim(title)) > 0),
    description TEXT,
    image_url TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    CHECK (category_id IS NULL OR product_id IS NULL),
    CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at)
);
CREATE INDEX banners_active_order_idx ON banners (sort_order) WHERE is_active;

CREATE TABLE flash_sale_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL CHECK (length(btrim(title)) > 0),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    CHECK (ends_at > starts_at)
);
CREATE INDEX flash_sale_campaigns_window_idx ON flash_sale_campaigns
    (starts_at, ends_at) WHERE is_active;
CREATE TABLE flash_sale_variants (
    campaign_id UUID NOT NULL REFERENCES flash_sale_campaigns(id) ON DELETE CASCADE,
    variant_id UUID NOT NULL REFERENCES product_variants(id) ON DELETE RESTRICT,
    sale_price_vnd BIGINT NOT NULL CHECK (sale_price_vnd >= 0),
    stock_limit INTEGER NOT NULL CHECK (stock_limit > 0),
    sold_quantity INTEGER NOT NULL DEFAULT 0 CHECK (sold_quantity >= 0),
    PRIMARY KEY (campaign_id, variant_id),
    CHECK (sold_quantity <= stock_limit)
);
CREATE INDEX flash_sale_variants_variant_idx ON flash_sale_variants (variant_id);

CREATE TABLE cart_items (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    variant_id UUID NOT NULL REFERENCES product_variants(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    is_selected BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, variant_id)
);
CREATE INDEX cart_items_variant_idx ON cart_items (variant_id);

CREATE TABLE wishlist_items (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, product_id)
);
CREATE INDEX wishlist_items_product_idx ON wishlist_items (product_id);

CREATE TABLE vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE CHECK (code ~ '^[A-Z0-9_-]{3,32}$'),
    title TEXT NOT NULL CHECK (length(btrim(title)) > 0),
    description TEXT NOT NULL DEFAULT '',
    minimum_subtotal_vnd BIGINT NOT NULL DEFAULT 0 CHECK (minimum_subtotal_vnd >= 0),
    discount_vnd BIGINT NOT NULL CHECK (discount_vnd > 0),
    max_total_uses INTEGER CHECK (max_total_uses > 0),
    max_uses_per_user INTEGER NOT NULL DEFAULT 1 CHECK (max_uses_per_user > 0),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (ends_at > starts_at)
);

CREATE SEQUENCE order_code_seq;
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_code TEXT NOT NULL UNIQUE DEFAULT
        ('MS' || to_char(now() AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYYMMDD') ||
         nextval('minishop.order_code_seq')::text),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    checkout_key UUID,
    address_id UUID REFERENCES addresses(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'processing', 'shipping', 'delivered', 'cancelled')),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('cod', 'card', 'wallet')),
    recipient_name TEXT NOT NULL,
    recipient_phone TEXT NOT NULL,
    shipping_address_line TEXT NOT NULL,
    shipping_ward TEXT,
    shipping_district TEXT,
    shipping_province TEXT,
    subtotal_vnd BIGINT NOT NULL CHECK (subtotal_vnd >= 0),
    shipping_fee_vnd BIGINT NOT NULL DEFAULT 0 CHECK (shipping_fee_vnd >= 0),
    discount_vnd BIGINT NOT NULL DEFAULT 0 CHECK (discount_vnd >= 0),
    total_vnd BIGINT GENERATED ALWAYS AS
        (subtotal_vnd + shipping_fee_vnd - discount_vnd) STORED,
    voucher_code_snapshot TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (discount_vnd <= subtotal_vnd + shipping_fee_vnd),
    CHECK (length(btrim(order_code)) > 0),
    CHECK (length(btrim(recipient_name)) > 0),
    CHECK (length(btrim(recipient_phone)) > 0),
    CHECK (length(btrim(shipping_address_line)) > 0)
);
ALTER SEQUENCE order_code_seq OWNED BY orders.order_code;
CREATE INDEX orders_user_created_idx ON orders (user_id, created_at DESC);
CREATE INDEX orders_status_created_idx ON orders (status, created_at DESC);
CREATE INDEX orders_address_idx ON orders (address_id);
CREATE UNIQUE INDEX orders_checkout_key_unique ON orders (user_id, checkout_key)
    WHERE checkout_key IS NOT NULL;

CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL,
    variant_id UUID NOT NULL,
    product_name_snapshot TEXT NOT NULL,
    sku_snapshot TEXT NOT NULL,
    attributes_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb
        CHECK (jsonb_typeof(attributes_snapshot) = 'object'),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_vnd BIGINT NOT NULL CHECK (unit_price_vnd >= 0),
    line_total_vnd BIGINT GENERATED ALWAYS AS (quantity * unit_price_vnd) STORED,
    UNIQUE (order_id, variant_id),
    UNIQUE (id, product_id),
    FOREIGN KEY (variant_id, product_id)
        REFERENCES product_variants(id, product_id) ON DELETE RESTRICT
);
CREATE INDEX order_items_order_idx ON order_items (order_id);
CREATE INDEX order_items_product_idx ON order_items (product_id);
CREATE INDEX order_items_variant_idx ON order_items (variant_id);

CREATE TABLE order_status_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    from_status TEXT CHECK (from_status IN
        ('pending', 'processing', 'shipping', 'delivered', 'cancelled')),
    to_status TEXT NOT NULL CHECK (to_status IN
        ('pending', 'processing', 'shipping', 'delivered', 'cancelled')),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX order_status_events_order_idx ON order_status_events (order_id, created_at);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    method TEXT NOT NULL CHECK (method IN ('cod', 'card', 'wallet')),
    provider TEXT,
    provider_reference TEXT,
    amount_vnd BIGINT NOT NULL CHECK (amount_vnd >= 0),
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'paid', 'failed', 'refunded')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    paid_at TIMESTAMPTZ
);
CREATE INDEX payments_order_idx ON payments (order_id, created_at DESC);
CREATE UNIQUE INDEX payments_provider_reference_unique ON payments
    (provider, provider_reference)
    WHERE provider IS NOT NULL AND provider_reference IS NOT NULL;

CREATE TABLE shipments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
    carrier TEXT,
    tracking_number TEXT,
    status TEXT NOT NULL DEFAULT 'preparing'
        CHECK (status IN ('preparing', 'in_transit', 'delivered', 'returned')),
    estimated_delivery_at TIMESTAMPTZ,
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX shipments_tracking_unique ON shipments (carrier, tracking_number)
    WHERE carrier IS NOT NULL AND tracking_number IS NOT NULL;

CREATE TABLE voucher_redemptions (
    order_id UUID PRIMARY KEY REFERENCES orders(id) ON DELETE RESTRICT,
    voucher_id UUID NOT NULL REFERENCES vouchers(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'applied'
        CHECK (status IN ('applied', 'released')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX voucher_redemptions_voucher_status_idx ON voucher_redemptions
    (voucher_id, status);
CREATE INDEX voucher_redemptions_user_voucher_idx ON voucher_redemptions
    (user_id, voucher_id, status);

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_item_id UUID NOT NULL UNIQUE,
    product_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT CHECK (comment IS NULL OR length(btrim(comment)) > 0),
    is_visible BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    FOREIGN KEY (order_item_id, product_id)
        REFERENCES order_items(id, product_id) ON DELETE RESTRICT
);
CREATE INDEX reviews_product_created_idx ON reviews (product_id, created_at DESC)
    WHERE is_visible;
CREATE INDEX reviews_user_created_idx ON reviews (user_id, created_at DESC);

CREATE TABLE review_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL CHECK (length(btrim(image_url)) > 0),
    sort_order INTEGER NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
    UNIQUE (review_id, sort_order)
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('order', 'promotion', 'general')),
    title TEXT NOT NULL CHECK (length(btrim(title)) > 0),
    body TEXT NOT NULL DEFAULT '',
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at TIMESTAMPTZ
);
CREATE INDEX notifications_user_created_idx ON notifications (user_id, created_at DESC);
CREATE INDEX notifications_unread_idx ON notifications (user_id, created_at DESC)
    WHERE read_at IS NULL;
CREATE INDEX notifications_order_idx ON notifications (order_id);

-- Listing data comes from the cheapest active variant. The backend may cache this
-- projection later if the catalog becomes large.
CREATE VIEW catalog_listing AS
SELECT p.id, p.slug, p.category_id, p.brand_id, p.name, p.description,
       p.ship_from, p.status, p.rating_average, p.review_count, p.sold_count,
       cheapest.price_vnd, cheapest.original_price_vnd,
       CASE WHEN cheapest.original_price_vnd > cheapest.price_vnd
            THEN round(100.0 * (cheapest.original_price_vnd - cheapest.price_vnd)
                       / cheapest.original_price_vnd)::integer
            ELSE 0 END AS discount_percent,
       COALESCE(stock.stock_quantity, 0) AS stock_quantity
FROM products p
LEFT JOIN LATERAL (
    SELECT v.price_vnd, v.original_price_vnd
    FROM product_variants v
    WHERE v.product_id = p.id AND v.is_active
    ORDER BY v.price_vnd, v.id
    LIMIT 1
) cheapest ON true
LEFT JOIN LATERAL (
    SELECT sum(v.stock_quantity) AS stock_quantity
    FROM product_variants v
    WHERE v.product_id = p.id AND v.is_active
) stock ON true;

CREATE FUNCTION touch_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER users_touch BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER addresses_touch BEFORE UPDATE ON addresses
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER categories_touch BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER brands_touch BEFORE UPDATE ON brands
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER products_touch BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER product_variants_touch BEFORE UPDATE ON product_variants
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER collections_touch BEFORE UPDATE ON collections
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER cart_items_touch BEFORE UPDATE ON cart_items
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER vouchers_touch BEFORE UPDATE ON vouchers
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER orders_touch BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER reviews_touch BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

COMMIT;
