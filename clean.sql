-- =====================================================================
-- Swish Growth/Product Analyst project — Step 3b: clean the raw data
--
-- Run this in the BigQuery console's query editor AFTER Step 3a (all 12
-- raw CSVs uploaded as tables in the `raw` dataset). Creates a `clean`
-- dataset with analysis-ready tables that Power BI will connect to.
--
-- Before running: replace every `swish-growth-analyst` below with your actual
-- Google Cloud project ID (find it at the top of the BigQuery console,
-- or in the project dropdown).
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS `swish-growth-analyst.clean`;

-- ---------------------------------------------------------------------
-- 1. City lookup — resolves every messy spelling/casing back to city_id.
--    Built from the known variants; any city text NOT in this list will
--    come back NULL after the join in steps 2 and 3, which is exactly
--    how you'd catch a variant nobody anticipated.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.city_name_lookup` AS
SELECT * FROM UNNEST([
  STRUCT('Bengaluru' AS raw_text, 1 AS city_id), STRUCT('Bangalore', 1), STRUCT('bengaluru', 1),
  STRUCT('BANGALORE', 1), STRUCT('Banglore', 1),
  STRUCT('Mumbai', 2), STRUCT('mumbai', 2), STRUCT('MUMBAI', 2), STRUCT('Bombay', 2),
  STRUCT('Delhi NCR', 3), STRUCT('delhi ncr', 3), STRUCT('New Delhi', 3), STRUCT('Delhi', 3),
  STRUCT('Pune', 4), STRUCT('pune', 4), STRUCT('PUNE', 4),
  STRUCT('Hyderabad', 5), STRUCT('hyderabad', 5), STRUCT('Hyderbad', 5),
  STRUCT('Chennai', 6), STRUCT('chennai', 6), STRUCT('Madras', 6)
]);

-- ---------------------------------------------------------------------
-- 2. dim_customer — dedupe exact-duplicate rows, resolve city text to
--    city_id, parse the three mixed date formats, keep a missing
--    channel as NULL rather than guessing one.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.dim_customer` AS
SELECT DISTINCT
  c.customer_id,
  COALESCE(
    SAFE.PARSE_DATE('%Y-%m-%d', c.signup_date),
    SAFE.PARSE_DATE('%d-%m-%Y', c.signup_date),
    SAFE.PARSE_DATE('%m/%d/%Y', c.signup_date)
  ) AS signup_date,
  c.acquisition_channel_id,
  l.city_id AS home_city_id
FROM `swish-growth-analyst.raw.dim_customer` c
LEFT JOIN `swish-growth-analyst.clean.city_name_lookup` l
  ON TRIM(c.city_name_raw) = l.raw_text;

-- ---------------------------------------------------------------------
-- 3. fact_orders — same dedupe/city/date treatment, plus: an impossible
--    delivery time (<=0) is nulled out rather than deleting the whole
--    order, since the order itself is still real.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.fact_orders` AS
SELECT DISTINCT
  o.order_id,
  o.customer_id,
  COALESCE(
    SAFE.PARSE_DATE('%Y-%m-%d', o.order_date),
    SAFE.PARSE_DATE('%d-%m-%Y', o.order_date),
    SAFE.PARSE_DATE('%m/%d/%Y', o.order_date)
  ) AS order_date,
  l.city_id AS city_id,
  o.channel_id,
  o.kitchen_id,
  o.order_value,
  IF(o.delivery_time_minutes <= 0, NULL, o.delivery_time_minutes) AS delivery_time_minutes,
  o.promised_time_minutes,
  o.order_status,
  o.is_repeat_order
FROM `swish-growth-analyst.raw.fact_orders` o
LEFT JOIN `swish-growth-analyst.clean.city_name_lookup` l
  ON TRIM(o.city_name_raw) = l.raw_text;

-- ---------------------------------------------------------------------
-- 4. fact_order_items — drop zero-quantity lines (not a real item sold).
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.fact_order_items` AS
SELECT order_item_id, order_id, item_id, quantity, item_price,
       ROUND(quantity * item_price, 2) AS line_total
FROM `swish-growth-analyst.raw.fact_order_items`
WHERE quantity > 0;

-- ---------------------------------------------------------------------
-- 5. Reconciliation flag — orders where the header total disagrees with
--    its own line items. Flagged, not silently corrected: same practice
--    as the Hospitality project's documented Revenue discrepancy.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.fact_order_value_reconciliation` AS
SELECT
  o.order_id,
  o.order_value AS header_value,
  ROUND(SUM(i.line_total), 2) AS items_value,
  ABS(o.order_value - SUM(i.line_total)) > 1 AS is_mismatched
FROM `swish-growth-analyst.clean.fact_orders` o
JOIN `swish-growth-analyst.clean.fact_order_items` i USING (order_id)
GROUP BY o.order_id, o.order_value;

-- ---------------------------------------------------------------------
-- 6. fact_funnel_event — standardize step-name casing to the 5 canonical
--    values (a CASE/lookup, not INITCAP, so "Add to Cart" comes out
--    exactly right rather than "Add To Cart").
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.fact_funnel_event` AS
SELECT
  event_id, customer_id, event_date, city_id, channel_id, session_id,
  CASE LOWER(funnel_step)
    WHEN 'app open' THEN 'App Open'
    WHEN 'browse' THEN 'Browse'
    WHEN 'add to cart' THEN 'Add to Cart'
    WHEN 'checkout started' THEN 'Checkout Started'
    WHEN 'order placed' THEN 'Order Placed'
  END AS funnel_step,
  step_order
FROM `swish-growth-analyst.raw.fact_funnel_event`;

-- ---------------------------------------------------------------------
-- 7. Tables that were already clean at generation — copied through as-is
--    so Power BI can point at one single `clean` dataset for everything.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.dim_date`      AS SELECT * FROM `swish-growth-analyst.raw.dim_date`;
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.dim_city`      AS SELECT * FROM `swish-growth-analyst.raw.dim_city`;
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.dim_channel`   AS SELECT * FROM `swish-growth-analyst.raw.dim_channel`;
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.dim_kitchen`   AS SELECT * FROM `swish-growth-analyst.raw.dim_kitchen`;
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.dim_menu_item` AS SELECT * FROM `swish-growth-analyst.raw.dim_menu_item`;
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.dim_experiment` AS SELECT * FROM `swish-growth-analyst.raw.dim_experiment`;
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.fact_customer_monthly_activity` AS
  SELECT * FROM `swish-growth-analyst.raw.fact_customer_monthly_activity`;
CREATE OR REPLACE TABLE `swish-growth-analyst.clean.fact_experiment_results` AS
  SELECT * FROM `swish-growth-analyst.raw.fact_experiment_results`;

-- =====================================================================
-- Step 3c — verification queries. Run these after the above and check
-- the numbers against what's expected (from Swish_Raw_Data_Notes.md).
-- =====================================================================

-- Expect 0 — dedupe worked
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM `swish-growth-analyst.clean.fact_orders`;

-- Expect 0 — every city text variant was resolved
SELECT COUNT(*) AS unresolved_cities
FROM `swish-growth-analyst.clean.fact_orders` WHERE city_id IS NULL;

-- Expect 0 — no impossible delivery times remain
SELECT COUNT(*) AS bad_delivery_times
FROM `swish-growth-analyst.clean.fact_orders` WHERE delivery_time_minutes <= 0;

-- Expect roughly 2,900-3,000 (~4% of ~74,125 orders) — this is EXPECTED,
-- it's the flag working, not a bug. These orders are still usable; they're
-- just marked as unreliable on order_value specifically.
SELECT COUNTIF(is_mismatched) AS flagged_mismatched_orders
FROM `swish-growth-analyst.clean.fact_order_value_reconciliation`;

-- Expect exactly these 5 values, nothing else
SELECT DISTINCT funnel_step FROM `swish-growth-analyst.clean.fact_funnel_event`;
