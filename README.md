# An AI SQL assistant got 10 of 10 business questions right, and half of them only after it asked what I meant

*Self-directed project on a synthetic dataset (a modelled 10-minute food-delivery business, "Swish"). Not affiliated with any real company.*

## Business problem

A growth team at a delivery business gets a steady stream of questions: how many orders, how is retention in one city, did the experiment work. If an AI assistant writes the SQL, two risks follow. The SQL can look right and be wrong. And the same question can get two different answers when a metric is not clearly defined.

Question I tested: **can an AI assistant give answers an analyst can trust, and what makes it fail?**

## Executive summary

- I gave a Claude assistant only three things: the real table and column list, a written metric definitions file, and the script that built the dataset.
- I asked it 10 business questions that I had already verified in Power BI and BigQuery.
- **All 10 final answers matched.** None needed me to edit the SQL.
- **5 of the 10 questions got a question back first**, because my definitions file did not say enough. The assistant asked instead of guessing.
- The most useful result was not the score. It was finding three places where **my own definitions and dashboard were incomplete or wrong**.

## Insights

**1. The gaps were in my rules, not in the assistant's SQL.**
On 5 questions the assistant asked before answering. My definitions file had left something out each time: what "growth" means, what format the months are stored in, how to find a customer's city. I added each rule to the file. A new analyst would have hit the same 5 gaps.

**2. The assistant found an error in my own dashboard.**
Chennai had 789 orders in Q1 2026, but my Power BI report showed 798. The report compared Q2 (91 days) with the 91 days before it, which starts on 31 December, not with true Q1 (90 days). The 9 extra orders were from 31 December. I rebuilt the comparison to use the previous quarter and corrected all six cities. Chennai's growth moved from +51.9% to +53.6%, and Bengaluru's from +13.6% to +14.6%. The ranking did not change. I now define "quarter" in the metric file.

**3. One metric name can hide two ways of calculating it.**
Month+1 retention is the share of new customers who order again the next month. New customers are grouped by the month they joined. My definitions file said to calculate it for each month's group separately. My Power BI report, for city and channel, joins all the groups into one number. For Bengaluru customers from Paid Social, 267 of 1,079 came back, which is 24.7%. The assistant asked which way I meant. I chose one combined number and wrote that into the file.

## Recommendation

| Action | Owner | Expected impact | Metric to track |
|---|---|---|---|
| Keep one written file of metric definitions (quarter, growth, active customer, retention). Use it for both analysts and the assistant | Analytics lead | Every metric is calculated the same way, so fewer conflicting numbers (my expectation, not measured) | Questions answered with no clarification needed. Today: 5 of 10 needed one |
| Keep a fixed set of questions with checked answers. Re-run it after every change | Analyst who owns the assistant | Wrong answers are caught before a stakeholder sees them | Correct answers out of 10 per run |
| When a number does not match an old log, find out why before choosing one | Anyone reviewing the numbers | Old or differently calculated numbers are found early | Mismatches found and explained |

## Caveats

- I wrote both the rules and the answers I checked against. Someone else might spot gaps that I cannot.
- Some of the 10 questions are easy, such as counting orders from one table. The harder ones are the real test: joining several tables, retention by city and channel, and the experiment result.
- I ran only 3 of the 10 questions a second time. All 3 gave the same answer.
- The data is synthetic. Business conclusions about Swish are not real findings.

---

## Appendix: how it was built (technical detail)

- **Assistant:** a Claude Project with three files: `Swish_Schema.md` (table and column list from BigQuery INFORMATION_SCHEMA), `Swish_Metric_Definitions.md`, and `clean.sql` (the cleaning script).
- **Rules given to it:** BigQuery Standard SQL on one dataset; use only listed tables and columns; say when something is missing; show joins and why; never invent a metric definition.
- **Test method:** each question in a fresh chat; SQL run in BigQuery unedited; result compared to the verified number; failures and gaps logged.
- **Files:** `Swish_SQL_Assistant_Scorecard.md` (10 questions, results, failure log), schema, definitions, cleaning script.
