--1. Query to Get Products the User Has Already Purchased
SELECT op.product_id
FROM `instacart-441209.instacart.order_products_prior` op
JOIN `instacart-441209.instacart.orders` o
ON op.order_id = o.order_id
WHERE o.user_id = 186704;

--2. Create Combined Orders Table
CREATE OR REPLACE TABLE `instacart-441209.instacart.combined_orders` AS
SELECT order_id, product_id
FROM `instacart-441209.instacart.order_products_prior`
UNION ALL
SELECT order_id, product_id
FROM `instacart-441209.instacart.order_products_train`;

--3. Query to Find Frequent Product Pairs
SELECT
    co1.product_id AS product_id_1,
    co2.product_id AS product_id_2,
    COUNT(*) AS purchase_count
FROM `instacart-441209.instacart.combined_orders` co1
JOIN `instacart-441209.instacart.combined_orders` co2
ON co1.order_id = co2.order_id AND co1.product_id < co2.product_id
GROUP BY product_id_1, product_id_2
ORDER BY purchase_count DESC
LIMIT 10;

--4. Query to Get Product Names for Frequent Pairs
SELECT
    pp.product_id_1,
    p1.product_name AS product_name_1,
    pp.product_id_2,
    p2.product_name AS product_name_2,
    pp.purchase_count
FROM (
    SELECT
        product_id_1,
        product_id_2,
        COUNT(*) AS purchase_count
    FROM `instacart-441209.instacart.combined_orders` co1
    JOIN `instacart-441209.instacart.combined_orders` co2
    ON co1.order_id = co2.order_id AND co1.product_id < co2.product_id
    GROUP BY product_id_1, product_id_2
    ORDER BY purchase_count DESC
    LIMIT 10
) AS pp
JOIN `instacart-441209.instacart.products` p1 ON pp.product_id_1 = p1.product_id
JOIN `instacart-441209.instacart.products` p2 ON pp.product_id_2 = p2.product_id;

