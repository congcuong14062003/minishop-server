-- Mô tả schema MiniShop bằng metadata PostgreSQL.
-- Chạy sau 001_init.sql; có thể chạy lại để cập nhật chú thích.
BEGIN;

COMMENT ON SCHEMA minishop IS 'Dữ liệu nghiệp vụ của ứng dụng MiniShop.';

COMMENT ON TABLE minishop.users IS 'Tài khoản khách hàng dùng để đăng nhập, mua hàng và nhận thông báo.';
COMMENT ON COLUMN minishop.users.id IS 'Mã định danh duy nhất của khách hàng.';
COMMENT ON COLUMN minishop.users.email IS 'Email đăng nhập, có thể để trống nếu dùng số điện thoại; không phân biệt chữ hoa và chữ thường khi kiểm tra trùng.';
COMMENT ON COLUMN minishop.users.phone IS 'Số điện thoại đăng nhập, có thể để trống nếu có email.';
COMMENT ON COLUMN minishop.users.full_name IS 'Họ tên hiển thị của khách hàng.';
COMMENT ON COLUMN minishop.users.password_hash IS 'Mật khẩu đã băm; có thể để trống với tài khoản chỉ đăng nhập qua nhà cung cấp ngoài.';
COMMENT ON COLUMN minishop.users.status IS 'Trạng thái tài khoản: active đang dùng, blocked bị khóa.';
COMMENT ON COLUMN minishop.users.created_at IS 'Thời điểm tạo tài khoản.';
COMMENT ON COLUMN minishop.users.updated_at IS 'Thời điểm cập nhật tài khoản gần nhất, được trigger tự động ghi.';

COMMENT ON TABLE minishop.oauth_accounts IS 'Liên kết tài khoản MiniShop với tài khoản đăng nhập từ nhà cung cấp ngoài.';
COMMENT ON COLUMN minishop.oauth_accounts.provider IS 'Tên nhà cung cấp đăng nhập, ví dụ Google.';
COMMENT ON COLUMN minishop.oauth_accounts.provider_subject IS 'Mã người dùng do nhà cung cấp cấp; duy nhất trong từng nhà cung cấp.';
COMMENT ON COLUMN minishop.oauth_accounts.user_id IS 'Tài khoản MiniShop được liên kết.';
COMMENT ON COLUMN minishop.oauth_accounts.created_at IS 'Thời điểm tạo liên kết đăng nhập.';

COMMENT ON TABLE minishop.user_preferences IS 'Tùy chọn giao diện riêng của từng khách hàng.';
COMMENT ON COLUMN minishop.user_preferences.user_id IS 'Khách hàng sở hữu tùy chọn; đồng thời là khóa chính.';
COMMENT ON COLUMN minishop.user_preferences.theme_mode IS 'Chế độ giao diện: light sáng, dark tối, system theo thiết bị.';

COMMENT ON TABLE minishop.addresses IS 'Sổ địa chỉ giao hàng của khách hàng.';
COMMENT ON COLUMN minishop.addresses.id IS 'Mã định danh của địa chỉ.';
COMMENT ON COLUMN minishop.addresses.user_id IS 'Khách hàng sở hữu địa chỉ.';
COMMENT ON COLUMN minishop.addresses.recipient_name IS 'Tên người nhận hàng tại địa chỉ này.';
COMMENT ON COLUMN minishop.addresses.recipient_phone IS 'Số điện thoại người nhận hàng.';
COMMENT ON COLUMN minishop.addresses.address_line IS 'Số nhà, tên đường và thông tin địa chỉ chi tiết.';
COMMENT ON COLUMN minishop.addresses.ward IS 'Phường hoặc xã.';
COMMENT ON COLUMN minishop.addresses.district IS 'Quận hoặc huyện.';
COMMENT ON COLUMN minishop.addresses.province IS 'Tỉnh hoặc thành phố.';
COMMENT ON COLUMN minishop.addresses.is_default IS 'Đánh dấu địa chỉ mặc định; mỗi khách hàng có tối đa một địa chỉ mặc định.';
COMMENT ON COLUMN minishop.addresses.created_at IS 'Thời điểm thêm địa chỉ.';
COMMENT ON COLUMN minishop.addresses.updated_at IS 'Thời điểm sửa địa chỉ gần nhất, được trigger tự động ghi.';

COMMENT ON TABLE minishop.categories IS 'Danh mục phân loại sản phẩm, có thể lồng danh mục cha và con.';
COMMENT ON COLUMN minishop.categories.id IS 'Mã định danh của danh mục.';
COMMENT ON COLUMN minishop.categories.slug IS 'Tên ngắn duy nhất dùng trong đường dẫn và API.';
COMMENT ON COLUMN minishop.categories.name IS 'Tên danh mục hiển thị cho người dùng.';
COMMENT ON COLUMN minishop.categories.icon IS 'Tên biểu tượng hoặc mã tài nguyên hiển thị của danh mục.';
COMMENT ON COLUMN minishop.categories.parent_id IS 'Danh mục cha; để trống nếu là danh mục cấp cao nhất.';
COMMENT ON COLUMN minishop.categories.sort_order IS 'Thứ tự sắp xếp danh mục trên giao diện.';
COMMENT ON COLUMN minishop.categories.is_active IS 'Danh mục đang được phép hiển thị và sử dụng.';
COMMENT ON COLUMN minishop.categories.created_at IS 'Thời điểm tạo danh mục.';
COMMENT ON COLUMN minishop.categories.updated_at IS 'Thời điểm cập nhật danh mục gần nhất, được trigger tự động ghi.';

COMMENT ON TABLE minishop.brands IS 'Thương hiệu của sản phẩm.';
COMMENT ON COLUMN minishop.brands.id IS 'Mã định danh của thương hiệu.';
COMMENT ON COLUMN minishop.brands.slug IS 'Tên ngắn duy nhất dùng trong đường dẫn và API.';
COMMENT ON COLUMN minishop.brands.name IS 'Tên thương hiệu hiển thị.';
COMMENT ON COLUMN minishop.brands.created_at IS 'Thời điểm tạo thương hiệu.';
COMMENT ON COLUMN minishop.brands.updated_at IS 'Thời điểm cập nhật thương hiệu gần nhất, được trigger tự động ghi.';

COMMENT ON TABLE minishop.products IS 'Thông tin chung của sản phẩm, dùng chung cho các biến thể giá và tồn kho.';
COMMENT ON COLUMN minishop.products.id IS 'Mã định danh của sản phẩm.';
COMMENT ON COLUMN minishop.products.slug IS 'Tên ngắn duy nhất dùng cho đường dẫn chi tiết sản phẩm.';
COMMENT ON COLUMN minishop.products.category_id IS 'Danh mục chứa sản phẩm.';
COMMENT ON COLUMN minishop.products.brand_id IS 'Thương hiệu của sản phẩm; có thể để trống.';
COMMENT ON COLUMN minishop.products.name IS 'Tên sản phẩm hiển thị.';
COMMENT ON COLUMN minishop.products.description IS 'Mô tả chi tiết sản phẩm.';
COMMENT ON COLUMN minishop.products.ship_from IS 'Địa điểm gửi hàng hiển thị trên thẻ sản phẩm.';
COMMENT ON COLUMN minishop.products.status IS 'Trạng thái: draft bản nháp, active đang bán, archived đã lưu trữ.';
COMMENT ON COLUMN minishop.products.rating_average IS 'Điểm đánh giá trung bình từ 0 đến 5, do backend tổng hợp.';
COMMENT ON COLUMN minishop.products.review_count IS 'Số đánh giá của sản phẩm, do backend tổng hợp.';
COMMENT ON COLUMN minishop.products.sold_count IS 'Tổng số lượng đã bán, do backend tổng hợp.';
COMMENT ON COLUMN minishop.products.created_at IS 'Thời điểm tạo sản phẩm.';
COMMENT ON COLUMN minishop.products.updated_at IS 'Thời điểm cập nhật sản phẩm gần nhất, được trigger tự động ghi.';

COMMENT ON TABLE minishop.product_images IS 'Các ảnh minh họa của sản phẩm theo thứ tự hiển thị.';
COMMENT ON COLUMN minishop.product_images.id IS 'Mã định danh của ảnh sản phẩm.';
COMMENT ON COLUMN minishop.product_images.product_id IS 'Sản phẩm sở hữu ảnh.';
COMMENT ON COLUMN minishop.product_images.image_url IS 'Đường dẫn truy cập ảnh.';
COMMENT ON COLUMN minishop.product_images.alt_text IS 'Văn bản mô tả ảnh phục vụ khả năng truy cập.';
COMMENT ON COLUMN minishop.product_images.sort_order IS 'Thứ tự ảnh; có thể dùng ảnh đầu tiên làm ảnh đại diện.';

COMMENT ON TABLE minishop.product_variants IS 'Đơn vị bán cụ thể của sản phẩm theo thuộc tính, SKU, giá và tồn kho.';
COMMENT ON COLUMN minishop.product_variants.id IS 'Mã định danh của biến thể sản phẩm.';
COMMENT ON COLUMN minishop.product_variants.product_id IS 'Sản phẩm cha của biến thể.';
COMMENT ON COLUMN minishop.product_variants.sku IS 'Mã hàng duy nhất dùng quản lý kho.';
COMMENT ON COLUMN minishop.product_variants.attributes IS 'Các lựa chọn của biến thể dạng đối tượng JSON, ví dụ màu sắc và dung lượng; dùng đối tượng rỗng nếu không có lựa chọn.';
COMMENT ON COLUMN minishop.product_variants.price_vnd IS 'Giá bán hiện tại của một đơn vị, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.product_variants.original_price_vnd IS 'Giá gốc để so sánh và tính phần trăm giảm giá, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.product_variants.stock_quantity IS 'Số lượng còn trong kho của biến thể.';
COMMENT ON COLUMN minishop.product_variants.is_active IS 'Biến thể đang được phép bán.';
COMMENT ON COLUMN minishop.product_variants.created_at IS 'Thời điểm tạo biến thể.';
COMMENT ON COLUMN minishop.product_variants.updated_at IS 'Thời điểm cập nhật biến thể gần nhất, được trigger tự động ghi.';

COMMENT ON TABLE minishop.collections IS 'Nhóm sản phẩm do cửa hàng chọn để hiển thị, ví dụ phổ biến hoặc gợi ý hôm nay.';
COMMENT ON COLUMN minishop.collections.id IS 'Mã định danh của nhóm sản phẩm.';
COMMENT ON COLUMN minishop.collections.slug IS 'Tên ngắn duy nhất để backend chọn nhóm.';
COMMENT ON COLUMN minishop.collections.title IS 'Tiêu đề nhóm hiển thị trên giao diện.';
COMMENT ON COLUMN minishop.collections.is_active IS 'Nhóm đang được phép hiển thị.';
COMMENT ON COLUMN minishop.collections.sort_order IS 'Thứ tự hiển thị giữa các nhóm.';
COMMENT ON COLUMN minishop.collections.created_at IS 'Thời điểm tạo nhóm.';
COMMENT ON COLUMN minishop.collections.updated_at IS 'Thời điểm cập nhật nhóm gần nhất, được trigger tự động ghi.';

COMMENT ON TABLE minishop.collection_products IS 'Liên kết sản phẩm với nhóm trưng bày và xác định thứ tự trong nhóm.';
COMMENT ON COLUMN minishop.collection_products.collection_id IS 'Nhóm trưng bày chứa sản phẩm.';
COMMENT ON COLUMN minishop.collection_products.product_id IS 'Sản phẩm được đưa vào nhóm.';
COMMENT ON COLUMN minishop.collection_products.sort_order IS 'Vị trí của sản phẩm trong nhóm.';

COMMENT ON TABLE minishop.banners IS 'Banner quảng bá trên trang chủ, có thể dẫn tới danh mục hoặc sản phẩm.';
COMMENT ON COLUMN minishop.banners.id IS 'Mã định danh của banner.';
COMMENT ON COLUMN minishop.banners.eyebrow IS 'Dòng chữ ngắn phía trên tiêu đề banner.';
COMMENT ON COLUMN minishop.banners.title IS 'Tiêu đề chính của banner.';
COMMENT ON COLUMN minishop.banners.description IS 'Nội dung bổ sung của banner.';
COMMENT ON COLUMN minishop.banners.image_url IS 'Đường dẫn ảnh nền hoặc ảnh minh họa banner.';
COMMENT ON COLUMN minishop.banners.category_id IS 'Danh mục đích khi bấm banner; không dùng đồng thời với product_id.';
COMMENT ON COLUMN minishop.banners.product_id IS 'Sản phẩm đích khi bấm banner; không dùng đồng thời với category_id.';
COMMENT ON COLUMN minishop.banners.sort_order IS 'Thứ tự hiển thị banner.';
COMMENT ON COLUMN minishop.banners.starts_at IS 'Thời điểm bắt đầu hiển thị; để trống nếu không giới hạn đầu kỳ.';
COMMENT ON COLUMN minishop.banners.ends_at IS 'Thời điểm ngừng hiển thị; để trống nếu không giới hạn cuối kỳ.';
COMMENT ON COLUMN minishop.banners.is_active IS 'Bật hoặc tắt banner thủ công.';

COMMENT ON TABLE minishop.flash_sale_campaigns IS 'Đợt Flash Sale với khoảng thời gian áp dụng.';
COMMENT ON COLUMN minishop.flash_sale_campaigns.id IS 'Mã định danh của đợt Flash Sale.';
COMMENT ON COLUMN minishop.flash_sale_campaigns.title IS 'Tên đợt Flash Sale hiển thị.';
COMMENT ON COLUMN minishop.flash_sale_campaigns.starts_at IS 'Thời điểm bắt đầu bán giá ưu đãi.';
COMMENT ON COLUMN minishop.flash_sale_campaigns.ends_at IS 'Thời điểm kết thúc bán giá ưu đãi.';
COMMENT ON COLUMN minishop.flash_sale_campaigns.is_active IS 'Bật hoặc tắt đợt Flash Sale thủ công.';

COMMENT ON TABLE minishop.flash_sale_variants IS 'Biến thể tham gia Flash Sale cùng giá ưu đãi và giới hạn số lượng.';
COMMENT ON COLUMN minishop.flash_sale_variants.campaign_id IS 'Đợt Flash Sale áp dụng cho biến thể.';
COMMENT ON COLUMN minishop.flash_sale_variants.variant_id IS 'Biến thể sản phẩm được giảm giá.';
COMMENT ON COLUMN minishop.flash_sale_variants.sale_price_vnd IS 'Giá bán ưu đãi cho một đơn vị, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.flash_sale_variants.stock_limit IS 'Tổng số đơn vị tối đa được bán theo ưu đãi trong đợt này.';
COMMENT ON COLUMN minishop.flash_sale_variants.sold_quantity IS 'Số đơn vị đã bán theo ưu đãi trong đợt này.';

COMMENT ON TABLE minishop.cart_items IS 'Các biến thể trong giỏ hàng của khách hàng đã đăng nhập.';
COMMENT ON COLUMN minishop.cart_items.user_id IS 'Khách hàng sở hữu giỏ hàng.';
COMMENT ON COLUMN minishop.cart_items.variant_id IS 'Biến thể sản phẩm được thêm vào giỏ.';
COMMENT ON COLUMN minishop.cart_items.quantity IS 'Số đơn vị muốn mua.';
COMMENT ON COLUMN minishop.cart_items.is_selected IS 'Mục được chọn để tính vào lần thanh toán tiếp theo.';
COMMENT ON COLUMN minishop.cart_items.created_at IS 'Thời điểm thêm biến thể vào giỏ.';
COMMENT ON COLUMN minishop.cart_items.updated_at IS 'Thời điểm sửa số lượng hoặc lựa chọn gần nhất, được trigger tự động ghi.';

COMMENT ON TABLE minishop.wishlist_items IS 'Danh sách sản phẩm yêu thích của từng khách hàng.';
COMMENT ON COLUMN minishop.wishlist_items.user_id IS 'Khách hàng yêu thích sản phẩm.';
COMMENT ON COLUMN minishop.wishlist_items.product_id IS 'Sản phẩm được yêu thích; không gắn với một biến thể cụ thể.';
COMMENT ON COLUMN minishop.wishlist_items.created_at IS 'Thời điểm thêm sản phẩm vào danh sách yêu thích.';

COMMENT ON TABLE minishop.vouchers IS 'Mã giảm giá tiền cố định dùng khi đặt hàng.';
COMMENT ON COLUMN minishop.vouchers.id IS 'Mã định danh của voucher.';
COMMENT ON COLUMN minishop.vouchers.code IS 'Mã viết hoa duy nhất để khách hàng nhập khi thanh toán.';
COMMENT ON COLUMN minishop.vouchers.title IS 'Tên voucher hiển thị.';
COMMENT ON COLUMN minishop.vouchers.description IS 'Mô tả điều kiện hoặc nội dung ưu đãi.';
COMMENT ON COLUMN minishop.vouchers.minimum_subtotal_vnd IS 'Giá trị hàng tối thiểu trước phí giao hàng và giảm giá, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.vouchers.discount_vnd IS 'Số tiền giảm cố định, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.vouchers.max_total_uses IS 'Giới hạn tổng lượt sử dụng; để trống nếu không giới hạn.';
COMMENT ON COLUMN minishop.vouchers.max_uses_per_user IS 'Số lượt tối đa mỗi khách hàng được sử dụng voucher.';
COMMENT ON COLUMN minishop.vouchers.starts_at IS 'Thời điểm bắt đầu hiệu lực.';
COMMENT ON COLUMN minishop.vouchers.ends_at IS 'Thời điểm hết hiệu lực.';
COMMENT ON COLUMN minishop.vouchers.is_active IS 'Bật hoặc tắt voucher thủ công.';
COMMENT ON COLUMN minishop.vouchers.created_at IS 'Thời điểm tạo voucher.';
COMMENT ON COLUMN minishop.vouchers.updated_at IS 'Thời điểm cập nhật voucher gần nhất, được trigger tự động ghi.';

COMMENT ON SEQUENCE minishop.order_code_seq IS 'Số tăng dần dùng tạo mã đơn hàng hiển thị.';
COMMENT ON TABLE minishop.orders IS 'Đơn đặt hàng và bản chụp địa chỉ giao hàng, số tiền tại thời điểm checkout.';
COMMENT ON COLUMN minishop.orders.id IS 'Mã định danh của đơn hàng.';
COMMENT ON COLUMN minishop.orders.order_code IS 'Mã đơn hàng duy nhất hiển thị cho khách hàng, tự tạo theo ngày và số thứ tự.';
COMMENT ON COLUMN minishop.orders.user_id IS 'Khách hàng đã đặt đơn.';
COMMENT ON COLUMN minishop.orders.checkout_key IS 'Khóa chống tạo trùng đơn khi khách hàng gửi lại cùng một yêu cầu checkout.';
COMMENT ON COLUMN minishop.orders.address_id IS 'Địa chỉ trong sổ địa chỉ được chọn khi đặt hàng; có thể để trống nếu địa chỉ gốc bị xóa.';
COMMENT ON COLUMN minishop.orders.status IS 'Trạng thái đơn: pending chờ xử lý, processing đang xử lý, shipping đang giao, delivered đã giao, cancelled đã hủy.';
COMMENT ON COLUMN minishop.orders.payment_method IS 'Cách thanh toán đã chọn: cod khi nhận hàng, card thẻ, wallet ví điện tử.';
COMMENT ON COLUMN minishop.orders.recipient_name IS 'Tên người nhận được chụp lại khi đặt hàng.';
COMMENT ON COLUMN minishop.orders.recipient_phone IS 'Số điện thoại người nhận được chụp lại khi đặt hàng.';
COMMENT ON COLUMN minishop.orders.shipping_address_line IS 'Địa chỉ chi tiết được chụp lại khi đặt hàng.';
COMMENT ON COLUMN minishop.orders.shipping_ward IS 'Phường hoặc xã giao hàng được chụp lại khi đặt hàng.';
COMMENT ON COLUMN minishop.orders.shipping_district IS 'Quận hoặc huyện giao hàng được chụp lại khi đặt hàng.';
COMMENT ON COLUMN minishop.orders.shipping_province IS 'Tỉnh hoặc thành phố giao hàng được chụp lại khi đặt hàng.';
COMMENT ON COLUMN minishop.orders.subtotal_vnd IS 'Tổng tiền hàng trước phí giao hàng và giảm giá, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.orders.shipping_fee_vnd IS 'Phí giao hàng của đơn, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.orders.discount_vnd IS 'Tổng số tiền được giảm trên đơn, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.orders.total_vnd IS 'Tổng phải trả được tính tự động bằng tiền hàng cộng phí giao hàng trừ giảm giá.';
COMMENT ON COLUMN minishop.orders.voucher_code_snapshot IS 'Mã voucher được chụp lại khi đặt hàng để giữ lịch sử dù voucher đổi hoặc bị xóa.';
COMMENT ON COLUMN minishop.orders.created_at IS 'Thời điểm đặt hàng.';
COMMENT ON COLUMN minishop.orders.updated_at IS 'Thời điểm cập nhật đơn gần nhất, được trigger tự động ghi.';

COMMENT ON TABLE minishop.order_items IS 'Các dòng sản phẩm trong đơn, giữ nguyên thông tin và giá tại thời điểm mua.';
COMMENT ON COLUMN minishop.order_items.id IS 'Mã định danh của dòng sản phẩm trong đơn.';
COMMENT ON COLUMN minishop.order_items.order_id IS 'Đơn hàng chứa dòng sản phẩm.';
COMMENT ON COLUMN minishop.order_items.product_id IS 'Sản phẩm gốc để tra cứu và liên kết đánh giá.';
COMMENT ON COLUMN minishop.order_items.variant_id IS 'Biến thể gốc đã mua.';
COMMENT ON COLUMN minishop.order_items.product_name_snapshot IS 'Tên sản phẩm được chụp lại lúc mua.';
COMMENT ON COLUMN minishop.order_items.sku_snapshot IS 'SKU được chụp lại lúc mua.';
COMMENT ON COLUMN minishop.order_items.attributes_snapshot IS 'Thuộc tính biến thể được chụp lại lúc mua dưới dạng JSON.';
COMMENT ON COLUMN minishop.order_items.quantity IS 'Số đơn vị đã mua của biến thể.';
COMMENT ON COLUMN minishop.order_items.unit_price_vnd IS 'Giá thực trả cho một đơn vị lúc mua, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.order_items.line_total_vnd IS 'Thành tiền dòng hàng được tính tự động bằng số lượng nhân đơn giá.';

COMMENT ON TABLE minishop.order_status_events IS 'Lịch sử các lần chuyển trạng thái của đơn hàng.';
COMMENT ON COLUMN minishop.order_status_events.id IS 'Mã tự tăng của sự kiện trạng thái.';
COMMENT ON COLUMN minishop.order_status_events.order_id IS 'Đơn hàng phát sinh sự kiện.';
COMMENT ON COLUMN minishop.order_status_events.from_status IS 'Trạng thái trước khi chuyển; có thể để trống cho sự kiện tạo đơn.';
COMMENT ON COLUMN minishop.order_status_events.to_status IS 'Trạng thái mới sau khi chuyển.';
COMMENT ON COLUMN minishop.order_status_events.note IS 'Ghi chú bổ sung về lần chuyển trạng thái.';
COMMENT ON COLUMN minishop.order_status_events.created_at IS 'Thời điểm chuyển trạng thái.';

COMMENT ON TABLE minishop.payments IS 'Các lần ghi nhận hoặc thử thanh toán của đơn hàng.';
COMMENT ON COLUMN minishop.payments.id IS 'Mã định danh của lần thanh toán.';
COMMENT ON COLUMN minishop.payments.order_id IS 'Đơn hàng được thanh toán.';
COMMENT ON COLUMN minishop.payments.method IS 'Phương thức của lần thanh toán: cod, card hoặc wallet.';
COMMENT ON COLUMN minishop.payments.provider IS 'Tên đơn vị xử lý thanh toán, nếu có.';
COMMENT ON COLUMN minishop.payments.provider_reference IS 'Mã giao dịch từ đơn vị thanh toán, dùng nhận diện webhook trùng.';
COMMENT ON COLUMN minishop.payments.amount_vnd IS 'Số tiền của lần thanh toán, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.payments.status IS 'Trạng thái: pending đang chờ, paid đã trả, failed thất bại, refunded đã hoàn tiền.';
COMMENT ON COLUMN minishop.payments.created_at IS 'Thời điểm tạo lần thanh toán.';
COMMENT ON COLUMN minishop.payments.paid_at IS 'Thời điểm xác nhận đã thanh toán; để trống khi chưa thanh toán.';

COMMENT ON TABLE minishop.shipments IS 'Thông tin vận chuyển của đơn hàng; mỗi đơn có tối đa một bản ghi vận chuyển.';
COMMENT ON COLUMN minishop.shipments.id IS 'Mã định danh của lần vận chuyển.';
COMMENT ON COLUMN minishop.shipments.order_id IS 'Đơn hàng được giao.';
COMMENT ON COLUMN minishop.shipments.carrier IS 'Tên đơn vị vận chuyển.';
COMMENT ON COLUMN minishop.shipments.tracking_number IS 'Mã theo dõi vận đơn do đơn vị vận chuyển cung cấp.';
COMMENT ON COLUMN minishop.shipments.status IS 'Trạng thái: preparing đang chuẩn bị, in_transit đang giao, delivered đã giao, returned hoàn trả.';
COMMENT ON COLUMN minishop.shipments.estimated_delivery_at IS 'Thời điểm dự kiến giao hàng.';
COMMENT ON COLUMN minishop.shipments.shipped_at IS 'Thời điểm bàn giao hàng cho đơn vị vận chuyển.';
COMMENT ON COLUMN minishop.shipments.delivered_at IS 'Thời điểm giao hàng thành công.';
COMMENT ON COLUMN minishop.shipments.created_at IS 'Thời điểm tạo thông tin vận chuyển.';

COMMENT ON TABLE minishop.voucher_redemptions IS 'Lượt áp dụng voucher vào đơn hàng, dùng theo dõi giới hạn sử dụng.';
COMMENT ON COLUMN minishop.voucher_redemptions.order_id IS 'Đơn hàng dùng voucher; mỗi đơn tối đa một voucher.';
COMMENT ON COLUMN minishop.voucher_redemptions.voucher_id IS 'Voucher đã áp dụng.';
COMMENT ON COLUMN minishop.voucher_redemptions.user_id IS 'Khách hàng sử dụng voucher.';
COMMENT ON COLUMN minishop.voucher_redemptions.status IS 'Trạng thái lượt dùng: applied đang áp dụng, released đã giải phóng khi hủy theo chính sách.';
COMMENT ON COLUMN minishop.voucher_redemptions.created_at IS 'Thời điểm ghi nhận lượt dùng voucher.';

COMMENT ON TABLE minishop.reviews IS 'Đánh giá của khách hàng cho sản phẩm đã mua, tối đa một đánh giá mỗi dòng đơn.';
COMMENT ON COLUMN minishop.reviews.id IS 'Mã định danh của đánh giá.';
COMMENT ON COLUMN minishop.reviews.order_item_id IS 'Dòng đơn hàng được đánh giá, bảo đảm sản phẩm đã được mua.';
COMMENT ON COLUMN minishop.reviews.product_id IS 'Sản phẩm được đánh giá, phải khớp sản phẩm trong dòng đơn.';
COMMENT ON COLUMN minishop.reviews.user_id IS 'Khách hàng viết đánh giá.';
COMMENT ON COLUMN minishop.reviews.rating IS 'Số sao đánh giá từ 1 đến 5.';
COMMENT ON COLUMN minishop.reviews.comment IS 'Nội dung đánh giá bằng chữ; có thể để trống.';
COMMENT ON COLUMN minishop.reviews.is_visible IS 'Đánh giá được phép hiển thị công khai.';
COMMENT ON COLUMN minishop.reviews.created_at IS 'Thời điểm gửi đánh giá.';
COMMENT ON COLUMN minishop.reviews.updated_at IS 'Thời điểm sửa đánh giá gần nhất, được trigger tự động ghi.';

COMMENT ON TABLE minishop.review_images IS 'Ảnh đính kèm một đánh giá theo thứ tự hiển thị.';
COMMENT ON COLUMN minishop.review_images.id IS 'Mã định danh của ảnh đánh giá.';
COMMENT ON COLUMN minishop.review_images.review_id IS 'Đánh giá sở hữu ảnh.';
COMMENT ON COLUMN minishop.review_images.image_url IS 'Đường dẫn truy cập ảnh đánh giá.';
COMMENT ON COLUMN minishop.review_images.sort_order IS 'Thứ tự ảnh trong đánh giá.';

COMMENT ON TABLE minishop.notifications IS 'Thông báo gửi tới từng khách hàng về đơn hàng, khuyến mãi hoặc nội dung chung.';
COMMENT ON COLUMN minishop.notifications.id IS 'Mã định danh của thông báo.';
COMMENT ON COLUMN minishop.notifications.user_id IS 'Khách hàng nhận thông báo.';
COMMENT ON COLUMN minishop.notifications.type IS 'Loại thông báo: order đơn hàng, promotion khuyến mãi, general nội dung chung.';
COMMENT ON COLUMN minishop.notifications.title IS 'Tiêu đề thông báo.';
COMMENT ON COLUMN minishop.notifications.body IS 'Nội dung chi tiết của thông báo.';
COMMENT ON COLUMN minishop.notifications.order_id IS 'Đơn hàng liên quan, nếu là thông báo về đơn.';
COMMENT ON COLUMN minishop.notifications.created_at IS 'Thời điểm tạo thông báo.';
COMMENT ON COLUMN minishop.notifications.read_at IS 'Thời điểm khách hàng đã đọc; để trống nghĩa là chưa đọc.';

COMMENT ON VIEW minishop.catalog_listing IS 'Dữ liệu gọn cho danh sách sản phẩm: giá biến thể đang bán rẻ nhất, tổng tồn kho và thông tin đánh giá.';
COMMENT ON COLUMN minishop.catalog_listing.id IS 'Mã định danh sản phẩm.';
COMMENT ON COLUMN minishop.catalog_listing.slug IS 'Tên ngắn của sản phẩm dùng trong đường dẫn.';
COMMENT ON COLUMN minishop.catalog_listing.category_id IS 'Danh mục của sản phẩm.';
COMMENT ON COLUMN minishop.catalog_listing.brand_id IS 'Thương hiệu của sản phẩm.';
COMMENT ON COLUMN minishop.catalog_listing.name IS 'Tên sản phẩm.';
COMMENT ON COLUMN minishop.catalog_listing.description IS 'Mô tả sản phẩm.';
COMMENT ON COLUMN minishop.catalog_listing.ship_from IS 'Địa điểm gửi hàng.';
COMMENT ON COLUMN minishop.catalog_listing.status IS 'Trạng thái hiện tại của sản phẩm.';
COMMENT ON COLUMN minishop.catalog_listing.rating_average IS 'Điểm đánh giá trung bình của sản phẩm.';
COMMENT ON COLUMN minishop.catalog_listing.review_count IS 'Số đánh giá của sản phẩm.';
COMMENT ON COLUMN minishop.catalog_listing.sold_count IS 'Tổng số lượng đã bán của sản phẩm.';
COMMENT ON COLUMN minishop.catalog_listing.price_vnd IS 'Giá thấp nhất trong các biến thể đang bán, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.catalog_listing.original_price_vnd IS 'Giá gốc của biến thể đang bán có giá thấp nhất, tính bằng đồng Việt Nam.';
COMMENT ON COLUMN minishop.catalog_listing.discount_percent IS 'Phần trăm giảm giá làm tròn của biến thể được chọn cho danh sách.';
COMMENT ON COLUMN minishop.catalog_listing.stock_quantity IS 'Tổng tồn kho của các biến thể đang bán.';

COMMIT;
