"""Lead funnel dashboard. Reads the CSVs written by sql/04_export.sql (run ./run.sh first)."""
from pathlib import Path
import pandas as pd
import plotly.graph_objects as go
import streamlit as st

OUT = Path(__file__).parent / "outputs"
ACCENT, MUTED = "#2563EB", "#B8C0CC"
st.set_page_config(page_title="Lead Funnel Analysis", layout="wide")

def load(name): return pd.read_csv(OUT / f"{name}.csv")

def bar(df, x, y, title, highlight=None, ytitle="Conversion rate (%)", horizontal=False):
    colors = [ACCENT if (highlight is None or v in highlight) else MUTED for v in df[x]]
    fig = go.Figure(go.Bar(x=df[y] if horizontal else df[x], y=df[x] if horizontal else df[y],
                           marker_color=colors, orientation="h" if horizontal else "v",
                           text=df[y].round(1).astype(str) + "%", textposition="outside",
                           hovertemplate="%{x}: %{y}<extra></extra>" if not horizontal else "%{y}: %{x}<extra></extra>"))
    fig.update_layout(title=title, height=340, margin=dict(l=10, r=10, t=50, b=10),
                      showlegend=False, plot_bgcolor="rgba(0,0,0,0)", paper_bgcolor="rgba(0,0,0,0)",
                      yaxis=dict(title=ytitle if not horizontal else None, gridcolor="rgba(128,128,128,.2)"),
                      xaxis=dict(title=None if not horizontal else ytitle,
                                 gridcolor="rgba(128,128,128,.2)" if horizontal else None))
    if horizontal: fig.update_yaxes(autorange="reversed")
    return fig

k = load("kpis").iloc[0]
src, eng, act, comp, quint = (load(n) for n in
    ["by_source", "by_engagement", "by_last_activity", "by_completeness", "priority_quintiles"])

st.title("Where do converting leads come from?")
st.caption("X Education lead dataset (9,240 leads). North-star metric: lead-to-customer conversion rate. "
           "Observational data - patterns are correlations, to be validated with experiments.")

c1, c2, c3 = st.columns(3)
c1.metric("Leads", f"{int(k.leads):,}")
c2.metric("Converted", f"{int(k.converted):,}")
c3.metric("Conversion rate", f"{k.conv_rate_pct}%")

t1, t2, t3, t4 = st.tabs(["Sources", "Engagement", "Lead capture", "Priority score"])

with t1:
    a, b = st.columns(2)
    a.plotly_chart(bar(src, "lead_source", "conv_rate_pct", "Conversion rate by source",
                       highlight=["Olark Chat"]), width="stretch")
    long = src.melt(id_vars="lead_source", value_vars=["pct_of_leads", "pct_of_conversions"])
    fig = go.Figure()
    for v, name, col in [("pct_of_leads", "% of leads", MUTED), ("pct_of_conversions", "% of conversions", ACCENT)]:
        d = long[long.variable == v]
        fig.add_bar(x=d.lead_source, y=d.value, name=name, marker_color=col)
    fig.update_layout(title="Share of leads vs share of conversions", barmode="group", height=340,
                      margin=dict(l=10, r=10, t=50, b=10), legend=dict(orientation="h", y=1.15),
                      plot_bgcolor="rgba(0,0,0,0)", paper_bgcolor="rgba(0,0,0,0)",
                      yaxis=dict(title="%", gridcolor="rgba(128,128,128,.2)"))
    b.plotly_chart(fig, width="stretch")
    st.info("Olark Chat is 19% of leads but 12.6% of conversions. 'Reference' and 'Welingak Website' convert "
            "at 92-99% but are all sales-entered (Lead Add Form), so treat them as pre-qualified, not a scalable channel.")

with t2:
    a, b = st.columns(2)
    a.plotly_chart(bar(eng, "engagement_band", "conv_rate_pct",
                       "Conversion by time on site (web leads)", highlight=["3. 15+ min"]), width="stretch")
    b.plotly_chart(bar(act, "last_activity", "conv_rate_pct", "Conversion by last activity",
                       horizontal=True, highlight=["SMS Sent"]), width="stretch")
    st.info("Web leads with 15+ min on site convert at ~69% vs ~14% under 5 min. 718 such leads are still open: "
            "a ready follow-up pool. Last activity is recorded after contact, so use it for playbooks, not scoring.")

with t3:
    st.plotly_chart(bar(comp, "fields_filled", "conv_rate_pct",
                        "Conversion by profile fields filled at capture (0-4, web leads)",
                        highlight=[4]), width="stretch")
    st.info("Leads with all 4 fields (occupation, specialization, city, how heard) convert at ~51% vs ~11% with none. "
            "Filling fields signals intent, so the causal effect needs an A/B test (see README).")

with t4:
    q = quint.copy(); q["priority_quintile"] = "Q" + q.priority_quintile.astype(str)
    a, b = st.columns(2)
    a.plotly_chart(bar(q, "priority_quintile", "conv_rate_pct", "Conversion by priority quintile",
                       highlight=["Q1", "Q2"]), width="stretch")
    q["cum"] = q.cum_pct_of_conversions
    b.plotly_chart(bar(q.assign(conv_rate_pct=q.cum), "priority_quintile", "conv_rate_pct",
                       "Cumulative % of conversions captured", highlight=["Q1", "Q2"],
                       ytitle="% of conversions"), width="stretch")
    st.info("Rule-based score from capture-time signals only. Top 40% of web leads hold ~72% of conversions; "
            "bottom 20% hold ~3%. In-sample and coarse: directional, not a validated model.")
    st.dataframe(quint, hide_index=True)
