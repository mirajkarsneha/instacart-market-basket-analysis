WITH CombinedOrders AS (
    -- Combine prior and train order products
    SELECT order_id, product_id
    FROM `instacart-441209.instacart.order_products_prior`
    UNION ALL
    SELECT order_id, product_id
    FROM `instacart-441209.instacart.order_products_train`
),
ProductPairs AS (
    -- Find product pairs based on previous orders
    SELECT
        p1.product_id AS product_id_1,
        p2.product_id AS product_id_2,
        COUNT(*) AS purchase_count
    FROM
        CombinedOrders co1
    JOIN
        CombinedOrders co2 ON co1.order_id = co2.order_id AND co1.product_id < co2.product_id
    JOIN
        `instacart-441209.instacart.products` p1 ON co1.product_id = p1.product_id
    JOIN
        `instacart-441209.instacart.products` p2 ON co2.product_id = p2.product_id
    GROUP BY
        p1.product_id, p2.product_id
),
UserCart AS (
    -- Identify products in the user's cart (assuming cart is based on eval_set = 'test')
    SELECT user_id, product_id
    FROM `instacart-441209.instacart.orders` o
    JOIN `instacart-441209.instacart.order_products_train` op
        ON o.order_id = op.order_id
    WHERE o.eval_set = 'test' AND o.user_id = 10266
)
SELECT
    p1.product_id AS recommended_product_id,
    p1.product_name AS recommended_product_name,
    SUM(pp.purchase_count) AS recommendation_score
FROM
    UserCart uc
JOIN
    ProductPairs pp ON uc.product_id = pp.product_id_1
JOIN
    `instacart-441209.instacart.products` p1 ON pp.product_id_2 = p1.product_id
WHERE
    p1.product_id NOT IN (SELECT product_id FROM UserCart)
GROUP BY
    p1.product_id, p1.product_name
ORDER BY
    recommendation_score DESC
LIMIT 5;


WITH UserProducts AS (
    SELECT
        op.order_id,
        op.product_id
    FROM
        `instacart-441209.instacart.order_products_prior` op
    JOIN
        `instacart-441209.instacart.orders` o
    ON
        op.order_id = o.order_id
    WHERE
        o.user_id = 143095
)
SELECT DISTINCT
    up.product_id,
    p.product_name
FROM
    UserProducts up
JOIN
    `instacart-441209.instacart.products` p
ON
    up.product_id = p.product_id;
