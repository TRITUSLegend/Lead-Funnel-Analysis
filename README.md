# Lead Funnel Analysis: from conversion data to product recommendations

**Question:** where do converting leads come from, and what should a CRM do about it?
**Data:** X Education Lead Scoring dataset (9,240 leads, 38.5% converted). **Stack:** PostgreSQL, SQL (CTEs, window functions), Streamlit, Plotly.
**North-star metric:** lead-to-customer conversion rate. The data has no timestamps, so this is a segmented conversion analysis, not a time-based funnel.

## Run it
```
./run.sh                    # loads Leads.csv into Postgres, builds the clean view, exports result tables
pip install -r requirements.txt
streamlit run app.py
```
`sql/01` load, `sql/02` clean view (fixes 'Select' placeholders and source case variants), `sql/03` all analysis queries, `sql/04` exports for the dashboard.

## Findings
| # | Finding | Evidence |
|---|---|---|
| 1 | Time on site is the strongest web signal | 15+ min: 68.7% vs under 5 min: 13.5% (web leads) |
| 2 | Olark Chat is high volume, low yield | 19.0% of leads, 12.6% of conversions, 25.5% rate |
| 3 | Complete profiles convert far better | 4 fields filled: 51.4% vs 0 fields: 10.7% |
| 4 | Occupation is a big divider | Working Professional 91.6%; not provided 13.8% |
| 5 | Email opt-out and bounces are dead ends | Do-not-email 16.1% vs 40.5%; bounced 8.0% |
| 6 | Reference/Welingak (92-99%) are not a scalable channel | All are sales-entered 'Lead Add Form' leads |
| 7 | A simple capture-time score concentrates value | Top 40% of web leads = 71.6% of conversions; bottom 20% = 2.9% |

## Recommendations (hypotheses to test, with success metrics)
1. **Hot-lead alerts.** Notify sales when a web lead passes ~15 min on site. 718 such leads are currently unconverted. *Metric:* conversion of the 15+ min segment; time-to-first-contact (needs instrumentation).
2. **Priority score and routing.** Route Q1-Q2 leads to calls, Q5 to automated nurture. *Metric:* calls per conversion; conversion in Q1-Q2 after rollout.
3. **Qualify in chat.** Add occupation and goal questions to the Olark chat flow before handoff. *Metric:* chat-to-qualified rate.
4. **Progressive profiling.** Ask for occupation/specialization earlier. *Test:* A/B test the form, since completeness may reflect intent rather than cause conversion. *Metric:* conversion and form drop-off.
5. **Email hygiene.** Validate emails at capture and offer SMS/WhatsApp where email opt-out is set. *Metric:* bounce rate, reachable-lead share.

## Limitations
Observational data; correlation is not causation. Sales-assigned fields (lead quality, tags, last activity) are excluded from the score to avoid outcome leakage. The score is coarse, rule-based and in-sample, so it is directional, not a validated model.
