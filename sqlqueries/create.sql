USE instacart;
-- Create `aisles` table
CREATE TABLE `aisles` (
    `aisle_id` INT PRIMARY KEY,              -- Unique identifier for the aisle
    `aisle` VARCHAR(255) NOT NULL,          -- Name or description of the aisle
    INDEX (`aisle_id`)
);

-- Create `departments` table
CREATE TABLE `departments` (
    `department_id` INT PRIMARY KEY,         -- Unique identifier for the department
    `department` VARCHAR(255) NOT NULL,     -- Name or description of the department
    INDEX (`department_id`)
);

-- Create `products` table with foreign keys referencing `aisles` and `departments`
CREATE TABLE `products` (
    `product_id` INT PRIMARY KEY AUTO_INCREMENT,
    `product_name` VARCHAR(255) NOT NULL,
    `aisle_id` INT NOT NULL,
    `department_id` INT NOT NULL,
    INDEX (`aisle_id`),
    INDEX (`department_id`),
    FOREIGN KEY (`aisle_id`) REFERENCES `aisles` (`aisle_id`),
    FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`)
);

-- Create `orders` table
CREATE TABLE `orders` (
    `order_id` INT NOT NULL,
    `user_id` INT NOT NULL,
    `eval_set` VARCHAR(50) NOT NULL,
    `order_number` INT NOT NULL,
    `order_dow` INT NOT NULL,               -- Day of the week (0 = Sunday, 6 = Saturday)
    `order_hour_of_day` INT NOT NULL,       -- Hour of the day (0-23)
    `days_since_prior_order` INT          -- Days since the last order (can be NULL)
);

-- Cre-- Create `order_products_train` table with foreign keys referencing `orders` and `products`
CREATE TABLE `order_products_train` (
    `order_id` INT NOT NULL,
    `product_id` INT NOT NULL,
    `add_to_cart_order` INT NOT NULL,      -- The order in which the product was added to the cart
    `reordered` TINYINT NOT NULL,           -- Indicates if the product was reordered (0 = No, 1 = Yes)
    INDEX (`order_id`),
    INDEX (`product_id`)
);


-- Create `order_products_prior` table with foreign keys referencing `orders` and `products`
CREATE TABLE `order_products_prior` (
    `order_id` INT NOT NULL,
    `product_id` INT NOT NULL,
    `add_to_cart_order` INT NOT NULL,      -- The order in which the product was added to the cart
    `reordered` TINYINT NOT NULL,           -- Indicates if the product was reordered (0 = No, 1 = Yes)
    INDEX (`order_id`),
    INDEX (`product_id`)
);


SELECT * FROM  order_products_train;

SELECT DISTINCT order_id 
FROM order_products_train 
WHERE order_id NOT IN (SELECT order_id FROM orders);

-- Disable foreign key checks temporarily
SET foreign_key_checks = 0;

-- Perform the data import (for example, with LOAD DATA INFILE or INSERT INTO)
LOAD DATA LOCAL INFILE '/Users/rishikeshdhokare/Documents/Ironhack/FinalProject/instacart-customer-churn-analysis/datafiles/order_products__train.csv'
INTO TABLE order_products_train
FIELDS TERMINATED BY ','  -- assuming the CSV is comma-separated
ENCLOSED BY '"'           -- if fields are enclosed in double quotes (optional)
LINES TERMINATED BY '\n'  -- assuming each row ends with a new line
IGNORE 1 ROWS;            -- ignore the first row if it contains headers


-- Re-enable foreign key checks
SET foreign_key_checks = 1;

SELECT count(*) FROM orders;

SELECT count(*)  FROM order_products_train;

SELECT  count(*) FROM order_products_prior;

SELECT COUNT(DISTINCT user_id) AS InactiveCustomers
FROM (
    SELECT user_id, MAX(days_since_prior_order) AS max_days_since_prior
    FROM Orders
    GROUP BY user_id
) AS Subquery
WHERE max_days_since_prior >= 30 OR max_days_since_prior IS NULL;

WITH InactiveCustomers AS (
    SELECT COUNT(DISTINCT user_id) AS InactiveCount
    FROM (
        SELECT user_id, MAX(days_since_prior_order) AS max_days_since_prior
        FROM Orders
        GROUP BY user_id
    ) AS Subquery
    WHERE max_days_since_prior >= 30 OR max_days_since_prior IS NULL
)
SELECT InactiveCount * 100.0 / NULLIF((SELECT COUNT(DISTINCT user_id) FROM Orders), 0) AS ChurnRate
FROM InactiveCustomers;


