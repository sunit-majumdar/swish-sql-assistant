# Swish SQL Assistant: scorecard

10 business questions with answers I had already verified in Power BI or BigQuery. Each question was run in a fresh chat inside the assistant's Project. The SQL was run in BigQuery without editing and the result compared to the verified answer.

| # | Question | Verified answer | Matched? | Asked a clarification first? | Same on re-run? |
|---|---|---|---|---|---|
| 1 | How many delivered orders are there in total? | 67,584 | Yes | No | Not re-run |
| 2 | How many orders are there across all statuses, and how many were not delivered? | 74,125 total; 6,541 not delivered (about 8.8%) | Yes | No | Not re-run |
| 3 | What is total revenue and AOV for delivered orders? | Revenue 2,66,93,686; AOV 394.97 | Yes | No | Not re-run |
| 4 | How many active customers were there in June 2026? | 2,255 | Yes | Yes (definition and month format) | Not re-run |
| 5 | What is the Month+1 retention rate for the August 2026 cohort? | 56.8% (681 / 1,199) | Yes | Yes (cohort month format) | Not re-run |
| 6 | What is the step-to-step conversion rate between each funnel step, all history? | 60.1%, 52.2%, 72.1%, 65.0%; end-to-end 14.7% | Yes | No | Not re-run |
| 7 | How many delivered orders were placed from 1 July to 15 September 2026? | 16,860 | Yes | No | Not re-run |
| 8 | Which city had the highest order growth in Q2 2026 vs Q1 2026, and what was it? | Chennai, +53.6% (1,212 vs 789) | Yes | Yes (growth and quarter definitions) | Yes |
| 9 | What is Month+1 retention for customers from Bengaluru acquired through Paid Social? | 24.7% (267 / 1,079) | Yes | Yes (city field, pooled or per cohort) | Yes |
| 10 | What was the conversion rate for control vs treatment in the Checkout One-Tap Reorder experiment? | 8.96% vs 16.48% (32/357 vs 59/358) | Yes | Yes (what the outcome column holds) | Yes |

**Result: 10 of 10 matched. 5 of 10 needed a clarification first. 3 re-run, all the same.**

## What each question tests
- 2, 3: filter and aggregation choices. Q3 needs the delivered-only rule for both revenue and AOV.
- 4, 5: month columns stored as text; retention as a ratio of two counts.
- 6: comparing each funnel step to the one before it.
- 7: date filtering.
- 8: calendar quarters and percentage growth.
- 9: joins to customer, city and channel tables, with a type cast on the channel ID.
- 10: a metric that was not defined in the files. The right behaviour was to ask.

## Failure log
No wrong final answers. These are the gaps the test found:

| Q | What happened | How it was found | Fix |
|---|---|---|---|
| 8, 9 | My definitions file said retention is per cohort. My Power BI measure pools all cohorts for city and channel. | The assistant asked which one I meant. | Added the pooled rule to the definitions file. |
| 8 | "Growth" and "quarter" were not defined. | The assistant asked. | Defined them: calendar quarters, percentage change. |
| 8 | The assistant's Chennai Q1 count (789) did not match my dashboard (798). The dashboard compared Q2 with the 91 days before it, which includes 31 December. | I compared the assistant's result to the dashboard. | Rebuilt the City Expansion comparison to use the previous quarter. All six cities corrected. Ranking unchanged. |
| 4, 5, 10 | Month formats and the meaning of the experiment outcome column were not written down. | The assistant asked. | Added both to the definitions file. |
