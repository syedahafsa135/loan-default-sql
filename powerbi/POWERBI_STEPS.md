# Building the one-page Power BI report

**Goal:** one page that answers *"where does the default risk sit, and how concentrated is it?"*

The original plan asked "how did volume change?", but this dataset has no dates, so the second half of the question is about concentration instead.

Allow 1–2 hours. The **expected values** below come from the SQL results, so you can check each visual as you go.

---

## 0. Before you start

In PowerShell, from the `loan-default-sql` folder, make sure the export file exists:

```powershell
python src\export_powerbi.py
```

You should see `Wrote 255,347 rows x 19 columns to powerbi\loans_dashboard.csv`. *(If you're using the Claude scratchpad Python, the full path is printed in the chat.)*

## 1. Load the data

1. Open **Power BI Desktop** → **Blank report**.
2. **Home → Get data → Text/CSV** → choose `powerbi\loans_dashboard.csv` → **Load**. Choose **Load**, not Transform.
3. In the **Data** pane on the right, the table is called `loans_dashboard`. Rename it to `loans` (right-click → Rename).
4. In **Table view** (the grid icon on the left), click each of these columns and set **Column tools → Summarization → Don't summarize**:
   - `age`
   - `red_flags`
   - `loan_term`
   - `credit_score`

## 2. Create the measures

Click the `loans` table → **Home → New measure**. Paste each line below one at a time and press Enter after each:

```DAX
Loans = COUNTROWS(loans)
```
```DAX
Defaults = SUM(loans[is_default])
```
```DAX
Default Rate = DIVIDE([Defaults], [Loans])
```
```DAX
Share of Defaults = DIVIDE([Defaults], CALCULATE([Defaults], ALL(loans)))
```
```DAX
Share of Loans = DIVIDE([Loans], CALCULATE([Loans], ALL(loans)))
```
```DAX
Defaults in 2+ Flags = CALCULATE([Share of Defaults], loans[red_flags] >= 2)
```

Then format them:
- Select **Default Rate**, **Share of Defaults**, **Share of Loans** and **Defaults in 2+ Flags** one at a time → **Measure tools → Format: Percentage**, 1 decimal place. Use 2 decimal places for Default Rate.
- **Loans** and **Defaults** → **Whole number**, with the thousands separator on.

## 3. Build the page (canvas 16:9)

Suggested layout: KPI cards across the top, two charts in the middle, and the heatmap plus a bar chart at the bottom. Slicers go on the left.

| # | Visual | Fields | Expected value / shape |
|---|---|---|---|
| 1 | **Card** | `Loans` | 255,347 |
| 2 | **Card** | `Default Rate` | 11.61% |
| 3 | **Card** | `Defaults` | 29,653 |
| 4 | **Card** | `Defaults in 2+ Flags`. Rename the title to "Defaults held by loans with 2+ red flags" | 47.4% |
| 5 | **Clustered column chart** | X-axis: `red_flags` · Y-axis: `Default Rate` · Tooltips: `Share of Loans` | 4.9%, 10.4%, 20.4%, 34.6%, 53.2% |
| 6 | **Line chart** | X-axis: `age` (set X-axis **Type: Continuous**) · Y-axis: `Default Rate` | Falls from about 22% at 18 to about 4.5% at 69 |
| 7 | **Matrix** (the heatmap) | Rows: `age_band` · Columns: `job_tenure` · Values: `Default Rate` | 18-24 / Under 2 years = 28.78%, 65-69 / 5+ years = 3.47% |
| 8 | **Clustered bar chart** | Y-axis: `employment_type` · X-axis: `Default Rate`, sorted descending | Unemployed 13.55% … Full-time 9.46% |
| 9 | **Slicer** | `loan_purpose` (Style: Tile or Dropdown) | 5 purposes |
| 10 | **Slicer** | `income_band` | 5 bands |

**Turn the matrix into a heatmap:**
1. Select it → **Format visual → Cell elements → Background color: On**.
2. Click **fx** → Format style: **Gradient**.
3. Lowest value: `#FBEFF3`. Highest value: `#962B57`. Tick **Add a middle color** and set it to `#E58CAE`.

**Colours to match the portfolio:**
- **View → Themes → Customize current theme**, and set the first data colour to `#B4386A`.
- Card callout text: `#2A1E24`.

**Optional extra:** add a constant line at 11.61% to the column and line charts (**Analytics** pane, the magnifier icon → **Constant line** → value `0.1161`, label "Overall").

## 4. Check it

- Click **Unemployed** in the bar chart. All the other visuals should cross-filter, and the Default Rate card should read **13.55%**.
- Clear it, then pick **Business** in the purpose slicer. The Default Rate card should read **12.33%**.

If both numbers match, the dashboard agrees with the SQL.

## 5. Save and screenshot

1. Clear all slicers and selections.
2. **File → Save as** → `powerbi\Dashboard.pbix`.
3. Press **Win + Shift + S** → drag over the report page → click the notification → **Save** as `powerbi\dashboard.png`.
4. Tell Claude it's there. It goes into the README and onto the portfolio page.
