
USE magist;

#What categories of tech products does Magist have?
SELECT
	DISTINCT product_category_name_english AS category
FROM products AS p
Expand
questions_business.sql
8 KB
USE magist;

#How many orders are there in the dataset?
SELECT 
    COUNT(order_id) AS number_of_orders,
	COUNT(DISTINCT order_id) AS distinct_number_of_orders
Expand
questions_data_exploration.sql
2 KB
﻿
Johannes Ballauff
Johannes Ballauff#5934
USE magist;

#What categories of tech products does Magist have?
SELECT
	DISTINCT product_category_name_english AS category
FROM products AS p
LEFT JOIN
	product_category_name_translation AS t ON p.product_category_name = t.product_category_name;

   ## computers_accessories, electronics, computers, telephony

#How many products of these tech categories have been sold (within the time window of the database snapshot)? What percentage does that represent from the overall number of products sold?
SELECT 
COUNT(o.product_id) AS sold,
CASE 
	WHEN t.product_category_name_english = "computers_accessories" THEN "tech"
	WHEN t.product_category_name_english = "electronics" THEN "tech"
	WHEN t.product_category_name_english = "computers" THEN "tech"
	WHEN t.product_category_name_english = "telephony" THEN "tech"
	ELSE "other"
END AS tech_or_other
FROM order_items as o
LEFT JOIN products AS p ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation AS t ON p.product_category_name = t.product_category_name
GROUP BY tech_or_other;
## 15342/(97308+15342) =~ 0.136 = 13.6%

#What’s the average price of the products being sold?
SELECT 
t.product_category_name_english AS category,
AVG(o.price) AS avg_price
FROM order_items as o
LEFT JOIN products AS p ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation AS t ON p.product_category_name = t.product_category_name
GROUP BY category
HAVING category IN ("computers_accessories", "electronics", "computers","telephony");

#Are expensive tech products popular?
## expensive = price > avarage item price of Eniac products (540€)
## popular = propotion of sales from all 'tech' sales
SELECT 
t.product_category_name_english AS category,
COUNT(o.product_id) AS n_sales,
CASE 
	WHEN o.price > 540 THEN "above_avarage"
    ELSE "avarage_or_below"
END AS price_category
FROM order_items as o
LEFT JOIN products AS p ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation AS t ON p.product_category_name = t.product_category_name
GROUP BY category, price_category
HAVING category IN ("computers_accessories", "electronics", "computers","telephony")
ORDER BY category;

#How many months of data are included in the magist database?
SELECT 
    YEAR(order_purchase_timestamp) AS ord_year,
    MONTH(order_purchase_timestamp) AS ord_month,
    COUNT(order_id) AS number_of_orders
FROM
    orders
GROUP BY ord_year , ord_month
ORDER BY ord_year, ord_month;
## 25 BUT 9/2018 - 10/2018 incomplete? (low sales numbers) -> 23


#How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers?
SELECT
	COUNT(seller_id)
FROM
	sellers;
## 3095

SELECT
	COUNT(DISTINCT s.seller_id)
FROM sellers AS s
LEFT JOIN order_items AS o ON s.seller_id = o.seller_id
LEFT JOIN products AS p ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation as t ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN ("computers_accessories", "electronics", "computers","telephony");

#What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?
# earn = revenue (total gross income?)
SELECT
	SUM(op.payment_value) AS Total_revenue
FROM sellers AS s
LEFT JOIN order_items AS o ON s.seller_id = o.seller_id
LEFT JOIN order_payments AS op ON o.order_id = op.order_id;
# ~ 20,000,000

SELECT
	SUM(op.payment_value) AS Total_revenue
FROM sellers AS s
LEFT JOIN order_items AS o ON s.seller_id = o.seller_id
LEFT JOIN order_payments AS op ON o.order_id = op.order_id
LEFT JOIN products AS p ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation as t ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN ("computers_accessories", "electronics", "computers","telephony");
## ~2,600,000

#Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?
# earn = revenue (total gross income?)
SELECT
	AVG(output.monthly_revenue)
FROM
	(SELECT
		YEAR(o.order_approved_at) AS year,
		MONTH(o.order_approved_at) AS month,
		SUM(op.payment_value) AS monthly_revenue
	FROM sellers AS s
	LEFT JOIN order_items AS oi ON s.seller_id = oi.seller_id
	LEFT JOIN orders AS o ON oi.order_id = o.order_id
	LEFT JOIN order_payments AS op ON o.order_id = op.order_id
	GROUP BY year, month
	ORDER BY year,month) AS output;
## ~ 846,000

SELECT
	AVG(output.monthly_revenue)
FROM
	(SELECT
		YEAR(o.order_approved_at) AS year,
		MONTH(o.order_approved_at) AS month,
		SUM(op.payment_value) AS monthly_revenue
	FROM sellers AS s
	LEFT JOIN order_items AS oi ON s.seller_id = oi.seller_id
	LEFT JOIN orders AS o ON oi.order_id = o.order_id
	LEFT JOIN order_payments AS op ON o.order_id = op.order_id
    LEFT JOIN products AS p ON oi.product_id = p.product_id
	LEFT JOIN product_category_name_translation as t ON p.product_category_name = t.product_category_name
	WHERE t.product_category_name_english IN ("computers_accessories", "electronics", "computers","telephony")
	GROUP BY year, month
	ORDER BY year,month) AS output;
## ~ 118,000

#What’s the average time between the order being placed and the product being delivered?

SELECT
	AVG(TIMESTAMPDIFF(DAY,order_purchase_timestamp,order_delivered_customer_date)) AS avg_delivery_time_days
FROM
	orders;

#How many orders are delivered on time vs orders delivered with a delay?
#delayed = order delivered >= 1 day after expected date
SELECT
	COUNT(order_id),
    CASE 
		WHEN DATE(order_delivered_customer_date) <= DATE(order_estimated_delivery_date) THEN "in_time"
        ELSE "delayed"
        END AS delayed_or_in_time
FROM
	orders
GROUP BY delayed_or_in_time;

#Is there any pattern for delayed orders, e.g. big products being delayed more often?
SELECT AVG(product_width_cm * product_height_cm * product_length_cm) AS avg_product_volume FROM products; #16564 cm^3
SELECT AVG(product_weight_g) AS avg_product_weight FROM products; #2276 g

#size?
SELECT
	COUNT(o.order_id),
    CASE 
		WHEN DATE(o.order_delivered_customer_date) <= DATE(o.order_estimated_delivery_date) THEN "in_time"
        ELSE "delayed"
        END AS delayed_or_in_time,
		CASE 
		WHEN p.product_width_cm * p.product_height_cm * p.product_length_cm <= 16564 THEN "average_or_below"
        ELSE "above_average"
        END AS size
FROM
	orders AS o
LEFT JOIN order_items AS oi ON o.order_id = oi.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
GROUP BY delayed_or_in_time, size
ORDER BY size;

#weight?
SELECT 
    COUNT(o.order_id),
    CASE
        WHEN DATE(o.order_delivered_customer_date) <= DATE(o.order_estimated_delivery_date) THEN 'in_time'
        ELSE 'delayed'
    END AS delayed_or_in_time,
    CASE
        WHEN p.product_weight_g <= 2276 THEN 'average_or_below'
        ELSE 'above_average'
    END AS weight
FROM
    orders AS o
        LEFT JOIN
    order_items AS oi ON o.order_id = oi.order_id
        LEFT JOIN
    products AS p ON oi.product_id = p.product_id
GROUP BY delayed_or_in_time , weight
ORDER BY weight;


#category?
SELECT
	COUNT(o.order_id),
    CASE 
		WHEN DATE(o.order_delivered_customer_date) <= DATE(o.order_estimated_delivery_date) THEN "in_time"
        ELSE "delayed"
        END AS delayed_or_in_time,
		CASE 
		WHEN t.product_category_name_english IN ("computers_accessories", "electronics", "computers","telephony") THEN "tech"
        ELSE "other"
        END AS category
FROM
	orders AS o
LEFT JOIN order_items AS oi ON o.order_id = oi.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation as t ON p.product_category_name = t.product_category_name
GROUP BY delayed_or_in_time, category
ORDER BY category;
