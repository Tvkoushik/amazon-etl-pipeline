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

