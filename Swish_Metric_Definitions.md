# Swish metric definitions (source of truth for the SQL assistant)

Dataset: `swish-growth-analyst.clean` (BigQuery Standard SQL). Use only tables/columns in the schema file.

- Valid `fact_orders.order_status` values (verified): Delivered, Refunded, Cancelled.
- **Order Count** = count of orders with `order_status = 'Delivered'` only.
- **Revenue** = sum of order value for Delivered orders only.
- **AOV** = Revenue / Order Count (Delivered only).
- **Funnel Conversion** = Order Placed events / App Open events, from `fact_funnel_event` (event counts, not distinct sessions or customers).
- Valid `fact_funnel_event.funnel_step` values in order (verified): App Open (1), Browse (2), Add to Cart (3), Checkout Started (4), Order Placed (5).
- **Month+1 Retention** = customers active at `months_since_first_order` = 1 divided by customers at `months_since_first_order` = 0, per `cohort_month`.
- `fact_customer_monthly_activity` has rows only for active months. A missing month means inactive, not zero.
- **Active Customers** (month) = distinct `customer_id` in `fact_customer_monthly_activity` with `is_active = TRUE` for that `activity_month` (format 'YYYY-MM'). `cohort_month` also uses 'YYYY-MM'.
- **Month+1 Retention by city and channel** = pooled across all cohorts (not per cohort). City = `dim_customer.home_city_id`. Channel = `dim_customer.acquisition_channel_id` (cast to INT64 to join `dim_channel`). Known caveat: the latest cohort has no complete Month+1 yet and slightly lowers the pooled rate.
- **Quarter** = calendar quarter (Q1 = Jan to Mar, Q2 = Apr to Jun). **Growth** = percentage change.
- **Experiment conversion/retention rate** = average of `fact_experiment_results.outcome_metric_value` (0/1 flag) per `variant` ('Control', 'Treatment'). If `dim_experiment.primary_metric` is 'AOV', the average is in rupees instead.

Check value: total delivered orders = 67,584 (matches Power BI).
Funnel check value: Order Placed 68,081 / App Open 463,308 = 14.69% (event-count basis).
