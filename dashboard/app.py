"""City volume dashboard — chute totals → city via chute_destination."""

from __future__ import annotations

import html

import pandas as pd
import plotly.express as px
import streamlit as st

from data import city_volume_series, latest_city_totals, list_batches

st.set_page_config(
    page_title="Sorting Database · City Flow",
    page_icon="▦",
    layout="wide",
    initial_sidebar_state="expanded",
)

CITY_PALETTE = [
    "#F0A202",
    "#3DDC97",
    "#4CC9F0",
    "#F72585",
    "#B8F2E6",
    "#FF6B35",
    "#7BDFF2",
    "#F9C74F",
    "#90BE6D",
    "#577590",
    "#F8961E",
    "#43AA8B",
    "#F94144",
    "#277DA1",
    "#F3722C",
]

st.markdown(
    """
<style>
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700&family=IBM+Plex+Mono:wght@400;500&display=swap');

html, body, [class*="css"] {
  font-family: "Outfit", system-ui, sans-serif;
}
.stApp {
  background:
    radial-gradient(1200px 600px at 10% -10%, rgba(240,162,2,0.16), transparent 55%),
    radial-gradient(900px 500px at 90% 0%, rgba(61,220,151,0.10), transparent 50%),
    linear-gradient(165deg, #0b1210 0%, #121a22 45%, #0e151c 100%);
  color: #e8eee9;
}
[data-testid="stSidebar"] {
  background: rgba(8, 14, 16, 0.92);
  border-right: 1px solid rgba(240,162,2,0.18);
}
[data-testid="stSidebar"] * { color: #dce6df !important; }
.block-container { padding-top: 1.4rem; padding-bottom: 2.5rem; max-width: 1200px; }
h1, h2, h3 { font-family: "Outfit", sans-serif !important; letter-spacing: -0.02em; }
.brand {
  font-size: clamp(2.4rem, 5vw, 3.6rem);
  font-weight: 700;
  line-height: 1.05;
  margin: 0 0 0.35rem 0;
  background: linear-gradient(120deg, #fff6e0 0%, #f0a202 40%, #3ddc97 100%);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.lede {
  color: #9aa8a0;
  font-size: 1.05rem;
  max-width: 40rem;
  margin-bottom: 1.25rem;
}
.meta-strip {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem 1.25rem;
  margin: 0.5rem 0 1.5rem;
  font-family: "IBM Plex Mono", monospace;
  font-size: 0.85rem;
  color: #b7c4bc;
}
.meta-strip strong { color: #f0a202; font-weight: 500; }
.city-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 0.65rem;
  margin-top: 0.5rem;
}
.city-tile {
  border: 1px solid rgba(255,255,255,0.08);
  background: linear-gradient(160deg, rgba(255,255,255,0.04), rgba(255,255,255,0.015));
  padding: 0.7rem 0.8rem;
  border-radius: 2px;
  transition: border-color 180ms ease, transform 180ms ease;
}
.city-tile:hover {
  border-color: rgba(240,162,2,0.45);
  transform: translateY(-1px);
}
.city-tile .code {
  font-family: "IBM Plex Mono", monospace;
  font-size: 0.78rem;
  color: #3ddc97;
  letter-spacing: 0.04em;
}
.city-tile .vol {
  font-size: 1.35rem;
  font-weight: 700;
  margin-top: 0.2rem;
  color: #f4f7f5;
}
.city-tile .delta {
  font-family: "IBM Plex Mono", monospace;
  font-size: 0.72rem;
  color: #9aa8a0;
  margin-top: 0.15rem;
}
div[data-testid="stPlotlyChart"] {
  border: 1px solid rgba(255,255,255,0.07);
  background: rgba(0,0,0,0.18);
  padding: 0.4rem;
}
</style>
""",
    unsafe_allow_html=True,
)

st.markdown('<p class="brand">Sorting Database</p>', unsafe_allow_html=True)
st.markdown(
    '<p class="lede">City / hub flow from 20-minute chute snapshots. '
    "<code>last_mile</code> uses <code>city</code>; <code>transit</code> uses "
    "<code>warehouse</code>. Increments are this scrape minus the previous one.</p>",
    unsafe_allow_html=True,
)

try:
    batches = list_batches(40)
except Exception as exc:  # noqa: BLE001
    st.error(f"Could not load batches from Supabase: {exc}")
    st.stop()

if batches.empty:
    st.warning("No scrape batches in Supabase yet.")
    st.stop()

labels = [
    f"{row.subbatch_date} · {row.subbatch} · {row.scrape_count} snaps · {row.latest_total:,}"
    for row in batches.itertuples()
]
choice = st.sidebar.selectbox("Batch / ops day", options=list(range(len(labels))), format_func=lambda i: labels[i])
selected = batches.iloc[choice]
subbatch = str(selected["subbatch"])

show_unmapped = st.sidebar.checkbox("Include Unmapped (no city / no transit warehouse)", value=False)
metric_mode = st.sidebar.radio(
    "Chart metric",
    options=["total", "delta"],
    format_func=lambda m: "Cumulative total" if m == "total" else "20-min increment",
    index=0,
)
top_n = st.sidebar.slider("Cities / hubs on chart (by latest total)", min_value=5, max_value=40, value=15)

series = city_volume_series(subbatch)
if series.empty:
    st.warning(f"No chute volume rows for {subbatch}.")
    st.stop()

if not show_unmapped:
    series = series[series["city"] != "Unmapped"].copy()

latest = latest_city_totals(series)
chart_cities = latest["city"].head(top_n).tolist()
plot_df = series[series["city"].isin(chart_cities)].copy()
plot_df["scraped_et"] = plot_df["scraped_at"].dt.tz_convert("America/New_York")

y_col = "total_volume" if metric_mode == "total" else "delta_volume"
y_title = "Cumulative packages" if metric_mode == "total" else "Packages since previous scrape"

color_map = {city: CITY_PALETTE[i % len(CITY_PALETTE)] for i, city in enumerate(chart_cities)}

fig = px.line(
    plot_df.sort_values("scraped_et"),
    x="scraped_et",
    y=y_col,
    color="city",
    color_discrete_map=color_map,
    markers=True,
)
fig.update_traces(line=dict(width=2.4), marker=dict(size=7))
fig.update_layout(
    height=460,
    margin=dict(l=10, r=10, t=20, b=10),
    paper_bgcolor="rgba(0,0,0,0)",
    plot_bgcolor="rgba(0,0,0,0)",
    font=dict(family="Outfit, sans-serif", color="#dce6df"),
    legend=dict(orientation="h", yanchor="bottom", y=1.02, x=0, title=None),
    xaxis=dict(title="Scrape time (ET)", gridcolor="rgba(255,255,255,0.06)", zeroline=False),
    yaxis=dict(title=y_title, gridcolor="rgba(255,255,255,0.06)", zeroline=False),
    hovermode="x unified",
)

ops_date = selected["subbatch_date"]
last_et = pd.Timestamp(selected["last_scraped_at"]).tz_convert("America/New_York")
st.markdown(
    f"""
<div class="meta-strip">
  <span>ops day <strong>{html.escape(str(ops_date))}</strong></span>
  <span>batch <strong>{html.escape(subbatch)}</strong></span>
  <span>snaps <strong>{int(selected["scrape_count"])}</strong></span>
  <span>last scrape <strong>{last_et.strftime("%Y-%m-%d %H:%M %Z")}</strong></span>
</div>
""",
    unsafe_allow_html=True,
)

st.subheader("City / hub growth")
st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

st.subheader("Latest city / hub totals")
st.caption(
    "Mapping: `last_mile` → city, `transit` → warehouse "
    "(chute_destination effective for that batch ops day: latest effective_date ≤ subbatch_date). "
    "Delta = current chute total − previous scrape (floored at 0)."
)

tiles = []
for row in latest.itertuples():
    delta = int(row.delta_volume)
    delta_txt = f"+{delta:,}" if delta >= 0 else f"{delta:,}"
    tiles.append(
        f'<div class="city-tile">'
        f'<div class="code">{html.escape(str(row.city))}</div>'
        f'<div class="vol">{int(row.total_volume):,}</div>'
        f'<div class="delta">last Δ {delta_txt}</div>'
        f"</div>"
    )
st.markdown(f'<div class="city-grid">{"".join(tiles)}</div>', unsafe_allow_html=True)

with st.expander("Raw series table"):
    show = series.copy()
    show["scraped_at_et"] = show["scraped_at"].dt.tz_convert("America/New_York").dt.strftime(
        "%Y-%m-%d %H:%M"
    )
    st.dataframe(
        show[["scraped_at_et", "city", "total_volume", "delta_volume"]].sort_values(
            ["scraped_at_et", "city"]
        ),
        use_container_width=True,
        hide_index=True,
    )
