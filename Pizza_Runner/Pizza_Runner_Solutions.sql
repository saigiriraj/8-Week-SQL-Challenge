-- TABLES
-- runners
-- customer_orders
-- runner_orders
-- pizza_names
-- pizza_recipes
-- pizza_toppings

-- A. PIZZA METRICS

-- A.1 - How many pizzas were ordered?
SELECT COUNT(pizza_id) AS PIZZA_ORDERED FROM pizza_runner.customer_orders;

-- A.2 - How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM pizza_runner.customer_orders;

-- Clean runner_orders
WITH clean_runner_orders AS (
SELECT
	order_id, runner_id, pickup_time,
    replace(distance, 'km', '') AS distance,
    replace(replace(replace(replace(replace(duration, ' ', ''), 'minutes', ''), 'minute', ''), 'mins', ''), 'min', '') AS duration,
    CASE WHEN cancellation is NULL or cancellation = 'null' or cancellation = '' THEN 0 ELSE 1 END AS cancellation
FROM
	pizza_runner.runner_orders
)

-- A.3 - How many successful orders were delivered by each runner?
SELECT COUNT(*) FROM clean_runner_orders
WHERE cancellation = 0;

-- A.4 - How many of each type of pizza was delivered?
WITH clean_runner_orders AS (
SELECT
	order_id, runner_id, pickup_time,
    replace(distance, 'km', '') AS distance,
    replace(replace(replace(replace(replace(duration, ' ', ''), 'minutes', ''), 'minute', ''), 'mins', ''), 'min', '') AS duration,
    CASE WHEN cancellation is NULL or cancellation = 'null' or cancellation = '' THEN 0 ELSE 1 END AS cancellation
FROM
	pizza_runner.runner_orders
)
SELECT 
	a.pizza_id,
    COUNT(*) AS total_deliveried
FROM
	pizza_runner.customer_orders a
INNER JOIN
(
SELECT DISTINCT order_id FROM clean_runner_orders WHERE cancellation = 0
)b
ON a.order_id = b.order_id
GROUP BY a.pizza_id;


-- A.5 - How many Vegetarian and Meatlovers were ordered by each customer?
-- Based on toppings table pizza id: 1 -> Meat and 2 -> Veg
SELECT 
	customer_id,
    SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS Meatlovers,
    SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS Vegetarian
FROM pizza_runner.customer_orders
GROUP BY customer_id;

-- A.6 - What was the maximum number of pizzas delivered in a single order?
WITH clean_runner_orders AS (
SELECT
	order_id, runner_id, pickup_time,
    replace(distance, 'km', '') AS distance,
    replace(replace(replace(replace(replace(duration, ' ', ''), 'minutes', ''), 'minute', ''), 'mins', ''), 'min', '') AS duration,
    CASE WHEN cancellation is NULL or cancellation = 'null' or cancellation = '' THEN 0 ELSE 1 END AS cancellation
FROM
	pizza_runner.runner_orders
)
SELECT MAX(final.pizzas_delivered) AS max_pizzas_delivered
FROM (
SELECT 
	a.order_id,
    COUNT(a.pizza_id) AS pizzas_delivered
FROM
	pizza_runner.customer_orders a
INNER JOIN
(
SELECT DISTINCT order_id FROM clean_runner_orders WHERE cancellation = 0
)b
ON a.order_id = b.order_id
GROUP By order_id
)final;

-- A.7 - For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH clean_runner_orders AS ( 
SELECT
	order_id, runner_id, pickup_time,
    replace(distance, 'km', '') AS distance,
    replace(replace(replace(replace(replace(duration, ' ', ''), 'minutes', ''), 'minute', ''), 'mins', ''), 'min', '') AS duration,
    CASE WHEN cancellation is NULL or cancellation = 'null' or cancellation = '' THEN 0 ELSE 1 END AS cancellation
FROM
	pizza_runner.runner_orders
)
SELECT 
	a.customer_id,
    SUM(CASE WHEN a.exclusions IN ('null', '') OR a.extras IN('null', '')  THEN 1 ELSE 0 END) AS no_change_order,
    SUM(CASE WHEN a.exclusions NOT IN ('null', '') AND a.extras NOT IN('null', '')  THEN 1 ELSE 0 END) AS change_order
FROM
	pizza_runner.customer_orders a
INNER JOIN
(
SELECT DISTINCT order_id FROM clean_runner_orders WHERE cancellation = 0
)b
ON a.order_id = b.order_id
GROUP BY a.customer_id
;