WITH CombinedOrderProducts AS (
    SELECT product_id, add_to_cart_order
    FROM `instacart-441209.instacart.order_products_prior`
    
    UNION ALL
    
    SELECT product_id, add_to_cart_order
    FROM `instacart-441209.instacart.order_products_train`
)

SELECT
    cc.product_id,
    pp.product_name,
    COUNT(*) AS AddToCartCount
FROM
    CombinedOrderProducts cc
JOIN
    `instacart-441209.instacart.products` pp
    ON pp.product_id = cc.product_id
WHERE
    cc.add_to_cart_order = 1
GROUP BY
    cc.product_id, pp.product_name
ORDER BY
    AddToCartCount DESC
LIMIT 5;
