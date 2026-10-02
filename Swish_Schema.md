# Swish BigQuery schema (dataset `swish-growth-analyst.clean`)

Source: INFORMATION_SCHEMA.COLUMNS output run on 2 Oct 2026. This is the only list of valid tables and columns. Anything not listed here does not exist.

## Dimensions
- city_name_lookup: raw_text STRING, city_id INT64
- dim_channel: channel_id INT64, channel_name STRING, channel_type STRING
- dim_city: city_id INT64, city_name STRING, tier STRING, region STRING, launch_date DATE
- dim_customer: customer_id INT64, signup_date DATE, acquisition_channel_id FLOAT64, home_city_id INT64
- dim_date: date_id INT64, calendar_date DATE, day_name STRING, week_number INT64, month INT64, month_name STRING, quarter INT64, year INT64, day_type STRING, is_current_quarter BOOL
- dim_experiment: experiment_id INT64, experiment_name STRING, start_date DATE, end_date DATE, primary_metric STRING, hypothesis STRING
- dim_kitchen: kitchen_id INT64, city_id INT64, kitchen_name STRING
- dim_menu_item: item_id INT64, item_name STRING, category STRING, price_tier STRING

## Facts
- fact_orders: order_id INT64, customer_id INT64, order_date DATE, city_id INT64, channel_id FLOAT64, kitchen_id INT64, order_value FLOAT64, delivery_time_minutes INT64, promised_time_minutes INT64, order_status STRING, is_repeat_order BOOL
- fact_order_items: order_item_id INT64, order_id INT64, item_id INT64, quantity INT64, item_price FLOAT64, line_total FLOAT64
- fact_order_value_reconciliation: order_id INT64, header_value FLOAT64, items_value FLOAT64, is_mismatched BOOL
- fact_customer_monthly_activity: customer_id INT64, activity_month STRING, orders_in_month INT64, is_active BOOL, cohort_month STRING, months_since_first_order INT64
- fact_funnel_event: event_id INT64, customer_id INT64, event_date DATE, city_id INT64, channel_id INT64, session_id INT64, funnel_step STRING, step_order INT64
- fact_experiment_results: experiment_id INT64, customer_id INT64, variant STRING, outcome_metric_value FLOAT64, entry_date DATE

## Facts about the schema (from the output, not assumptions)
- fact_orders has `order_date` (DATE). It has NO `date_id`. To use dim_date, join on `fact_orders.order_date = dim_date.calendar_date`.
- `fact_orders.channel_id` and `dim_customer.acquisition_channel_id` are FLOAT64 (nullable), while `dim_channel.channel_id` is INT64.
- `activity_month` and `cohort_month` are STRING, not DATE.
- The exact values of `order_status` and `funnel_step` are not in this file. Do not guess them; ask for a SELECT DISTINCT.
