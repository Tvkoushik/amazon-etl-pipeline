CREATE TABLE redshift_schema.fact_sales (
    sale_id BIGINT ENCODE zstd NOT NULL, -- PK                  
    order_id BIGINT ENCODE zstd NOT NULL,                 
    customer_id BIGINT ENCODE zstd NOT NULL,              
    product_id BIGINT ENCODE zstd NOT NULL,               
    seller_id BIGINT ENCODE zstd NOT NULL,                
    quantity INT ENCODE zstd NOT NULL,
    sale_date_id BIGINT ENCODE zstd NOT NULL,             
    total_amount DECIMAL(18, 2) ENCODE zstd NOT NULL,
    discount_amount DECIMAL(18, 2) ENCODE zstd,
    net_amount DECIMAL(18, 2) ENCODE zstd NOT NULL,
    refund_amount DECIMAL(18, 2) ENCODE zstd,
    is_returned BOOLEAN ENCODE zstd DEFAULT False         
)
DISTSTYLE KEY
DISTKEY (customer_id)
INTERLEAVED SORTKEY (sale_date_id, customer_id, product_id);

-- SELECT 
--     oi.order_item_id AS sale_id,
--     oi.order_id,
--     o.customer_id,
--     oi.product_id,
--     o.seller_id,
--     oi.quantity,
--     d_date.date_id AS sale_date_id,
--     oi.total_price AS total_amount,
--     oi.discount AS discount_amount,
--     (oi.total_price - oi.discount) AS net_amount,
--     COALESCE(oi.refund_amount, 0) AS refund_amount,
--     CASE WHEN oi.is_returned THEN True ELSE False END AS is_returned
-- FROM staging_order_items oi
-- JOIN staging_orders o ON oi.order_id = o.order_id
-- JOIN dim_customer d_c ON o.customer_id = d_c.customer_id
-- JOIN dim_product d_p ON oi.product_id = d_p.product_id
-- JOIN dim_seller d_s ON o.seller_id = d_s.seller_id
-- JOIN dim_date d_date ON o.order_date = d_date.date


CREATE TABLE redshift_schema.fact_orders (
    order_id BIGINT ENCODE zstd NOT NULL,                 
    customer_id BIGINT ENCODE zstd NOT NULL,              
    order_date_id BIGINT ENCODE zstd NOT NULL,            
    total_order_value DECIMAL(18, 2) ENCODE zstd NOT NULL,
    total_discount DECIMAL(18, 2) ENCODE zstd,
    shipping_cost DECIMAL(18, 2) ENCODE zstd,
    payment_method VARCHAR(50) ENCODE zstd,
    delivery_method VARCHAR(50) ENCODE zstd,
    order_status VARCHAR(50) ENCODE zstd                  
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (order_date_id, customer_id);

-- SELECT 
--     o.order_id,
--     o.customer_id,
--     d_date.date_id AS order_date_id,
--     o.total_amount AS total_order_value,
--     o.discount AS total_discount,
--     o.shipping_cost,
--     o.payment_method,
--     o.delivery_method,
--     o.status AS order_status
-- FROM staging_orders o
-- JOIN dim_customer d_c ON o.customer_id = d_c.customer_id
-- JOIN dim_date d_date ON o.order_date = d_date.date;

CREATE TABLE redshift_schema.fact_refunds (
    refund_id BIGINT ENCODE zstd NOT NULL,                
    order_id BIGINT ENCODE zstd NOT NULL,                 
    customer_id BIGINT ENCODE zstd NOT NULL,              
    product_id BIGINT ENCODE zstd NOT NULL,               
    seller_id BIGINT ENCODE zstd NOT NULL,                
    refund_date_id BIGINT ENCODE zstd NOT NULL,           
    refund_amount DECIMAL(18, 2) ENCODE zstd NOT NULL,
    refund_reason VARCHAR(255) ENCODE zstd
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (refund_date_id, customer_id);

-- SELECT 
--     r.return_id AS refund_id,
--     r.order_id,
--     o.customer_id,
--     r.product_id,
--     o.seller_id,
--     d_date.date_id AS refund_date_id,
--     r.refund_amount,
--     r.return_reason
-- FROM staging_returns r
-- JOIN staging_orders o ON r.order_id = o.order_id
-- JOIN dim_customer d_c ON o.customer_id = d_c.customer_id
-- JOIN dim_product d_p ON r.product_id = d_p.product_id
-- JOIN dim_seller d_s ON o.seller_id = d_s.seller_id
-- JOIN dim_date d_date ON r.return_date = d_date.date;