-- Ensure the database is created and in use
CREATE DATABASE IF NOT EXISTS instacart;
USE instacart;

-- Create Table: AISLES
CREATE TABLE IF NOT EXISTS aisles (
    aisle_id INT PRIMARY KEY,
    aisle VARCHAR(255)
);

-- Load Data into AISLES Table
LOAD DATA INFILE '/Users/rishikeshdhokare/Documents/Ironhack/FinalProject/instacart-market-basket-analysis/datafiles/aisles.csv'
INTO TABLE aisles
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(aisle_id, aisle);

-- Create Table: DEPARTMENTS
CREATE TABLE IF NOT EXISTS departments (
    department_id INT PRIMARY KEY,
    department VARCHAR(255)
);

select * from departments limit 10;

-- Load Data into DEPARTMENTS Table
LOAD DATA INFILE '/Users/rishikeshdhokare/Documents/Ironhack/FinalProject/instacart-market-basket-analysis/datafiles/departments.csv'
INTO TABLE departments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(department_id, department);

-- Create Table: PRODUCTS
CREATE TABLE IF NOT EXISTS products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    aisle_id INT,
    department_id INT,
    FOREIGN KEY (aisle_id) REFERENCES aisles(aisle_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Load Data into PRODUCTS Table
LOAD DATA INFILE '/Users/rishikeshdhokare/Documents/Ironhack/FinalProject/instacart-market-basket-analysis/datafiles/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, aisle_id, department_id);

-- Create Table: ORDERS
CREATE TABLE IF NOT EXISTS orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    eval_set VARCHAR(50),
    order_number INT,
    order_dow INT,
    order_hour_of_day INT,
    days_since_prior_order INT
);

SHOW VARIABLES LIKE 'local_infile';

-- Load Data into ORDERS Table
LOAD DATA LOCAL INFILE '/Users/rishikeshdhokare/Documents/Ironhack/FinalProject/instacart-market-basket-analysis/datafiles/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, user_id, eval_set, order_number, order_dow, order_hour_of_day, days_since_prior_order);


LOAD DATA LOCAL INFILE '/path/to/your/file.csv'
INTO TABLE your_table_name
FIELDS TERMINATED BY ','  -- Specify delimiter
ENCLOSED BY '"'          -- Enclosure for string fields
LINES TERMINATED BY '\n' -- Line terminator
IGNORE 1 LINES;         -- Ignore header row


-- Create Table: ORDER_PRODUCTS
CREATE TABLE IF NOT EXISTS order_products (
    order_id INT,
    product_id INT,
    add_to_cart_order INT,
    reordered INT,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Load Data into ORDER_PRODUCTS Table
LOAD DATA INFILE '/Users/rishikeshdhokare/Documents/Ironhack/FinalProject/instacart-market-basket-analysis/datafiles/order_products__prior.csv'
INTO TABLE order_products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, product_id, add_to_cart_order, reordered);

CREATE TABLE `order_products_prior` (
    `order_id` INT NOT NULL,
    `product_id` INT NOT NULL,
    `add_to_cart_order` INT NOT NULL,      -- The order in which the product was added to the cart
    `reordered` TINYINT NOT NULL,           -- Indicates if the product was reordered (0 = No, 1 = Yes)
    INDEX (`order_id`),
    INDEX (`product_id`)
);

CREATE TABLE `order_products_train` (
    `order_id` INT NOT NULL,
    `product_id` INT NOT NULL,
    `add_to_cart_order` INT NOT NULL,      -- The order in which the product was added to the cart
    `reordered` TINYINT NOT NULL,           -- Indicates if the product was reordered (0 = No, 1 = Yes)
    INDEX (`order_id`),
    INDEX (`product_id`)
);

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA LOCAL INFILE '/Users/rishikeshdhokare/Documents/Ironhack/FinalProject/instacart-market-basket-analysis/datafiles/order_products__prior.csv' INTO TABLE order_products_prior;

SELECT user, host, plugin FROM mysql.user;

ALTER USER 'sneha.miraj009'@'localhost' IDENTIFIED WITH mysql_native_password BY 'berlin13055';


SELECT count(*) FROM order_products_prior;

SELECT count(*) FROM orders;

SELECT count(*) FROM order_products_train;

SELECT count(*) FROM aisles;

SELECT count(*) FROM departments;

SELECT count(*) FROM products;


