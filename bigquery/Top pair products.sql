WITH CombinedOrders AS (
    -- Combine prior and train order products
    SELECT order_id, product_id
    FROM `instacart-441209.instacart.order_products_prior`
    UNION ALL
    SELECT order_id, product_id
    FROM `instacart-441209.instacart.order_products_train`
)

SELECT
    p1.product_name AS product_name_1,
    p2.product_name AS product_name_2,
    COUNT(*) AS purchase_count
FROM
    CombinedOrders co1
JOIN
    CombinedOrders co2 ON co1.order_id = co2.order_id AND co1.product_id < co2.product_id  -- Ensure unique pairs by using < operator
JOIN
    `instacart-441209.instacart.products` p1 ON co1.product_id = p1.product_id
JOIN
    `instacart-441209.instacart.products` p2 ON co2.product_id = p2.product_id
GROUP BY
    p1.product_id, p1.product_name, p2.product_id, p2.product_name
ORDER BY
    purchase_count DESC
LIMIT 10;
