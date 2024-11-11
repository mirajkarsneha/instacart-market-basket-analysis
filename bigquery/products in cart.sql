WITH UserOrderCounts AS (
    SELECT o.user_id,
           COUNT(op.product_id) AS total_products_ordered
    FROM `instacart-441209.instacart.order_products_prior` op
    JOIN `instacart-441209.instacart.orders` o
    ON op.order_id = o.order_id
    GROUP BY o.user_id
)

SELECT uoc.user_id,
       uoc.total_products_ordered,
       p.product_name,
       op.add_to_cart_order
FROM UserOrderCounts uoc
JOIN `instacart-441209.instacart.orders` o
    ON o.user_id = uoc.user_id
JOIN `instacart-441209.instacart.order_products_train` op
    ON op.order_id = o.order_id
JOIN `instacart-441209.instacart.products` p
    ON op.product_id = p.product_id
WHERE op.reordered = 1 -- To fetch only products that are in the cart (reordered)
ORDER BY uoc.total_products_ordered DESC
LIMIT 10;
