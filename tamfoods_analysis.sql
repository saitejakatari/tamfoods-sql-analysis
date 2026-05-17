-- ============================================================
-- TamFoods Analysis — April 2026
-- Author: Sai Teja Katari
-- 
-- Prerequisites: Run tamfoods.sql first to load the data.
-- ============================================================


-- ========== Stage 2: Profile ==========

--======================================================
-- Sanity check 1: total order count (should be 200)
--======================================================
-- Verifying Number of orders in the dataset
-- From order's table
SELECT
    COUNT(*)
FROM orders;

--======================================================
-- Sanity check 2: total restaurant count (should be 12)
--======================================================
-- Verifying Number of restaurant's in the dataset
-- From restaurant's table
SELECT
    COUNT(*)
FROM restaurants;

--======================================================
-- Sanity check 3: date range of orders (should be Apr 1 to Apr 30)
--======================================================
-- Finding the period of dataset to understand weather its 
-- from monthly, quarterly, halfyearly or annual.
SELECT
    MIN(order_date) AS starting_date,
    MAX(order_date) AS ending_date
FROM orders;
-- verified that the dataset is from Apr 01, 2026 to Apr 30, 2026

--======================================================
-- Sanity check 4: number of unique cuisines (should be 4)
--======================================================
-- Finding number of cuisines in the dataset
SELECT
    COUNT(DISTINCT r.cuisine) AS cuisines
FROM restaurants AS r;


-- ========== Stage 3: Core Analysis ==========

--======================================================
-- Q1: Total revenue and order count for April 2026
--======================================================
-- Finding total revenue and order count helps how business run in the month
SELECT
    SUM(order_value) AS total_revenue,
    COUNT(order_id) AS no_of_orders
FROM orders;

--======================================================
-- Q2: Top 5 restaurants by total revenue
--======================================================
-- This shows the top performing restaurants by revenue
SELECT
    r.restaurant_name,
    r.area,
    r.cuisine,
    SUM(o.order_value) AS total_revenue
FROM restaurants AS r
JOIN orders AS o
    ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_name, r.area, r.cuisine
ORDER BY total_revenue DESC
LIMIT 5;

--======================================================
-- Q3: Restaurants with zero orders (anti-join pattern)
--======================================================
-- Surfaces any restaurant on the platform that didn't receive
-- a single order in April 2026. Uses the LEFT JOIN + IS NULL
-- anti-join pattern.
-- Expected: Madras Halwa Co (newly opened Dec 2025, Sweets category)
SELECT
    r.restaurant_name
FROM restaurants AS r
LEFT JOIN orders AS o
    ON r.restaurant_id = o.restaurant_id
WHERE o.order_id IS NULL;

--======================================================
-- Q4: Revenue and order count by cuisine
--======================================================
-- Aggregate revenue and order volume per cuisine to identify 
-- which cuisines are driving most of TamFoods' business.
-- NOTE: Sweets cuisine is silently missing here due to INNER JOIN 
-- (Madras Halwa Co has zero orders). See Q3 for the gap. 
SELECT
    r.cuisine,
    SUM(o.order_value) AS total_revenue_by_cuisine,
    COUNT(o.order_id) AS no_of_orders
FROM restaurants AS r
JOIN orders AS o
    ON r.restaurant_id = o.restaurant_id
GROUP BY r.cuisine
ORDER BY total_revenue_by_cuisine DESC;

--======================================================
-- Q5: Cuisine availability gaps by area (2D crosstab)
--======================================================
-- For each area, what cuisines are present and
-- how much revenue does each generate?
SELECT
    r.area,
    r.cuisine,
    SUM(o.order_value) AS total_revenue_by_area,
    COUNT(o.order_id) AS no_of_orders_by_cuisine
FROM restaurants AS r
JOIN orders AS o
    ON r.restaurant_id = o.restaurant_id
GROUP BY r.area, r.cuisine
ORDER BY r.area ASC, total_revenue_by_area DESC;

-- ============================================================
-- Q6: Customer tier value — total vs per-customer
-- ============================================================
-- Compares each tier by total revenue AND by per-customer revenue.
-- 
-- WHY BOTH METRICS: Looking at total revenue alone can mislead — 
-- a tier with many customers will always look biggest. The real 
-- question is whether each individual customer in that tier is 
-- worth more. Computing both side-by-side prevents that trap.
-- 
-- TECHNIQUE: Three aggregations in one query:
--   1. SUM(order_value) for total revenue
--   2. COUNT(DISTINCT customer_id) for unique customers (not orders!)
--   3. Division of (1) by (2) for per-customer average, rounded to 2
SELECT
    customer_tier,
    SUM(order_value) AS total_revenue,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(order_value)/COUNT(DISTINCT customer_id), 2) AS avg_revenue_per_customer
FROM orders
GROUP BY customer_tier
ORDER BY total_revenue DESC;

-- ========== Stage 4: Stretch Queries ==========

--======================================================
-- S1: Worst-rated restaurants (with statistical credibility threshold)
--     Filter: avg rating < 4.0 AND at least 10 orders to avoid one-bad-review noise
--======================================================
SELECT
    r.restaurant_name,
    r.area,
    COUNT(o.order_id) AS order_count,
    ROUND(AVG(o.customer_rating), 2) AS avg_customer_rating
FROM restaurants AS r
JOIN orders AS o
    ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_name, r.area
HAVING avg_customer_rating < 4.0 AND COUNT(o.order_id)>=10
ORDER BY avg_customer_rating ASC;

--======================================================
-- S2: Slow delivery investigation (areas with avg delivery > 35 min)
--     Hypothesis check: are Velachery's bad ratings caused by slow delivery?
--======================================================
SELECT
    r.area,
    COUNT(o.order_id) AS no_of_orders,
    ROUND(AVG(o.delivery_time_min), 1) AS avg_delivery_time
FROM restaurants AS r
JOIN orders AS o
    ON r.restaurant_id = o.restaurant_id
GROUP BY r.area
ORDER BY avg_delivery_time DESC;
-- NOTE: Initial hypothesis was to filter for areas > 35 min average. 
-- Data showed no area exceeds that threshold, so switched to a 
-- ranking-based view. All areas are within a tight band.

--======================================================
-- S3: Newest Opened Restaurant
--======================================================
SELECT
    r.restaurant_name,
    r.area,
    r.cuisine,
    r.opened_date,
    SUM(o.order_value) AS total_revenue,
    COUNT(o.order_id) AS order_count,
    ROUND(AVG(o.customer_rating), 2) AS avg_rating
FROM restaurants AS r
LEFT JOIN orders AS o
    ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_name, r.area, r.cuisine, r.opened_date
ORDER BY r.opened_date DESC
LIMIT 1;

-- ============================================================
-- KEY FINDINGS
-- ============================================================
-- 1. Madras Halwa Co (Sweets, T. Nagar, opened Dec 2025) has 
--    received ZERO orders in April. Failed launch — needs 
--    partnerships team investigation.
-- 
-- 2. Cuisine-area supply gaps: South Indian (top cuisine at ₹51K) 
--    has no presence in Adyar and Velachery. Mylapore and T. Nagar 
--    have no Chinese or Fast Food.
-- 
-- 3. Customer tier inversion: Per-customer revenue DECREASES as 
--    tier rises (Bronze ₹1,353 → Platinum ₹1,074). Tier 
--    assignment criteria may need audit.
-- 
-- 4. S1 hypothesis (Velachery slow delivery causing bad ratings) 
--    was NOT supported — area-level delivery times are tightly 
--    clustered (30.6 to 34.6 min).
-- ============================================================