"""Web dashboard over the bi.* reporting views.

A code-first companion to the Power BI report described in powerbi/connection_guide.md:
the same five pages, reading the same views, so the analytics layer can be demoed
without Power BI Desktop.

    AW_DATABASE_URL=postgresql+psycopg2://user:pass@host:5432/adventureworks \
        streamlit run dashboard/app.py
"""
from __future__ import annotations

import os
from decimal import Decimal

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from sqlalchemy import create_engine, text

DATABASE_URL = os.getenv("AW_DATABASE_URL", "postgresql+psycopg2://postgres@localhost:5432/adventureworks")

TEAL = "#0f766e"
TEAL_LIGHT = "#5eead4"
AMBER = "#f59e0b"
ROSE = "#e11d48"
SLATE = "#64748b"
GRID = "#e2e8f0"
SEGMENT_COLORS = {
    "Champions": "#0f766e",
    "Loyal": "#14b8a6",
    "New": "#38bdf8",
    "Potential": "#a78bfa",
    "At Risk": "#f59e0b",
    "Lost": "#e11d48",
    "Others": "#94a3b8",
}

st.set_page_config(page_title="AdventureWorks BI", layout="wide")


@st.cache_resource
def engine():
    return create_engine(DATABASE_URL, future=True)


@st.cache_data(ttl=600)
def q(sql: str) -> pd.DataFrame:
    with engine().connect() as conn:
        df = pd.read_sql(text(sql), conn)
    # Postgres NUMERIC arrives as Decimal objects; convert those columns to floats for plotting.
    for col in df.columns:
        sample = df[col].dropna()
        if not sample.empty and isinstance(sample.iloc[0], Decimal):
            df[col] = df[col].astype(float)
    return df


def style(fig: go.Figure, height: int = 360) -> go.Figure:
    fig.update_layout(
        template="plotly_white",
        height=height,
        margin=dict(l=10, r=10, t=48, b=10),
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        font=dict(size=13, color="#0f172a"),
        title_font=dict(size=16),
        legend_title_text="",
    )
    fig.update_xaxes(gridcolor=GRID, title=None)
    fig.update_yaxes(gridcolor=GRID, title=None)
    return fig


def money(value: float) -> str:
    if abs(value) >= 1e6:
        return f"${value / 1e6:,.1f}M"
    if abs(value) >= 1e3:
        return f"${value / 1e3:,.0f}K"
    return f"${value:,.0f}"


def year_filter_sql(years: list[int], column: str = "year") -> str:
    return f"{column} IN ({', '.join(str(int(y)) for y in years)})" if years else "TRUE"


kpis = q("SELECT * FROM bi.vw_executive_kpis ORDER BY year, month")
all_years = sorted(kpis["year"].unique().tolist())

st.sidebar.title("AdventureWorks BI")
st.sidebar.caption("PostgreSQL `bi.*` views · 29/29 validation checks passing")
page = st.sidebar.radio(
    "Report page",
    ["Executive Summary", "Sales Performance", "Product Intelligence", "Customer Analytics", "Anomaly Report"],
)
years = st.sidebar.multiselect("Year", all_years, default=all_years)
complete_only = st.sidebar.toggle("Complete months only", value=True,
                                  help="Hide the trailing month when the data extract stops mid-month.")
year_sql = year_filter_sql(years)

# Month keys (year * 100 + month) to drop when "complete months only" is on.
incomplete = kpis.loc[~kpis["is_complete_month"], ["year", "month"]]
incomplete_keys = set((incomplete["year"] * 100 + incomplete["month"]).tolist()) if complete_only else set()


def drop_incomplete(df: pd.DataFrame) -> pd.DataFrame:
    return df[~(df["year"] * 100 + df["month"]).isin(incomplete_keys)]

# ---------------------------------------------------------------------------
if page == "Executive Summary":
    st.title("Executive Summary")
    df = kpis[kpis["year"].isin(years)]
    if complete_only:
        df = df[df["is_complete_month"]]
    df = df.assign(month_date=pd.to_datetime(dict(year=df["year"], month=df["month"], day=1)))
    latest = df.iloc[-1]

    c1, c2, c3, c4, c5 = st.columns(5)
    c1.metric("Revenue", money(df["total_revenue"].sum()))
    c2.metric("Orders", f"{int(df['total_orders'].sum()):,}")
    c3.metric("Avg Order Value", money(df["total_revenue"].sum() / df["total_orders"].sum()))
    c4.metric("Online Share", f"{100 * df['online_revenue'].sum() / df['total_revenue'].sum():.1f}%")
    yoy = latest["yoy_revenue_change_pct"]
    c5.metric(f"{latest['month_name'][:3]} {int(latest['year'])} vs LY",
              money(latest["total_revenue"]), f"{yoy:+.1f}% YoY" if pd.notna(yoy) else None)

    fig = go.Figure()
    fig.add_bar(x=df["month_date"], y=df["offline_revenue"], name="Reseller / offline", marker_color=TEAL)
    fig.add_bar(x=df["month_date"], y=df["online_revenue"], name="Online", marker_color=TEAL_LIGHT)
    fig.add_scatter(x=df["month_date"], y=df["total_revenue"].rolling(3).mean(), name="3-mo average",
                    line=dict(color=AMBER, width=3))
    fig.update_layout(barmode="stack", title="Monthly revenue by channel",
                      legend=dict(orientation="h", y=1.08, x=1, xanchor="right"))
    fig.update_yaxes(tickprefix="$")
    st.plotly_chart(style(fig, 400), use_container_width=True)

    left, right = st.columns(2)
    by_q = df.groupby(["year", "quarter"], as_index=False)["total_revenue"].sum()
    by_q["period"] = by_q["year"].astype(str) + " " + by_q["quarter"]
    fig = px.bar(by_q, x="period", y="total_revenue", title="Revenue by quarter", color_discrete_sequence=[TEAL])
    fig.update_yaxes(tickprefix="$")
    left.plotly_chart(style(fig), use_container_width=True)

    fig = px.line(df, x="month_date", y="avg_order_value", title="Average order value", markers=True,
                  color_discrete_sequence=[TEAL])
    fig.update_yaxes(tickprefix="$")
    right.plotly_chart(style(fig), use_container_width=True)

# ---------------------------------------------------------------------------
elif page == "Sales Performance":
    st.title("Sales Performance")
    sales = q(f"SELECT * FROM bi.vw_sales_summary WHERE {year_sql}")
    groups = sorted(sales["territory_group"].dropna().unique())
    chosen = st.sidebar.multiselect("Territory group", groups, default=groups)
    sales = sales[sales["territory_group"].isin(chosen)]

    reps = (
        sales.groupby("salesperson_name", as_index=False)
        .agg(revenue=("total_revenue", "sum"), quota=("quota", "sum"), orders=("total_orders", "sum"))
        .assign(attainment=lambda d: 100 * d["revenue"] / d["quota"].where(d["quota"] > 0))
        .sort_values("revenue", ascending=False)
    )
    rep_months = (
        sales.groupby(["salesperson_id", "year", "month"], as_index=False)
        .agg(revenue=("total_revenue", "sum"), quota=("quota", "sum"))
        .query("quota > 0")
    )

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Reseller Revenue", money(reps["revenue"].sum()))
    c2.metric("Salespeople", f"{len(reps)}")
    c3.metric("Overall Quota Attainment", f"{100 * reps['revenue'].sum() / reps['quota'].sum():.0f}%")
    c4.metric("Rep-months Above Quota", f"{100 * (rep_months['revenue'] >= rep_months['quota']).mean():.0f}%")

    left, right = st.columns([3, 2])
    reps_plot = reps.dropna(subset=["attainment"]).sort_values("attainment")
    colors = [TEAL if a >= 100 else (AMBER if a >= 80 else ROSE) for a in reps_plot["attainment"]]
    fig = go.Figure(go.Bar(x=reps_plot["attainment"], y=reps_plot["salesperson_name"], orientation="h",
                           marker_color=colors, text=[f"{a:.0f}%" for a in reps_plot["attainment"]],
                           textposition="outside"))
    fig.add_vline(x=100, line_dash="dash", line_color=SLATE)
    fig.update_layout(title="Quota attainment by salesperson")
    fig.update_xaxes(ticksuffix="%", range=[0, max(130, reps_plot["attainment"].max() * 1.15)])
    left.plotly_chart(style(fig, 520), use_container_width=True)

    terr = sales.groupby(["territory_group", "territory_name"], as_index=False)["total_revenue"].sum()
    fig = px.bar(terr.sort_values("total_revenue"), x="total_revenue", y="territory_name", color="territory_group",
                 orientation="h", title="Revenue by territory",
                 color_discrete_sequence=[TEAL, TEAL_LIGHT, AMBER])
    fig.update_xaxes(tickprefix="$")
    fig.update_layout(legend=dict(orientation="h", y=-0.12))
    right.plotly_chart(style(fig, 520), use_container_width=True)

# ---------------------------------------------------------------------------
elif page == "Product Intelligence":
    st.title("Product Intelligence")
    prod = q(f"SELECT * FROM bi.vw_product_performance WHERE {year_sql}")
    total_rev = prod["gross_revenue"].sum()
    total_profit = prod["gross_profit"].sum()

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Product Revenue", money(total_rev))
    c2.metric("Gross Profit", money(total_profit))
    c3.metric("Gross Margin", f"{100 * total_profit / total_rev:.1f}%")
    c4.metric("Products Sold", f"{prod['product_id'].nunique():,}")

    left, right = st.columns(2)
    sub = prod.groupby(["category_name", "subcategory_name"], as_index=False).agg(
        revenue=("gross_revenue", "sum"), profit=("gross_profit", "sum"))
    sub["margin_pct"] = 100 * sub["profit"] / sub["revenue"]
    fig = px.treemap(sub, path=["category_name", "subcategory_name"], values="revenue", color="margin_pct",
                     color_continuous_scale=[[0, ROSE], [0.35, "#fde68a"], [1, TEAL]],
                     title="Revenue mix (size) and gross margin % (colour)")
    fig.update_traces(texttemplate="%{label}<br>%{value:$,.2s}")
    fig.update_layout(coloraxis_colorbar=dict(title="Margin %"))
    left.plotly_chart(style(fig, 460), use_container_width=True)

    top = (prod.groupby("product_name", as_index=False)
           .agg(revenue=("gross_revenue", "sum"), profit=("gross_profit", "sum"))
           .nlargest(10, "revenue").sort_values("revenue"))
    fig = go.Figure()
    fig.add_bar(y=top["product_name"], x=top["revenue"], orientation="h", name="Revenue", marker_color=TEAL)
    fig.add_bar(y=top["product_name"], x=top["profit"], orientation="h", name="Gross profit", marker_color=TEAL_LIGHT)
    fig.update_layout(title="Top 10 products by revenue", barmode="overlay",
                      legend=dict(orientation="h", y=1.08, x=1, xanchor="right"))
    fig.update_xaxes(tickprefix="$")
    right.plotly_chart(style(fig, 460), use_container_width=True)

    cat_month = drop_incomplete(prod.groupby(["year", "month", "category_name"], as_index=False)["gross_revenue"].sum())
    cat_month["month_date"] = pd.to_datetime(dict(year=cat_month["year"], month=cat_month["month"], day=1))
    fig = px.area(cat_month, x="month_date", y="gross_revenue", color="category_name",
                  title="Monthly revenue by category",
                  color_discrete_sequence=[TEAL, TEAL_LIGHT, AMBER, "#a78bfa"])
    fig.update_yaxes(tickprefix="$")
    st.plotly_chart(style(fig, 340), use_container_width=True)

# ---------------------------------------------------------------------------
elif page == "Customer Analytics":
    st.title("Customer Analytics")
    rfm = q("""
        SELECT customer_id, full_name, territory_name, country_region, frequency, monetary,
               recency_days, rfm_score, segment, is_returning
        FROM bi.vw_customer_rfm
    """)
    monthly = q(f"""
        SELECT year, month,
               COUNT(*) FILTER (WHERE is_new_this_month) AS new_customers,
               COUNT(*) FILTER (WHERE NOT is_new_this_month) AS returning_customers
        FROM bi.vw_customer_monthly
        WHERE {year_sql}
        GROUP BY year, month ORDER BY year, month
    """)

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Customers", f"{len(rfm):,}")
    c2.metric("Repeat Customers", f"{100 * rfm['is_returning'].mean():.1f}%")
    champions = rfm[rfm["segment"] == "Champions"]
    c3.metric("Champions", f"{len(champions):,}")
    c4.metric("Champions' Share of Revenue", f"{100 * champions['monetary'].sum() / rfm['monetary'].sum():.0f}%")

    left, right = st.columns(2)
    seg = (rfm.groupby("segment", as_index=False)
           .agg(customers=("customer_id", "count"), revenue=("monetary", "sum"), avg_value=("monetary", "mean"))
           .sort_values("revenue", ascending=False))
    fig = px.pie(seg, names="segment", values="customers", hole=0.55, title="Customers by RFM segment",
                 color="segment", color_discrete_map=SEGMENT_COLORS)
    fig.update_traces(textinfo="percent", textposition="inside")
    left.plotly_chart(style(fig, 400), use_container_width=True)

    fig = px.bar(seg.sort_values("avg_value"), x="avg_value", y="segment", orientation="h",
                 title="Average lifetime value by segment", color="segment",
                 color_discrete_map=SEGMENT_COLORS, text=seg.sort_values("avg_value")["avg_value"].map(money))
    fig.update_layout(showlegend=False)
    fig.update_xaxes(tickprefix="$")
    right.plotly_chart(style(fig, 400), use_container_width=True)

    monthly = drop_incomplete(monthly)
    monthly["month_date"] = pd.to_datetime(dict(year=monthly["year"], month=monthly["month"], day=1))
    fig = go.Figure()
    fig.add_bar(x=monthly["month_date"], y=monthly["returning_customers"], name="Returning", marker_color=TEAL)
    fig.add_bar(x=monthly["month_date"], y=monthly["new_customers"], name="New", marker_color=TEAL_LIGHT)
    fig.update_layout(barmode="stack", title="Active customers per month: new vs returning",
                      legend=dict(orientation="h", y=1.08, x=1, xanchor="right"))
    st.plotly_chart(style(fig, 320), use_container_width=True)

    st.subheader("Top customers by lifetime value")
    st.dataframe(
        rfm.nlargest(10, "monetary")[["full_name", "territory_name", "segment", "rfm_score", "frequency", "monetary", "recency_days"]],
        hide_index=True, use_container_width=True,
        column_config={
            "full_name": "Customer", "territory_name": "Territory", "segment": "Segment", "rfm_score": "RFM",
            "frequency": "Orders", "monetary": st.column_config.NumberColumn("Lifetime value", format="$%.0f"),
            "recency_days": st.column_config.NumberColumn("Days since last order", format="%d"),
        },
    )

# ---------------------------------------------------------------------------
elif page == "Anomaly Report":
    st.title("Anomaly Report")
    st.caption("Last 3 complete months scored against each entity's own history (|z| > 2 flagged).")
    anomalies = q("SELECT * FROM bi.vw_anomaly_variance")
    # is_anomaly is NULL when an entity has a single month of history (no stddev).
    anomalies["is_anomaly"] = anomalies["is_anomaly"].fillna(False).astype(bool)
    flagged = anomalies[anomalies["is_anomaly"]].copy()
    flagged["metric"] = flagged["metric_category"].str.replace("_", " ").str.replace("monthly ", "").str.title()

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Entity-months scored", f"{len(anomalies):,}")
    c2.metric("Anomalies", f"{len(flagged):,}")
    c3.metric("Spikes", f"{(flagged['anomaly_direction'] == 'SPIKE').sum():,}")
    c4.metric("Drops", f"{(flagged['anomaly_direction'] == 'DROP').sum():,}")

    left, right = st.columns([2, 3])
    counts = flagged.groupby(["metric", "anomaly_severity"], as_index=False).size()
    fig = px.bar(counts, x="size", y="metric", color="anomaly_severity", orientation="h",
                 title="Anomalies by metric and severity",
                 color_discrete_map={"MILD": AMBER, "MODERATE": "#ea580c", "SEVERE": ROSE})
    fig.update_layout(legend=dict(orientation="h", y=-0.15))
    left.plotly_chart(style(fig, 380), use_container_width=True)

    scored = anomalies[anomalies["z_score"].notna()]
    fig = px.scatter(scored, x="pct_vs_mean", y="z_score", color="anomaly_direction",
                     hover_data=["entity_name", "year", "month"], title="Deviation vs historical mean",
                     color_discrete_map={"NORMAL": "#cbd5e1", "SPIKE": TEAL, "DROP": ROSE}, opacity=0.8)
    fig.add_hrect(y0=-2, y1=2, fillcolor=GRID, opacity=0.5, line_width=0)
    fig.update_xaxes(ticksuffix="%", range=[-110, max(300, scored["pct_vs_mean"].quantile(0.995))])
    right.plotly_chart(style(fig, 380), use_container_width=True)

    st.subheader("Flagged items")
    table = flagged.sort_values("z_score", key=lambda s: s.abs(), ascending=False)
    table["period"] = table["year"].astype(str) + "-" + table["month"].astype(str).str.zfill(2)
    st.dataframe(
        table[["metric", "entity_name", "period", "value", "historical_mean", "z_score", "anomaly_direction", "anomaly_severity"]].head(15),
        hide_index=True, use_container_width=True,
        column_config={
            "metric": "Metric", "entity_name": "Entity", "period": "Month",
            "value": st.column_config.NumberColumn("Value", format="%.0f"),
            "historical_mean": st.column_config.NumberColumn("Historical mean", format="%.0f"),
            "z_score": st.column_config.NumberColumn("z", format="%.2f"),
            "anomaly_direction": "Direction", "anomaly_severity": "Severity",
        },
    )
