CREATE TABLE staging_brands (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    brand_id BIGINT,
    brand_name VARCHAR(255),
    brand_description TEXT,
    brand_logo_url VARCHAR(255),
    brand_country VARCHAR(100),
    founded_date DATE,
    website_url VARCHAR(255),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_categories (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    category_id BIGINT,
    category_name VARCHAR(255),
    parent_category_id BIGINT,
    is_active BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_products (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    product_id BIGINT,
    name VARCHAR(255),
    description TEXT,
    sku VARCHAR(50),
    brand_id BIGINT,
    category_id BIGINT,
    subcategory_id BIGINT,
    price DECIMAL(10, 2),
    stock_quantity INT,
    is_active BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_sellers (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    seller_id BIGINT,
    seller_name VARCHAR(255),
    company_name VARCHAR(255),
    tax_id VARCHAR(50),
    seller_email VARCHAR(255),
    seller_phone VARCHAR(20),
    demographic_segment VARCHAR(50),
    photo_url VARCHAR(255),
    license_details TEXT,
    location_id BIGINT,
    address_id BIGINT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_addresses (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    address_id BIGINT,
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    zip_code VARCHAR(20),
    country VARCHAR(100),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_customers (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    customer_id BIGINT,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255),
    phone_number VARCHAR(20),
    address_id BIGINT,
    prime_status BOOLEAN,
    account_creation_date DATE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_orders (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    order_id BIGINT,
    customer_id BIGINT,
    order_date TIMESTAMP,
    status VARCHAR(50),
    total_amount DECIMAL(10, 2),
    discount DECIMAL(10, 2),
    shipping_cost DECIMAL(10, 2),
    payment_method VARCHAR(50),
    delivery_method VARCHAR(50),
    shipping_id BIGINT,
    delivery_id BIGINT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_order_items (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    order_item_id BIGINT,
    order_id BIGINT,
    product_id BIGINT,
    quantity INT,
    unit_price DECIMAL(10, 2),
    discount DECIMAL(10, 2),
    total_price DECIMAL(10, 2),
    is_returned BOOLEAN,
    return_reason VARCHAR(255),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_payments (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    payment_id BIGINT,
    order_id BIGINT,
    payment_method VARCHAR(50),
    payment_date TIMESTAMP,
    payment_amount DECIMAL(10, 2),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_returns (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    return_id BIGINT,
    order_id BIGINT,
    product_id BIGINT,
    return_date TIMESTAMP,
    return_reason VARCHAR(255),
    refund_amount DECIMAL(10, 2),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_reviews (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    review_id BIGINT,
    product_id BIGINT,
    customer_id BIGINT,
    rating DECIMAL(3, 2),
    review_text TEXT,
    review_date TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_shipping (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    shipping_id BIGINT,
    order_id BIGINT,
    carrier VARCHAR(100),
    shipping_date TIMESTAMP,
    estimated_arrival TIMESTAMP,
    tracking_number VARCHAR(100),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

CREATE TABLE staging_delivery (
    cdc_flag CHAR(1),                          -- CDC change flag (I/U/D)
    delivery_id BIGINT,
    order_id BIGINT,
    customer_id BIGINT,
    delivery_date TIMESTAMP,
    delivered_by VARCHAR(100),
    delivery_status VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
DISTSTYLE EVEN;

