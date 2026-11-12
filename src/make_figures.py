"""Draw the README / portfolio charts from the CSVs in results/.

Usage:
    python src/make_figures.py

Every number plotted is read from results/, so the charts always match
the SQL output.
"""
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import LinearSegmentedColormap

ROOT = Path(__file__).resolve().parents[1]
RES, FIG = ROOT / "results", ROOT / "figures"
FIG.mkdir(exist_ok=True)

# Portfolio palette (syedahafsa135.github.io, light theme)
ACCENT, ACCENT_SOFT = "#B4386A", "#F2C9D8"
INK, MUTED, LINE, BG = "#2A1E24", "#6B5A62", "#E9DADF", "#FFFFFF"
OVERALL = 11.61  # overall default rate, from results/clean_checks.csv

plt.rcParams.update({
    "font.family": ["Segoe UI", "DejaVu Sans"], "font.size": 11,
    "axes.edgecolor": LINE, "axes.labelcolor": MUTED, "axes.titlecolor": INK,
    "axes.titlesize": 14, "axes.titleweight": "bold", "axes.titlelocation": "left",
    "xtick.color": MUTED, "ytick.color": MUTED, "axes.spines.top": False,
    "axes.spines.right": False, "axes.grid": True, "grid.color": LINE,
    "grid.linewidth": 0.8, "axes.axisbelow": True, "figure.facecolor": BG,
    "axes.facecolor": BG, "savefig.dpi": 200, "savefig.bbox": "tight",
})

overall = pd.read_csv(RES / "clean_checks.csv").default_rate_pct.iloc[0]
assert abs(overall - OVERALL) < 0.01


def overall_line(ax, y=OVERALL, text_x=None):
    ax.axhline(y, color=MUTED, lw=1, ls=(0, (4, 3)), zorder=1)
    if text_x is not None:
        ax.text(text_x, y + 0.6, f"overall {y:.2f}%", color=MUTED, fontsize=9.5)


# 1. Red-flag scorecard -------------------------------------------------
s = pd.read_csv(RES / "q9_red_flag_scorecard.csv")
fig, ax = plt.subplots(figsize=(8, 4.6))
bars = ax.bar(s.red_flags, s.default_rate_pct, width=0.62, color=ACCENT, zorder=2)
for b, rate, share in zip(bars, s.default_rate_pct, s.share_of_loans_pct):
    ax.text(b.get_x() + b.get_width() / 2, rate + 1.2, f"{rate:.1f}%", ha="center",
            color=INK, fontweight="bold", zorder=4,
            bbox=dict(facecolor=BG, edgecolor="none", pad=1.5))  # sits above the overall line
ax.set_xticks(s.red_flags, [f"{f} flag{'s' if f != 1 else ''}\n{sh:.1f}% of loans"
                            for f, sh in zip(s.red_flags, s.share_of_loans_pct)])
overall_line(ax)
ax.text(-0.4, OVERALL + 1.0, f"overall {OVERALL:.2f}%", color=MUTED, fontsize=9.5)
ax.set_ylim(0, 60); ax.set_ylabel("Default rate (%)"); ax.grid(axis="x", visible=False)
ax.set_title("Each red flag roughly doubles the default rate", pad=26)
ax.text(0, 1.025, "Flags: age under 30, rate 18%+, loan 3x income or more, under 2 years in the job",
        transform=ax.transAxes, color=MUTED, fontsize=9.5, va="bottom")
fig.savefig(FIG / "red-flag-scorecard.png"); plt.close(fig)

# 2. Age: raw rate and 5-year moving average ------------------------------
a = pd.read_csv(RES / "q5_age_moving_average.csv")
fig, ax = plt.subplots(figsize=(8, 4.6))
ax.scatter(a.age, a.default_rate_pct, s=22, color=ACCENT_SOFT, zorder=2, label="each age")
ax.plot(a.age, a.moving_avg_5yr_pct, color=ACCENT, lw=2.2, zorder=3, label="5-year moving average")
overall_line(ax, text_x=58)
first, last = a.iloc[0], a.iloc[-1]
ax.annotate(f"{first.moving_avg_5yr_pct:.1f}% at {int(first.age)}", (first.age, first.moving_avg_5yr_pct),
            xytext=(8, 4), textcoords="offset points", color=INK, fontweight="bold")
ax.annotate(f"{last.moving_avg_5yr_pct:.1f}% at {int(last.age)}", (last.age, last.moving_avg_5yr_pct),
            xytext=(-62, -18), textcoords="offset points", color=INK, fontweight="bold")
ax.set_ylim(0, 25); ax.set_xlabel("Borrower age"); ax.set_ylabel("Default rate (%)")
ax.legend(frameon=False, loc="upper right", labelcolor=MUTED)
ax.set_title("Default risk falls with almost every year of age")
fig.savefig(FIG / "age-moving-average.png"); plt.close(fig)

# 3. Cohort matrix: age band x job tenure --------------------------------
c = pd.read_csv(RES / "q10_age_by_job_tenure_matrix.csv")
cols = ["job_0_2y_pct", "job_2_5y_pct", "job_5y_plus_pct"]
m = c[cols].to_numpy()
cmap = LinearSegmentedColormap.from_list("pink", ["#FBEFF3", "#E58CAE", "#962B57"])
fig, ax = plt.subplots(figsize=(7, 4.8))
ax.imshow(m, cmap=cmap, vmin=0, vmax=30, aspect="auto")
for i in range(m.shape[0]):
    for j in range(m.shape[1]):
        v = m[i, j]
        ax.text(j, i, f"{v:.1f}%", ha="center", va="center", fontweight="bold",
                color="#FFFFFF" if v > 17 else INK)
ax.set_xticks(range(3), ["under 2 years", "2-5 years", "5+ years"])
ax.set_yticks(range(len(c)), c.age_band)
ax.set_xlabel("Time in current job"); ax.set_ylabel("Age band")
ax.grid(False); [sp.set_visible(False) for sp in ax.spines.values()]
ax.tick_params(length=0)
ax.set_title("Young + new in the job is where risk stacks up")
fig.savefig(FIG / "cohort-age-tenure.png"); plt.close(fig)

# 4. Deciles: interest rate vs loan-to-income (shared y-axis) -------------
r = pd.read_csv(RES / "q7a_interest_rate_deciles.csv")
l = pd.read_csv(RES / "q7b_loan_to_income_deciles.csv")
fig, axes = plt.subplots(1, 2, figsize=(10, 4.4), sharey=True)
for ax, d, title in [(axes[0], r, "By interest rate: a smooth slope"),
                     (axes[1], l, "By loan-to-income: packed into the top 10%")]:
    ax.bar(d.decile, d.default_rate_pct, width=0.66, color=ACCENT, zorder=2)
    top = d.iloc[0]
    ax.text(1, top.default_rate_pct + 0.8, f"{top.default_rate_pct:.1f}%", ha="center",
            color=INK, fontweight="bold")
    low = d.iloc[-1]
    ax.text(10, low.default_rate_pct + 0.8, f"{low.default_rate_pct:.1f}%", ha="center",
            color=INK, fontweight="bold")
    overall_line(ax)
    ax.set_xticks(range(1, 11)); ax.set_xlabel("Decile (1 = highest)")
    ax.grid(axis="x", visible=False)
    ax.set_title(title, fontsize=12)
axes[0].set_ylabel("Default rate (%)"); axes[0].set_ylim(0, 30)
axes[1].text(10.4, OVERALL + 0.6, f"overall {OVERALL:.2f}%", color=MUTED, fontsize=9.5, ha="right")
fig.savefig(FIG / "deciles-rate-vs-lti.png"); plt.close(fig)

print("Wrote:", ", ".join(sorted(p.name for p in FIG.glob("*.png"))))
