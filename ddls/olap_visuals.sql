-- Product Growth/Depreciation Trends and Categorization by Sales Quantities (Month over Month)
SELECT
    d_p.product_id,
    d_p.product_name,
    d_c.category_name,
    d_b.brand_name,
    d_date.year,
    d_date.month,
    SUM(f_s.quantity) AS total_sales_quantity,
    SUM(f_s.total_amount) AS total_sales_amount,
    LAG(SUM(f_s.quantity), 1) OVER (
        PARTITION BY f_s.product_id
        ORDER BY
            d_date.year,
            d_date.month
    ) AS prev_month_quantity,
    (
        SUM(f_s.quantity) - LAG(SUM(f_s.quantity), 1) OVER (
            PARTITION BY f_s.product_id
            ORDER BY
                d_date.year,
                d_date.month
        )
    ) AS growth_depreciation_quantity
FROM
    redshift_schema.fact_sales f_s
    JOIN redshift_schema.dim_product d_p ON f_s.product_id = d_p.product_id
    JOIN redshift_schema.dim_category d_c ON d_p.category_id = d_c.category_id
    JOIN redshift_schema.dim_brand d_b ON d_p.brand_id = d_b.brand_id
    JOIN redshift_schema.dim_date d_date ON f_s.sale_date_id = d_date.date_id
GROUP BY
    d_p.product_id,
    d_p.product_name,
    d_c.category_name,
    d_b.brand_name,
    d_date.year,
    d_date.month
ORDER BY
    d_p.product_name,
    d_date.year,
    d_date.month;

-- Seller Behavior and Statistics (Categorization by Quality of Service)
SELECT
    d_s.seller_id,
    d_s.seller_name,
    d_s.company_name,
    d_s.demographic_segment,
    SUM(f_s.total_amount) AS total_sales_amount,
    SUM(f_s.refund_amount) AS total_refund_amount,
    SUM(
        CASE
            WHEN f_s.is_returned = True THEN 1
            ELSE 0
        END
    ) AS total_returns,
    CASE
        WHEN SUM(f_s.refund_amount) = 0
        AND SUM(
            CASE
                WHEN f_s.is_returned = True THEN 1
                ELSE 0
            END
        ) = 0 THEN 'High'
        WHEN SUM(f_s.refund_amount) > 0
        AND SUM(f_s.refund_amount) < 0.05 * SUM(f_s.total_amount) THEN 'Medium'
        ELSE 'Low'
    END AS quality_bucket
FROM
    redshift_schema.fact_sales f_s
    JOIN redshift_schema.dim_seller d_s ON f_s.seller_id = d_s.seller_id
GROUP BY
    d_s.seller_id,
    d_s.seller_name,
    d_s.company_name,
    d_s.demographic_segment
ORDER BY
    quality_bucket,
    total_sales_amount DESC;

-- Consumer Behavior and Statistics (Categorization by Quality, Spend, and Frequency)
SELECT
    d_c.customer_id,
    d_c.first_name || ' ' || d_c.last_name AS customer_name,
    d_c.email,
    d_c.prime_status,
    COUNT(f_o.order_id) AS total_transactions,
    SUM(f_o.total_order_value) AS total_spent,
    SUM(
        CASE
            WHEN f_r.refund_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS total_refunds,
    CASE
        WHEN SUM(f_r.refund_id IS NOT NULL) = 0
        AND COUNT(f_o.order_id) > 5 THEN 'High'
        WHEN SUM(f_r.refund_id IS NOT NULL) > 0
        AND SUM(f_r.refund_id IS NOT NULL) < 0.1 * COUNT(f_o.order_id) THEN 'Medium'
        ELSE 'Low'
    END AS quality_bucket,
    CASE
        WHEN SUM(f_o.total_order_value) > 1000 THEN 'High Spender'
        WHEN SUM(f_o.total_order_value) BETWEEN 500
        AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spend_category
FROM
    redshift_schema.fact_orders f_o
    LEFT JOIN redshift_schema.fact_refunds f_r ON f_o.order_id = f_r.order_id
    JOIN redshift_schema.dim_customer d_c ON f_o.customer_id = d_c.customer_id
GROUP BY
    d_c.customer_id,
    d_c.first_name,
    d_c.last_name,
    d_c.email,
    d_c.prime_status
ORDER BY
    quality_bucket,
    spend_category,
    total_spent DESC;