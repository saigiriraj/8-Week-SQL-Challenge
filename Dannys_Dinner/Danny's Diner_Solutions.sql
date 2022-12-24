-- Tables
-- 1. sales - customer_id, order_date, product_id
-- 2. members - customer_id, join_date
-- 3. menu - product_id, product_name, price

use dannys_diner;

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, sum(price) as price FROM
(
(SELECT * FROM sales)sales_join
LEFT JOIN
(SELECT * FROM menu)menu_join
on sales_join.product_id = menu_join.product_id
)
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS daysvisited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT sales_join.customer_id, sales_join.product_id, menu_join.product_name, item_order FROM
(
(SELECT *, 
row_number() Over (partition by customer_id  order by order_date, product_id) as item_order
FROM sales)sales_join
LEFT JOIN
(SELECT * FROM menu)menu_join
on sales_join.product_id = menu_join.product_id
)
where item_order = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT menu_join.product_id, menu_join.product_name, count(menu_join.product_id) as product_purchased FROM
(
(SELECT * FROM sales)sales_join
LEFT JOIN
(SELECT * FROM menu)menu_join
on sales_join.product_id = menu_join.product_id
)
GROUP BY menu_join.product_id
order by product_purchased Desc
limit 1;

-- 5 Which item was the most popular for each customer?
Select * from
(
SELECT sales_join.customer_id, menu_join.product_id, menu_join.product_name, count(menu_join.product_id) as product_purchased,
RANK() OVER(PARTITION BY sales_join.customer_id ORDER BY count(menu_join.product_id) DESC) as Rank_Order
FROM
(
(SELECT * FROM sales)sales_join
LEFT JOIN
(SELECT * FROM menu)menu_join
on sales_join.product_id = menu_join.product_id
)
GROUP BY menu_join.product_id, sales_join.customer_id
)sub_query
where sub_query.Rank_Order = 1

-- 6 Which item was purchased first by the customer after they became a member
select * from (
select a.customer_id, a.order_date, b.join_date,a.product_id ,
Rank() over(partition by customer_id order by order_date) as rank_order from
(select * from sales)a
left join
(SELECT * from members)b
on a.customer_id = b.customer_id
where a.order_date > b.join_date)sub_query
where sub_query.rank_order = 1

-- 7 Which item was purchased just before the customer became a member
select * from (
select a.customer_id, a.order_date, b.join_date,a.product_id ,
Rank() over(partition by customer_id order by order_date DESC) as rank_order from
(select * from sales)a
left join
(SELECT * from members)b
on a.customer_id = b.customer_id
where a.order_date < b.join_date)sub_query
where sub_query.rank_order = 1


-- 8 What is the total items and amount spent for each member before they became a member?
select a.customer_id, Count(Distinct a.product_id) As TotalItems, Sum(c.price) as TotalAmount from
(select * from sales)a
left join
(SELECT * from members)b
on a.customer_id = b.customer_id
left join
(select * from menu)c
on a.product_id = c.product_id
where a.order_date < b.join_date
group by a.customer_id

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select sub_query.customer_id, sum(sub_query.points) as points from
(
select a.customer_id, b.product_name, case when product_name = 'sushi' then b.price*20 else b.price*10 End as points from
(select * from sales)a
left join
(Select * from menu)b
on a.product_id = b.product_id
)sub_query
Group by sub_query.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?
Select sub_query.customer_id ,
SUM(CASE 
	When (sub_query.order_date >= sub_query.join_date and sub_query.order_date <= sub_query.Filter_Date) or (sub_query.product_id = 1) then sub_query.price*20
	Else sub_query.price*10 END)
     as Points
From
(
select a.*, b.join_date, c.price, c.product_name, b.join_date+Interval 6 DAY as Filter_Date
from
(select * from sales)a
left join
(select * from members)b
on a.customer_id = b.customer_id
left join
(select * from menu)c
on a.product_id = c.product_id
where b.join_date is Not NULL and a.order_date <= '2021-01-31'
)sub_query
Group by sub_query.customer_id

-- ****************************************** Bonus Questions **********************************************
-- 1. For Each Row in Sales table Create a Flag whether the Order was places before Memebership or After
select a.*, b.join_date, c.product_name, c.price ,
Case 
	When a.order_date < b.join_date then 'N' 
    WHEN a.order_date >= b.join_date THEN 'Y'
    ELSE 'N' End as member_flag
from
(select * from Sales)a
left join
(Select * from members)b
on a.customer_id = b.customer_id
left join
(Select * from menu)c
on a.product_id = c.product_id

-- 2.Ranking of the Customer Products and Mark as Null Where Memeber Flag is N
select sub_query.customer_id, sub_query.order_date, sub_query.product_name, sub_query.price, sub_query.member_flag ,
Case 
	When sub_query.member_flag = 'N' then NUll
    Else Rank() Over (Partition by sub_query.customer_id, sub_query.member_flag  ORDER BY sub_query.order_date) End as ranking
from
(
select a.*, b.join_date, c.product_name, c.price ,
Case 
	When a.order_date < b.join_date then 'N' 
    WHEN a.order_date >= b.join_date THEN 'Y'
    ELSE 'N' End as member_flag
from
(select * from Sales)a
left join
(Select * from members)b
on a.customer_id = b.customer_id
left join
(Select * from menu)c
on a.product_id = c.product_id
)sub_query