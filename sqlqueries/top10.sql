-- What are the top 10 product pairs that are most frequently purchased together?
WITH CombinedOrders AS (
    -- Combine prior and train order products
    SELECT order_id, product_id
    FROM order_products_prior
    UNION ALL
    SELECT order_id, product_id
    FROM order_products_train
)

SELECT
    p1.product_id AS product_id_1,
    p1.product_name AS product_name_1,
    p2.product_id AS product_id_2,
    p2.product_name AS product_name_2,
    COUNT(*) AS purchase_count
FROM
    CombinedOrders co1
JOIN
    CombinedOrders co2 ON co1.order_id = co2.order_id AND co1.product_id < co2.product_id
JOIN
    products p1 ON co1.product_id = p1.product_id
JOIN
    products p2 ON co2.product_id = p2.product_id
GROUP BY
    p1.product_id, p1.product_name, p2
    
    