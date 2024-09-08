-- Brands Table
CREATE TABLE Brands (
    brand_id BIGINT PRIMARY KEY,              -- Unique identifier for each brand
    brand_name VARCHAR(255) UNIQUE NOT NULL,  -- Name of the brand
    brand_description TEXT,                   -- Brief description of the brand
    brand_logo_url VARCHAR(255),              -- URL to the brand's logo image
    brand_country VARCHAR(100),               -- Country where the brand originates
    founded_date DATE,                        -- Date the brand was founded
    website_url VARCHAR(255),                 -- Official website of the brand
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP  -- Record update time
);

-- Sample Records for Brands Table
INSERT INTO Brands (brand_id, brand_name, brand_description, brand_logo_url, brand_country, founded_date, website_url, created_at, updated_at)
VALUES 
(1, 'Brand A', 'A global electronics brand.', 's3://example/logoA.png', 'USA', '1980-04-15', 'https://brandA.com', NOW(), NOW()),
(2, 'Brand B', 'Luxury fashion and apparel brand.', 's3://example/logoB.png', 'France', '1950-09-30', 'https://brandB.com', NOW(), NOW());

-- Categories Table
CREATE TABLE Categories (
    category_id BIGINT PRIMARY KEY,                  -- Unique identifier for each category
    category_name VARCHAR(255) NOT NULL,             -- Name of the category
    parent_category_id BIGINT,                       -- Parent category, NULL if it's a top-level category
    is_active BOOLEAN DEFAULT TRUE,                  -- Whether the category is active
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (parent_category_id) REFERENCES Categories(category_id)  -- Self-referencing for hierarchical categories
);

-- Sample Records for Categories Table
INSERT INTO Categories (category_id, category_name, parent_category_id, is_active, created_at, updated_at)
VALUES
(10, 'Electronics', NULL, TRUE, NOW(), NOW()),
(20, 'Smartphones', 10, TRUE, NOW(), NOW());

-- Products Table
CREATE TABLE Products (
    product_id BIGINT PRIMARY KEY,                -- Unique identifier for each product
    name VARCHAR(255) NOT NULL,                   -- Product name
    description TEXT,                             -- Product description
    sku VARCHAR(50) UNIQUE NOT NULL,              -- SKU (Stock Keeping Unit) for inventory tracking
    brand_id BIGINT NOT NULL,                     -- Foreign key linking to Brands
    category_id BIGINT NOT NULL,                  -- Foreign key linking to Categories
    subcategory_id BIGINT,                        -- Foreign key linking to subcategories in Categories
    price DECIMAL(10,2) NOT NULL,                 -- Product price
    stock_quantity INT DEFAULT 0,                 -- Quantity of product in stock
    is_active BOOLEAN DEFAULT TRUE,               -- Whether the product is currently active
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (brand_id) REFERENCES Brands(brand_id),   -- Links to Brands table
    FOREIGN KEY (category_id) REFERENCES Categories(category_id),   -- Links to Categories table
    FOREIGN KEY (subcategory_id) REFERENCES Categories(category_id) -- Links to Subcategories in Categories table
);

-- Sample Records for Products Table
INSERT INTO Products (product_id, name, description, sku, brand_id, category_id, subcategory_id, price, stock_quantity, created_at, updated_at)
VALUES
(101, 'Smartphone A', 'Latest smartphone with 128GB storage.', 'SP-A-128', 1, 10, 20, 699.99, 500, NOW(), NOW()),
(102, 'Laptop B', '15-inch laptop with 8GB RAM and SSD storage.', 'LP-B-15', 2, 10, 21, 1299.99, 200, NOW(), NOW());

-- Sellers Table
CREATE TABLE Sellers (
    seller_id BIGINT PRIMARY KEY,                 -- Unique identifier for each seller
    seller_name VARCHAR(255) NOT NULL,            -- Seller's name
    company_name VARCHAR(255),                    -- Seller's company name
    tax_id VARCHAR(50),                           -- Seller's tax identification number (e.g., VAT, EIN)
    seller_email VARCHAR(255) UNIQUE NOT NULL,    -- Seller's email address
    seller_phone VARCHAR(20),                     -- Seller's phone number
    demographic_segment VARCHAR(50),              -- Demographic information (e.g., Urban, Suburban)
    photo_url VARCHAR(255),                       -- URL to the seller's profile photo
    license_details TEXT,                         -- License information for the seller (if any)
    location_id BIGINT,                           -- Links to location (optional)
    address_id BIGINT,                            -- Links to address for detailed information
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (address_id) REFERENCES Addresses(address_id)  -- Links to the address
);

-- Sample Records for Sellers Table
INSERT INTO Sellers (seller_id, seller_name, company_name, tax_id, seller_email, seller_phone, demographic_segment, photo_url, license_details, location_id, address_id, created_at, updated_at)
VALUES
(201, 'Seller A', 'Seller A Corp', 'TX12345', 'sellerA@example.com', '123-456-7890', 'Urban', 's3://example/sellerA.png', 'Licensed electronics seller.', 301, 401, NOW(), NOW()),
(202, 'Seller B', 'Seller B Enterprises', 'TX98765', 'sellerB@example.com', '098-765-4321', 'Suburban', 's3://example/sellerB.png', 'Licensed fashion retailer.', 302, 402, NOW(), NOW());

-- Addresses Table
CREATE TABLE Addresses (
    address_id BIGINT PRIMARY KEY,                -- Unique identifier for each address
    street VARCHAR(255),                          -- Street address
    city VARCHAR(100),                            -- City
    state VARCHAR(100),                           -- State
    zip_code VARCHAR(20),                         -- ZIP/postal code
    country VARCHAR(100),                         -- Country
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP  -- Record update time
);

-- Sample Records for Addresses Table
INSERT INTO Addresses (address_id, street, city, state, zip_code, country, created_at, updated_at)
VALUES
(401, '123 Elm Street', 'Springfield', 'IL', '62704', 'USA', NOW(), NOW()),
(402, '456 Oak Avenue', 'Shelbyville', 'IL', '62565', 'USA', NOW(), NOW());

-- Customers Table
CREATE TABLE Customers (
    customer_id BIGINT PRIMARY KEY,               -- Unique identifier for each customer
    first_name VARCHAR(255) NOT NULL,             -- Customer's first name
    last_name VARCHAR(255) NOT NULL,              -- Customer's last name
    email VARCHAR(255) UNIQUE NOT NULL,           -- Customer's email address
    phone_number VARCHAR(20),                     -- Customer's phone number
    address_id BIGINT NOT NULL,                   -- Foreign key linking to Addresses
    prime_status BOOLEAN DEFAULT FALSE,           -- Prime status (TRUE = Prime, FALSE = Regular)
    account_creation_date DATE NOT NULL,          -- Date the account was created
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (address_id) REFERENCES Addresses(address_id)  -- Links to Addresses table
);

-- Sample Records for Customers Table
INSERT INTO Customers (customer_id, first_name, last_name, email, phone_number, address_id, prime_status, account_creation_date, created_at, updated_at)
VALUES
(301, 'John', 'Doe', 'john.doe@example.com', '123-456-7890', 401, TRUE, '2022-01-15', NOW(), NOW()),
(302, 'Jane', 'Smith', 'jane.smith@example.com', '098-765-4321', 402, FALSE, '2021-11-10', NOW(), NOW());

-- Orders Table
CREATE TABLE Orders (
    order_id BIGINT PRIMARY KEY,                  -- Unique identifier for each order
    customer_id BIGINT NOT NULL,                  -- Foreign key linking to Customers
    order_date TIMESTAMP NOT NULL,                -- Date and time of the order
    status VARCHAR(50) NOT NULL,                  -- Order status (e.g., 'Delivered', 'Shipped', 'Returned')
    total_amount DECIMAL(10,2) NOT NULL,          -- Total amount of the order
    discount DECIMAL(10,2) DEFAULT 0.00,          -- Discount applied to the order
    shipping_cost DECIMAL(10,2) DEFAULT 0.00,     -- Shipping cost for the order
    payment_method VARCHAR(50),                   -- Payment method used (e.g., 'Credit Card', 'PayPal')
    delivery_method VARCHAR(50),                  -- Delivery method used (e.g., 'Expedited', 'Standard')
    shipping_id BIGINT,                           -- Links to Shipping
    delivery_id BIGINT,                           -- Links to Delivery
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),  -- Links to Customers
    FOREIGN KEY (shipping_id) REFERENCES Shipping(shipping_id),   -- Links to Shipping
    FOREIGN KEY (delivery_id) REFERENCES Delivery(delivery_id)    -- Links to Delivery
);

-- Sample Records for Orders Table
INSERT INTO Orders (order_id, customer_id, order_date, status, total_amount, discount, shipping_cost, payment_method, delivery_method, shipping_id, delivery_id, created_at, updated_at)
VALUES
(401, 301, '2023-07-15 10:30:00', 'Delivered', 199.99, 20.00, 10.00, 'Credit Card', 'Expedited', 501, 601, NOW(), NOW()),
(402, 302, '2023-06-20 12:00:00', 'Returned', 299.99, 30.00, 15.00, 'PayPal', 'Standard', 502, 602, NOW(), NOW());

-- Order_Items Table
CREATE TABLE Order_Items (
    order_item_id BIGINT PRIMARY KEY,             -- Unique identifier for each order item
    order_id BIGINT NOT NULL,                     -- Foreign key linking to Orders
    product_id BIGINT NOT NULL,                   -- Foreign key linking to Products
    quantity INT NOT NULL,                        -- Quantity of the product ordered
    unit_price DECIMAL(10,2) NOT NULL,            -- Unit price of the product
    discount DECIMAL(10,2) DEFAULT 0.00,          -- Discount applied to the product
    total_price DECIMAL(10,2) NOT NULL,           -- Total price for the item (unit_price * quantity - discount)
    is_returned BOOLEAN DEFAULT FALSE,            -- Whether the item was returned
    return_reason VARCHAR(255),                   -- Reason for return (if applicable)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),  -- Links to Orders
    FOREIGN KEY (product_id) REFERENCES Products(product_id)  -- Links to Products
);

-- Sample Records for Order_Items Table
INSERT INTO Order_Items (order_item_id, order_id, product_id, quantity, unit_price, discount, total_price, is_returned, return_reason, created_at, updated_at)
VALUES
(501, 401, 101, 1, 199.99, 20.00, 179.99, FALSE, NULL, NOW(), NOW()),
(502, 402, 102, 1, 299.99, 30.00, 269.99, TRUE, 'Defective', NOW(), NOW());

-- Payments Table
CREATE TABLE Payments (
    payment_id BIGINT PRIMARY KEY,                -- Unique identifier for each payment
    order_id BIGINT NOT NULL,                     -- Foreign key linking to Orders
    payment_method VARCHAR(50),                   -- Payment method used (e.g., 'Credit Card', 'PayPal')
    payment_date TIMESTAMP NOT NULL,              -- Date of the payment
    payment_amount DECIMAL(10,2) NOT NULL,        -- Amount paid
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)  -- Links to Orders
);

-- Sample Records for Payments Table
INSERT INTO Payments (payment_id, order_id, payment_method, payment_date, payment_amount, created_at, updated_at)
VALUES
(601, 401, 'Credit Card', '2023-07-15 10:35:00', 179.99, NOW(), NOW()),
(602, 402, 'PayPal', '2023-06-20 12:05:00', 269.99, NOW(), NOW());

-- Returns Table
CREATE TABLE Returns (
    return_id BIGINT PRIMARY KEY,                 -- Unique identifier for each return
    order_id BIGINT NOT NULL,                     -- Foreign key linking to Orders
    product_id BIGINT NOT NULL,                   -- Foreign key linking to Products
    return_date TIMESTAMP NOT NULL,               -- Date the product was returned
    return_reason VARCHAR(255),                   -- Reason for the return
    refund_amount DECIMAL(10,2) NOT NULL,         -- Amount refunded for the return
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),  -- Links to Orders
    FOREIGN KEY (product_id) REFERENCES Products(product_id)  -- Links to Products
);

-- Sample Records for Returns Table
INSERT INTO Returns (return_id, order_id, product_id, return_date, return_reason, refund_amount, created_at, updated_at)
VALUES
(701, 402, 102, '2023-06-25 14:30:00', 'Defective', 269.99, NOW(), NOW());

-- Reviews Table
CREATE TABLE Reviews (
    review_id BIGINT PRIMARY KEY,                 -- Unique identifier for each review
    product_id BIGINT NOT NULL,                   -- Foreign key linking to Products
    customer_id BIGINT NOT NULL,                  -- Foreign key linking to Customers
    rating DECIMAL(3,2) NOT NULL,                 -- Rating given by the customer (e.g., 4.5)
    review_text TEXT,                             -- Review content provided by the customer
    review_date TIMESTAMP NOT NULL,               -- Date the review was written
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (product_id) REFERENCES Products(product_id),  -- Links to Products
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)  -- Links to Customers
);

-- Sample Records for Reviews Table
INSERT INTO Reviews (review_id, product_id, customer_id, rating, review_text, review_date, created_at, updated_at)
VALUES
(801, 101, 301, 4.5, 'Great smartphone with excellent features.', '2023-07-16 09:00:00', NOW(), NOW()),
(802, 102, 302, 3.8, 'Good laptop but could use more RAM.', '2023-06-21 14:20:00', NOW(), NOW());

-- Shipping Table
CREATE TABLE Shipping (
    shipping_id BIGINT PRIMARY KEY,               -- Unique identifier for each shipment
    order_id BIGINT NOT NULL,                     -- Foreign key linking to Orders
    carrier VARCHAR(100),                         -- Carrier name (e.g., FedEx, UPS)
    shipping_date TIMESTAMP NOT NULL,             -- Date the order was shipped
    estimated_arrival TIMESTAMP,                  -- Estimated arrival date
    tracking_number VARCHAR(100) UNIQUE,          -- Shipment tracking number
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)  -- Links to Orders
);

-- Sample Records for Shipping Table
INSERT INTO Shipping (shipping_id, order_id, carrier, shipping_date, estimated_arrival, tracking_number, created_at, updated_at)
VALUES
(501, 401, 'FedEx', '2023-07-15 10:45:00', '2023-07-17 10:45:00', 'FX123456789', NOW(), NOW()),
(502, 402, 'UPS', '2023-06-20 12:15:00', '2023-06-23 12:15:00', 'UPS987654321', NOW(), NOW());

-- Delivery Table
CREATE TABLE Delivery (
    delivery_id BIGINT PRIMARY KEY,               -- Unique identifier for each delivery
    order_id BIGINT NOT NULL,                     -- Foreign key linking to Orders
    customer_id BIGINT NOT NULL,                  -- Foreign key linking to Customers
    delivery_date TIMESTAMP,                      -- Actual delivery date
    delivered_by VARCHAR(100),                    -- Delivery personnel's name
    delivery_status VARCHAR(50),                  -- Delivery status (e.g., 'On Time', 'Delayed')
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Record creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Record update time
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),  -- Links to Orders
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)  -- Links to Customers
);

-- Sample Records for Delivery Table
INSERT INTO Delivery (delivery_id, order_id, customer_id, delivery_date, delivered_by, delivery_status, created_at, updated_at)
VALUES
(601, 401, 301, '2023-07-18 15:45:00', 'John Delivery', 'On Time', NOW(), NOW()),
(602, 402, 302, '2023-06-25 14:30:00', 'Jane Delivery', 'Delayed', NOW(), NOW());