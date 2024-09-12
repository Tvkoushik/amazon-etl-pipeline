CREATE TABLE redshift_schema.dim_product (
    product_id BIGINT ENCODE zstd NOT NULL,         
    product_name VARCHAR(255) ENCODE zstd NOT NULL,
    category_id BIGINT ENCODE zstd NOT NULL,
    brand_id BIGINT ENCODE zstd NOT NULL,
    price DECIMAL(10, 2) ENCODE zstd NOT NULL,
    launch_date DATE ENCODE zstd,
    current_stock_quantity INT ENCODE zstd,
    created_at TIMESTAMP ENCODE zstd,
    updated_at TIMESTAMP ENCODE zstd
)
DISTSTYLE KEY
DISTKEY (product_id)
SORTKEY (category_id, brand_id);


CREATE TABLE redshift_schema.dim_seller (
    seller_id BIGINT ENCODE zstd NOT NULL,              
    seller_name VARCHAR(255) ENCODE zstd NOT NULL,
    company_name VARCHAR(255) ENCODE zstd,
    total_sales_amount DECIMAL(18, 2) ENCODE zstd,
    total_refunds DECIMAL(18, 2) ENCODE zstd,
    total_returns INT ENCODE zstd,
    quality_bucket VARCHAR(50) ENCODE zstd,
    demographic_segment VARCHAR(50) ENCODE zstd,
    effective_date DATE ENCODE zstd,                   
    expiry_date DATE ENCODE zstd DEFAULT '9999-12-31', 
    is_current_record BOOLEAN ENCODE zstd DEFAULT True,
    created_at TIMESTAMP ENCODE zstd,
    updated_at TIMESTAMP ENCODE zstd
)
DISTSTYLE KEY
DISTKEY (seller_id)
SORTKEY (effective_date, seller_id);

CREATE TABLE redshift_schema.dim_customer (
    customer_id BIGINT ENCODE zstd NOT NULL,             
    first_name VARCHAR(255) ENCODE zstd NOT NULL,
    last_name VARCHAR(255) ENCODE zstd NOT NULL,
    email VARCHAR(255) ENCODE zstd NOT NULL,
    phone_number VARCHAR(20) ENCODE zstd,
    address_id BIGINT ENCODE zstd NOT NULL,
    prime_status BOOLEAN ENCODE zstd,
    total_spent DECIMAL(18, 2) ENCODE zstd,              
    transaction_count INT ENCODE zstd,
    refund_count INT ENCODE zstd,
    quality_bucket VARCHAR(50) ENCODE zstd,
    effective_date DATE ENCODE zstd,                     
    expiry_date DATE ENCODE zstd DEFAULT '9999-12-31',   
    is_current_record BOOLEAN ENCODE zstd DEFAULT True,  
    created_at TIMESTAMP ENCODE zstd,
    updated_at TIMESTAMP ENCODE zstd
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (effective_date, customer_id);

-- MERGE INTO redshift_schema.dim_customer AS dim 
-- USING (
--     SELECT 
--         stg.customer_id,
--         stg.first_name,
--         stg.last_name,
--         stg.email,
--         stg.phone_number,
--         stg.address_id,
--         stg.prime_status,
--         SUM(oi.total_price - oi.discount) AS total_spent,  -- Derived from order items
--         COUNT(o.order_id) AS transaction_count,  -- Derived from orders
--         COUNT(r.return_id) AS refund_count,  -- Derived from returns
--         CASE 
--             WHEN COUNT(o.order_id) >= 10 AND SUM(oi.total_price) > 1000 THEN 'High'
--             WHEN COUNT(o.order_id) >= 5 THEN 'Medium'
--             ELSE 'Low'
--         END AS quality_bucket,
--         current_date AS effective_date,
--         '9999-12-31' AS expiry_date,
--         True AS is_current_record,
--         stg.created_at,
--         stg.updated_at
--     FROM redshift_schema.staging_customers stg
--     LEFT JOIN redshift_schema.staging_orders o ON o.customer_id = stg.customer_id
--     LEFT JOIN redshift_schema.staging_order_items oi ON oi.order_id = o.order_id
--     LEFT JOIN redshift_schema.staging_returns r ON r.customer_id = stg.customer_id
--     WHERE stg.cdc_flag IN ('I', 'U')
--     GROUP BY stg.customer_id, stg.first_name, stg.last_name, stg.email, 
--              stg.phone_number, stg.address_id, stg.prime_status, 
--              stg.created_at, stg.updated_at
-- ) AS stg 
-- ON dim.customer_id = stg.customer_id

-- WHEN MATCHED AND dim.is_current_record = True THEN 
--   UPDATE SET 
--     dim.is_current_record = False, 
--     dim.expiry_date = current_date

-- WHEN NOT MATCHED THEN 
--   INSERT (
--     customer_id, first_name, last_name, email, 
--     phone_number, address_id, prime_status, 
--     total_spent, transaction_count, refund_count, 
--     quality_bucket, effective_date, expiry_date, 
--     is_current_record, created_at, updated_at
--   ) 
--   VALUES (
--     stg.customer_id, stg.first_name, stg.last_name, 
--     stg.email, stg.phone_number, stg.address_id, 
--     stg.prime_status, stg.total_spent, stg.transaction_count, 
--     stg.refund_count, stg.quality_bucket, current_date, 
--     '9999-12-31', True, stg.created_at, stg.updated_at
--   )

-- WHEN MATCHED AND stg.cdc_flag = 'D' AND dim.is_current_record = True THEN 
--   UPDATE SET 
--     dim.is_current_record = False, 
--     dim.expiry_date = current_date;



CREATE TABLE redshift_schema.dim_date (
    date_id BIGINT ENCODE zstd NOT NULL,       
    date DATE ENCODE zstd NOT NULL,            
    day_of_week INT ENCODE zstd,               
    day_of_month INT ENCODE zstd,              
    day_of_year INT ENCODE zstd,               
    week_of_year INT ENCODE zstd,              
    month INT ENCODE zstd,                     
    month_name VARCHAR(20) ENCODE zstd,        
    quarter INT ENCODE zstd,                   
    year INT ENCODE zstd,                      
    is_weekend BOOLEAN ENCODE zstd,            
    is_holiday BOOLEAN ENCODE zstd DEFAULT False
)
DISTSTYLE ALL
SORTKEY (date);

CREATE TABLE redshift_schema.dim_time (
    time_id BIGINT ENCODE zstd NOT NULL,       
    hour INT ENCODE zstd,                      
    minute INT ENCODE zstd,                    
    second INT ENCODE zstd,                    
    period VARCHAR(2) ENCODE zstd,             
    time_of_day_segment VARCHAR(20) ENCODE zstd 
)
DISTSTYLE ALL
SORTKEY (hour, minute, second);


CREATE TABLE redshift_schema.dim_category (
    category_id BIGINT ENCODE zstd NOT NULL,       
    category_name VARCHAR(255) ENCODE zstd NOT NULL,
    parent_category_id BIGINT ENCODE zstd,         
    is_active BOOLEAN ENCODE zstd DEFAULT True,
    created_at TIMESTAMP ENCODE zstd,
    updated_at TIMESTAMP ENCODE zstd
)
DISTSTYLE KEY
DISTKEY (category_id)
SORTKEY (category_id);

CREATE TABLE redshift_schema.dim_brand (
    brand_id BIGINT ENCODE zstd NOT NULL,        
    brand_name VARCHAR(255) ENCODE zstd NOT NULL,
    country VARCHAR(100) ENCODE zstd,
    founded_date DATE ENCODE zstd,
    website_url VARCHAR(255) ENCODE zstd,
    created_at TIMESTAMP ENCODE zstd,
    updated_at TIMESTAMP ENCODE zstd
)
DISTSTYLE KEY
DISTKEY (brand_id)
SORTKEY (brand_id);

