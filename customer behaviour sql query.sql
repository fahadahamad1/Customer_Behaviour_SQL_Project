SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;


-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS days_visited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH customer_first_purchase AS (
	SELECT customer_id, MIN(order_date) AS first_purchase_date
	FROM sales 
	GROUP BY customer_id
)
SELECT cfp.customer_id, cfp.first_purchase_date, m.product_name
FROM customer_first_purchase cfp
JOIN sales s
ON s.customer_id = cfp.customer_id
AND cfp.first_purchase_date = s.order_date
JOIN menu m 
ON m.product_id = s.product_id;
 
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name, COUNT(*) AS total_purchased
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC;

-- 5. Which item was the most popular for each customer?

WITH customer_popularity AS(
	SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count, 
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS ranks
	FROM sales s
	JOIN menu m
	ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
)
SELECT cp.customer_id, cp.product_name, cp.purchase_count
FROM customer_popularity cp
WHERE ranks = 1;


-- 6. Which item was purchased first by the customer after they became a member?

WITH first_purchase_after_membership AS (
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
	FROM sales s
	JOIN members mb
	ON s.customer_id = mb.customer_id
	WHERE s.order_date >= mb.join_date
	GROUP BY s.customer_id
)
SELECT fpam.customer_id, m.product_name
FROM first_purchase_after_membership fpam
JOIN sales s 
ON s.customer_id = fpam.customer_id
AND fpam.first_purchase_date = s.order_date
JOIN menu m
ON s.product_id = m.product_id;

-- 7. Which item was purchased just before the customer became a member?

WITH last_purchase_before_membership AS (
	SELECT s.customer_id, MAX(s.order_date) AS last_purchase_date
	FROM sales s
	JOIN members mb
	ON s.customer_id = mb.customer_id
	WHERE s.order_date < mb.join_date
	GROUP BY s.customer_id
)
SELECT lpbm.customer_id, m.product_name
FROM last_Purchase_before_membership lpbm
JOIN sales s
ON lpbm.customer_id = s.customer_id
AND lpbm.last_purchase_date = s.order_date
JOIN menu m
ON s.product_id = m.product_id;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(*) AS total_items, SUM(m.price) AS total_spent
FROM sales s 
JOIN menu m
ON s.product_id = m.product_id
JOIN members mb 
ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, SUM(
	CASE
		WHEN m.product_name = 'sushi' THEN m.price*20
        ELSE m.price*10 END) AS total_points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/

SELECT s.customer_id, SUM(
	CASE 
		WHEN s.order_date BETWEEN mb.join_date AND DATE_ADD(mb.join_date, INTERVAL 7 DAY) THEN m.price * 20
		WHEN m.product_name = 'sushi' THEN m.price * 20
		ELSE m.price * 10 END) AS total_points 
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id 
LEFT JOIN members mb 
ON s.customer_id = mb.customer_id 
WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31' 
GROUP BY s.customer_id;
   
-- 11. Recreate the table output using the available data

SELECT s.customer_id, s.order_date, mb.join_date, m.product_name, m.price, 
	CASE
		WHEN s.order_date >= mb.join_date THEN 'Y'
        ELSE 'N' END AS member
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
LEFT JOIN members mb 
ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;        

-- 12. Rank all the things:

WITH customer_data AS (
	SELECT s.customer_id, s.order_date, mb.join_date, m.product_name, m.price,
		CASE 
			WHEN s.order_date < mb.join_date THEN 'N'
			WHEN s.order_date >= mb.join_date THEN 'Y'
			ELSE 'N' END AS member
	FROM sales s 
	LEFT JOIN members mb 
	ON s.customer_id = mb.customer_id
	JOIN menu m
	ON s.product_id = m.product_id
)
SELECT *,
	CASE 
		WHEN member = 'N' THEN NULL 
        ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
        END AS ranking
FROM customer_data
ORDER BY customer_id, order_date;        
        
