--Customers who haven’t placed an order in the last 30 days? 
SELECT COUNT(DISTINCT user_id) AS InactiveCustomers
FROM (
    SELECT 
        user_id, 
        MAX(days_since_prior_order) AS max_days_since_prior
    FROM `instacart-441209.instacart.orders`
    GROUP BY user_id
) AS Subquery
WHERE max_days_since_prior >= 30 OR max_days_since_prior IS NULL;

--Churn rate calulation for past 30 days

WITH InactiveCustomers AS (
    SELECT COUNT(DISTINCT user_id) AS InactiveCount
    FROM (
        SELECT 
            user_id, 
            MAX(days_since_prior_order) AS max_days_since_prior
        FROM `instacart-441209.instacart.orders`
        GROUP BY user_id
    ) AS Subquery
    WHERE max_days_since_prior >= 30 OR max_days_since_prior IS NULL
)
SELECT 
    InactiveCount * 100.0 / NULLIF((SELECT COUNT(DISTINCT user_id) 
    FROM `instacart-441209.instacart.orders`), 0) AS ChurnRate
FROM InactiveCustomers;