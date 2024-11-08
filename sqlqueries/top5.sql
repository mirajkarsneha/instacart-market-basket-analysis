-- What are the top 5 products that are most commonly added to the instacart first?
WITH CombinedOrderProducts AS (
    SELECT product_id, add_to_cart_order
    FROM order_products_prior
    UNION ALL
    SELECT product_id, add_to_cart_order
    FROM order_products_train
)

SELECT
    cc.product_id,
    pp.product_name,
    COUNT(*) AS AddToCartCount
FROM
    CombinedOrderProducts cc
JOIN
    products pp ON pp.product_id = cc.product_id
WHERE
    cc.add_to_cart_order = 1
GROUP BY
    cc.product_id, pp.product_name
ORDER BY
    AddToCartCount DESC
LIMIT 5;
 
