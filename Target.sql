-- 1)
SELECT DISTINCT(customer_city)
FROM customers;

-- 2)
SELECT COUNT(order_id)
FROM orders
WHERE year(order_purchase_timestamp) = 2017;

-- 3)

SELECT products.product_category AS category,
ROUND(SUM(payments.payment_value),1) AS sales
FROM products 
JOIN order_items on products.product_id = order_items.product_id 
JOIN payments on order_items.order_id = payments.order_id
GROUP BY products.product_category;

-- 4) 

SELECT (SUM(CASE when payment_installments >= 1 then 1 else 0 end)/count(*))*100 
FROM payments;

-- 5) 

SELECT customer_state, COUNT(customer_id) 
FROM customers
GROUP BY customer_state;
-- 6) 

SELECT monthname(order_purchase_timestamp) AS Month, COUNT(order_id) AS order_count
FROM orders
WHERE year(order_purchase_timestamp) = 2018 
GROUP BY Month;
-- 7) 


WITH count_per_order AS
( 
SELECT orders.order_id, orders.customer_id, COUNT(order_items.order_id) AS oc
FROM orders
JOIN order_items ON
orders.order_id = order_items.order_id
GROUP BY orders.order_id, orders.customer_id
)

SELECT customers.customer_city, ROUND(AVG(count_per_order.oc),2) AS Average_Orders
FROM customers
JOIN count_per_order ON
customers.customer_id = count_per_order.customer_id
GROUP BY customers.customer_city
ORDER BY Average_Orders DESC;

-- 8) 

SELECT products.product_category AS category,
	ROUND((SUM(payments.payment_value)/(SELECT SUM(payment_value) FROM payments)) * 100,2) AS sales_percentage
FROM products
JOIN order_items ON
products.product_id = order_items.product_id
JOIN payments ON
order_items.order_id = payments.order_id
GROUP BY products.product_category
ORDER BY sales_percentage DESC;

-- 9) 

SELECT products.product_category, 
COUNT(order_items.product_id) AS Order_count,
ROUND(AVG(order_items.price),2) AS Average_Price
FROM products
JOIN order_items ON 
products.product_id = order_items.product_id
GROUP BY products.product_category;

-- 10)

SELECT seller_id, total_revenue,
DENSE_RANK() OVER (ORDER BY total_revenue DESC)AS RN
FROM (
	SELECT order_items.seller_id,
	SUM(payments.payment_value) AS total_revenue
    FROM order_items
    JOIN payments ON
    order_items.order_id = payments.order_id
    GROUP BY order_items.seller_id
) AS Revenue_summary;

-- 11) 

SELECT customer_id, order_purchase_timestamp, payment,
avg(payment) over(partition by customer_id
ORDER BY order_purchase_timestamp
rows between 2 preceding and current row) AS mov_avg
FROM 
(SELECT orders.customer_id, orders.order_purchase_timestamp,
payments.payment_value AS payment
FROM payments
JOIN orders ON 
payments.order_id = orders.order_id) AS a;

-- 12)

SELECT years, months, payment, SUM(payment)
over(
ORDER BY years, months) cumulative_sales 
FROM (
SELECT year(orders.order_purchase_timestamp) AS years,
month(orders.order_purchase_timestamp) AS months,
ROUND(SUM(payments.payment_value),2) AS payment 
FROM orders
JOIN payments ON 
orders.order_id = payments.order_id
GROUP BY years, months
ORDER BY years, months) AS a;

-- 13)

with a AS (SELECT year(orders.order_purchase_timestamp) AS years,
ROUND(SUM(payments.payment_value),2) AS payment 
FROM orders
JOIN payments ON 
orders.order_id = payments.order_id
GROUP BY years
ORDER BY years)
SELECT years, ((payment - lag(payment,1) over(order by years))/
lag(payment, 1) over(order by years)) * 100 AS yoy_perc_growth
FROM a;

-- 14)

WITH a AS (
    SELECT customers.customer_id, MIN(orders.order_purchase_timestamp) AS first_order
    FROM customers
    JOIN orders ON customers.customer_id = orders.customer_id
    GROUP BY customers.customer_id
),
b AS (
    SELECT a.customer_id, COUNT(DISTINCT orders.order_purchase_timestamp) AS next_order
    FROM a
    JOIN orders ON orders.customer_id = a.customer_id
    AND orders.order_purchase_timestamp > a.first_order
    AND orders.order_purchase_timestamp < DATE_ADD(a.first_order, INTERVAL 26 MONTH)
    GROUP BY a.customer_id
)
SELECT 100 * (COUNT(DISTINCT a.customer_id) / COUNT(DISTINCT b.customer_id))
FROM a
LEFT JOIN b ON a.customer_id = b.customer_id;

-- 15)

SELECT years, customer_id, payment, d_rank
FROM (
	SELECT year(orders.order_purchase_timestamp) AS years,
    orders.customer_id,
    SUM(payments.payment_value) AS payment,
    dense_rank() over(partition by year(orders.order_purchase_timestamp)
    ORDER BY SUM(payments.payment_value) DESC) AS d_rank
    FROM orders
    JOIN payments ON 
    payments.order_id = orders.order_id
    GROUP BY year(orders.order_purchase_timestamp),
    orders.customer_id) AS a
    WHERE d_rank <= 3;
    