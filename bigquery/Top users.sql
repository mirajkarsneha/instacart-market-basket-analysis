WITH UserOrderCounts AS (
    SELECT
        o.user_id,
        COUNT(op.product_id) AS total_products_ordered
    FROM
        `instacart-441209.instacart.order_products_prior` op
    JOIN
        `instacart-441209.instacart.orders` o
    ON
        op.order_id = o.order_id
    GROUP BY
        o.user_id
)
SELECT
    uoc.user_id,
    uoc.total_products_ordered
FROM
    UserOrderCounts uoc
ORDER BY
    uoc.total_products_ordered DESC
LIMIT 5;  -- You can adjust the limit if you want more or fewer users


SELECT * FROM `instacart-441209.instacart.order_products_prior`;
