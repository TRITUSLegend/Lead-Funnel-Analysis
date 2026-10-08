# Lead Funnel Analysis: from conversion data to CRM product recommendations

> **Which leads actually convert, and what should a CRM do about it?** An SQL-first analysis of 9,240 sales leads that ends in five testable product recommendations, each with a success metric, plus an interactive dashboard.

**Stack:** PostgreSQL · SQL (CTEs, window functions) · Python · Streamlit · Plotly  
**North-star metric:** lead-to-customer conversion rate (38.5% overall)

[Sources tab of the dashboard](https://claude.ai/chat/docs/dashboard-sources.png)

---

## TL;DR

| Finding | Evidence |
|---|---|
| Time on site is the strongest web signal | Web leads with 15+ min on site convert at **68.7%** vs **13.5%** under 5 min |
| **718** hot web leads are still open | 15+ min on site, not yet converted: a ready follow-up pool |
| Olark Chat is high volume, low yield | **19.0%** of leads but **12.6%** of conversions (25.5% rate) |
| Complete profiles convert far better | 4 of 4 fields filled: **51.4%** vs **10.7%** with none |
| A simple score concentrates value | Top 40% of web leads hold **71.6%** of conversions; the bottom 20% hold **2.9%** |

## Product recommendations

Each one is a hypothesis with a way to measure it, not a claim that it will work.

| # | Recommendation | Why (evidence) | Success metric |
|---|---|---|---|
| 1 | **Hot-lead alerts:** notify sales when a web lead passes ~15 min on site | 68.7% conversion in that band; 718 leads still open | Conversion of the 15+ min segment; time-to-first-contact (needs instrumentation) |
| 2 | **Priority score and routing:** calls for the top two quintiles, automated nurture for the bottom | Top 40% hold 71.6% of conversions | Calls per conversion; conversion in Q1-Q2 after rollout |
| 3 | **Qualify inside chat:** ask occupation and goal before handoff | Olark: 19% of leads, 12.6% of conversions | Chat-to-qualified rate |
| 4 | **Progressive profiling:** ask for occupation and specialization earlier | 4 fields filled: 51.4% vs 10.7%; occupation not provided: 13.8% vs working professional: 91.6% | Form conversion and drop-off, via an **A/B test** (completeness may reflect intent rather than cause conversion) |
| 5 | **Email hygiene:** validate at capture, offer SMS/WhatsApp when email is opted out | Do-not-email 16.1% vs 40.5%; bounced 8.0% | Bounce rate; share of reachable leads |

[Priority score tab of the dashboard](https://claude.ai/chat/docs/dashboard-priority.png)

## Analysis decisions worth knowing about

These are the choices that stop the numbers from misleading:

- **Sales-entered leads are separated out.** All `Reference` and `Welingak Website` leads come from the sales-entered `Lead Add Form` and convert at 92–99%. They are pre-qualified, not a channel to scale, so the engagement and scoring analyses use **web-originated leads only**.
- **No outcome leakage.** Fields sales assigns after contact (`lead_quality`, `tags`, `last_activity`) are excluded from the score. They are shown for follow-up playbooks, not prediction.
- **Dirty data fixed in one place.** The `leads` view turns the dropdown placeholder `Select` into `NULL` and collapses source case variants (`google` vs `Google`).
- **Not a time-based funnel.** The dataset has no timestamps, so this is conversion by segment. Response-time questions need new instrumentation, which is itself recommendation 1's metric.
- **Small segments are filtered.** The last-activity and occupation queries hide categories with fewer than 100 leads.

## Project structure

```text
leadfunnel/
├── Leads.csv               # public lead dataset (9,240 rows, 37 columns)
├── sql/
│   ├── 01_schema_load.sql  # raw table + COPY load
│   ├── 02_clean_view.sql   # `leads` view: cleaning and derived bands
│   ├── 03_analysis.sql     # all analysis queries (Q1-Q10), annotated
│   └── 04_export.sql       # result tables written to outputs/
├── outputs/                # CSVs the dashboard reads
├── app.py                  # Streamlit dashboard (4 tabs)
├── run.sh                  # load -> clean -> export
├── docs/                   # screenshots
└── requirements.txt
```

## Run it

Needs **Python 3.10+** and a local PostgreSQL installation (`psql` and `createdb` on your PATH).

```bash
python -m venv .venv
source .venv/bin/activate          # Windows Git Bash: source .venv/Scripts/activate

pip install -r requirements.txt

# If your Postgres is not the default local setup, set these first:
# export PGUSER=postgres PGHOST=localhost PGPORT=5432 PGPASSWORD=...

./run.sh                           # creates DB `leadfunnel`, loads data, builds the view, exports CSVs
streamlit run app.py               # add --server.address localhost to keep it local-only
```

The dashboard reads only `outputs/*.csv`, so you only need to rerun `run.sh` if the data or SQL changes.

To explore the queries directly:

```bash
psql -d leadfunnel -f sql/03_analysis.sql
```

**Check your run:** you should see **9,240 leads**, **3,561 converted (38.5%)**, the **15+ min band at 68.7%**, and priority quintiles of **76.7 / 44.9 / 24.2 / 19.2 / 4.9%**.

## Limitations

- **Observational data.** Everything here is correlation. The recommendations are meant to be tested, especially the profiling change, which needs an A/B test.
- **The score is coarse, rule-based and in-sample.** It is directional evidence, not a validated model. A fair next step is a holdout split or logistic regression to compare.
- **One company's data.** Rates will differ elsewhere; the method transfers, the numbers don't.

## What I'd do next

- Add timestamps or event instrumentation to measure response time and time-to-conversion.
- Validate the score on a holdout set and compare it with a simple logistic model.
- Turn recommendation 4 into a full experiment plan covering sample size, guardrail metrics, and duration.
- Write a PRD for the hot-lead alert feature.

## Data and credits

The dataset is a publicly available lead-scoring case-study dataset (X Education); I do not own it. Analysis, SQL, dashboard, and recommendations are my own.

**Author:** Aditya Raj Kar · [GitHub](https://github.com/TRITUSLegend) · [LinkedIn](https://www.linkedin.com/in/adityarajkar/)
