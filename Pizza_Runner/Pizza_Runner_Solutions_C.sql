-- TABLES
-- runners
-- customer_orders
-- runner_orders
-- pizza_names
-- pizza_recipes
-- pizza_toppings

-- C - Ingredient Optimisation

-- Create temporary tables

-- -- Split Pizza Toppings to Row Level
CREATE TABLE pizza_runner.pizza_recipies_row AS
SELECT a.pizza_id,
       trim(b.topping) AS topping_id,
       c.topping_name,
       d.pizza_name
FROM pizza_runner.pizza_recipes a
JOIN
	json_table(
    trim(replace(json_array(a.toppings), ',', '","')),
	'$[*]' columns (topping varchar(50) PATH '$')) b
LEFT JOIN
pizza_runner.pizza_toppings c
on trim(b.topping) = c.topping_id
LEFT JOIN
pizza_runner.pizza_names d
ON a.pizza_id = d.pizza_id
;

-- Column Level Table
DROP TABLE IF EXISTS pizza_runner.pizza_recipies_column;
CREATE TABLE pizza_runner.pizza_recipies_column AS
SELECT pizza_id, pizza_name, 
group_concat(topping_id) AS topping_id, 
group_concat(topping_name) AS topping_name 
FROM pizza_runner.pizza_recipies_row
GROUP BY  pizza_id, pizza_name;

-- Customer Order table explode
DROP TABLE IF exists pizza_runner.customer_orders_row;
CREATE TABLE pizza_runner.customer_orders_row AS
SELECT t.row_num,
       t.order_id,
       t.customer_id,
       t.pizza_id,
       CASE WHEN trim(json_1.exclusions) IN ('', 'null') THEN NULL ELSE trim(json_1.exclusions) END exclusions,
       CASE WHEN trim(json_2.extras) IN ('', 'null') THEN NULL ELSE trim(json_2.extras) END extras,
       t.order_time
FROM
  (SELECT *,
          row_number() over() AS row_num
   FROM pizza_runner.customer_orders) t
INNER JOIN json_table(trim(replace(json_array(t.exclusions), ',', '","')),
                      '$[*]' columns (exclusions varchar(50) PATH '$')) json_1
INNER JOIN json_table(trim(replace(json_array(t.extras), ',', '","')),
                      '$[*]' columns (extras varchar(50) PATH '$')) json_2 ;


-- C.1 - What are the standard ingredients for each pizza?
SELECT * FROM pizza_runner.pizza_recipies_column;


-- C.2 - What was the most commonly added extra?
SELECT 
	a.extras, 
    b.topping_name,
    COUNT(*) AS total_orders
FROM 
	pizza_runner.customer_orders_row a
INNER JOIN
	pizza_runner.pizza_recipies_row b
ON a.extras = b.topping_id
WHERE extras is  NOT NULL
GROUP BY extras, b.topping_name
ORDER BY 3 DESC
LIMIT 1;

-- C.3 - What was the most common exclusion?
SELECT 
	a.exclusions, 
    b.topping_name,
    COUNT(*) AS total_orders
FROM 
	pizza_runner.customer_orders_row a
INNER JOIN
	pizza_runner.pizza_recipies_row b
ON a.exclusions = b.topping_id
WHERE exclusions is  NOT NULL
GROUP BY exclusions, b.topping_name
ORDER BY 3 DESC
LIMIT 1;

-- C.4 - Generate an order item for each record in the customers_orders table in the format of one of the following:
SELECT
	sub.row_num,
    sub.order_id,
    sub.customer_id,
    CASE WHEN sub.exclusion_topping IS NULL AND sub.extra_topping is NULL THEN sub.pizza_name
    WHEN sub.exclusion_topping IS NOT NULL AND sub.extra_topping is NULL 
    THEN CONCAT(sub.pizza_name, " - ", 'Exculude ', sub.exclusion_topping)
    WHEN sub.exclusion_topping IS NULL AND sub.extra_topping is NOT NULL
    THEN CONCAT(sub.pizza_name, " - ", 'Include ', sub.extra_topping)
    ELSE  CONCAT(sub.pizza_name, " - ", 'Include ', sub.extra_topping, " - ", 'Exculude ', sub.exclusion_topping)
    END as ordered_pizza
FROM
(
SELECT 
	a.order_id,
    a.row_num,
    a.customer_id,
    d.pizza_name,
    GROUP_CONCAT(DISTINCT b.topping_name) AS exclusion_topping,
    GROUP_CONCAT(DISTINCT c.topping_name) AS extra_topping
FROM 
	pizza_runner.customer_orders_row a
LEFT JOIN
	pizza_runner.pizza_recipies_row b
ON a.exclusions = b.topping_id
LEFT JOIN
	pizza_runner.pizza_recipies_row c
ON a.extras = c.topping_id
LEFT JOIN
	pizza_runner.pizza_names d
ON a.pizza_id = d.pizza_id
GROUP BY
	a.order_id,
    a.row_num,
    a.customer_id,
    d.pizza_name
    ) sub
;



