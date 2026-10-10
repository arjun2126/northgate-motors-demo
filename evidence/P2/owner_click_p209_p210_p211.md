# Owner Click Checklist — P2-09, P2-10, P2-11

**Source of truth:** `evidence/P2/OWNER_ACTION_LIST.md` §1.
**Target org:** ng-dev only.
**Goal:** build the three reports and one dashboard, then tell the owner "done" so the
metadata can be retrieved and validated.

---

## 0. Folder sharing (do this first)

Folders already exist in ng-dev — **do not create them again**.

| DeveloperName | Type | ID | Current sharing |
|---|---|---|---|
| `NG_01_Pipeline` | Report | `00lg8000007YAc1AAG` | Hidden |
| `NG_02_Leads` | Report | `00lg8000007YAddAAG` | Hidden |
| `NG_Sales` | Dashboard | `00lg8000007YAfFAAW` | Hidden |

For each: **Setup → Reports** (or **Dashboards**) → locate the folder → **dropdown →
Share → Public Groups** (not Public) → pick the group → Access `View` → **Share**.

| Folder | Share with | Access |
|---|---|---|
| `NG_01_Pipeline` | `PG_All_Sales` | View |
| `NG_02_Leads` | `PG_All_Sales` | View |
| `NG_Sales` | `PG_All_Sales` | View |

> Requires public group `PG_All_Sales` (members: `ngrep@northgate.demo`,
> `arjun.ngdev@northgate.demo`) from `OWNER_ACTION_LIST.md` §0.

---

## 1. P2-09 — Report `Pipeline by Stage`

App Launcher → **Reports** → **New Report** → report type **"Opportunities"** → **Continue**.

- **Group Rows (Down):** drag `Opportunity.StageName`. Sort Asc.
- **Group Columns (Across):** drag `Opportunity.Sales_Staff__c` (the lookup, not an alias —
  `Sales_Staff__c` is the reporting dimension per DATA_MODEL §3.15 / §7). Sort Asc.
- **Columns:** add `Opportunity.Name`, `Opportunity.Sales_Staff__c.Name`,
  `Opportunity.Amount`.
- **Summaries:** on the Amount column at the **Grand Total** cell → **Summarize → Sum**.
  Repeat at the row grouping and the column grouping so totals show at every level.
- **Filters:** Show = All Opportunities; add
  `Opportunity.StageName` **not equal to** `Closed Lost`.
- **Save & Run → Save As**
  - Report Name: `Pipeline by Stage`
  - Report Unique Name: `Pipeline_by_Stage`
  - Folder: `NG_01_Pipeline`

## 2. P2-10 — Report `Lead Source Effectiveness` (with real conversion %)

App Launcher → **Reports** → **New Report** → report type **"Leads"** → **Continue**.

- **Group Rows (Down):** `Lead.LeadSource`. Sort Asc.
- Add **one** summary formula (Columns panel → **Add Summary Formula**, the Σ icon):
  - **Name:** `Conversion %`
  - **Output type:** **Percent**, Decimals 1–2
  - **Formula:** `Converted:SUM / RowCount`

  Where the field tokens are Report Builder's actual tokens for a Leads grouped by
  `LeadSource`:
  - `Converted` = the `IsConverted` checkbox summary field, aggregated as **SUM**
  - `RowCount` = the count of Lead rows in the group

  Report Builder surfaces these as selectable summary fields, so pick `Converted` with the
  **SUM** roll-up, then `/ RowCount`, and set the output type to Percent. Do not write a
  row-level `IF(IsConverted, 1, 0)` helper unless the builder confirms a custom formula
  column — the summary formula must stand on its own.

  **Do not** add a grand-total denominator (`... / PARENTGROUPVAL(...)`); that would
  change the metric from group conversion rate to share-of-total.

- **Columns:** `Lead.LeadSource`, `Lead.Status`, then `Lead.Email`.
- **Summaries:** add **Count** of `Lead.Id` at the grouping-row level for a row count
  cross-check.
- **Filters:** Show **All Leads** (no time restriction).
- **Save & Run → Save As**
  - Report Name: `Lead Source Effectiveness`
  - Report Unique Name: `Lead_Source_Effectiveness`
  - Folder: `NG_02_Leads`

### Validation example for the formula

A source group with **4 leads, 1 of them converted** must render **25.0%** in the
`Conversion %` column. Report Builder returns a Decimal from `SUM / RowCount`
(0.25); setting the output type to Percent formats it as 25.0% without changing the value.

## 3. P2-11 — Dashboard `Sales Pipeline Snapshot`

App Launcher → **Dashboards** → **New Dashboard**.
- **Name:** `Sales Pipeline Snapshot`
- **Folder:** `NG_Sales` (already exists)
- **Layout:** **3-column** equal width → **Create**

Build the third component's report first:

App Launcher → **Reports** → **New Report** → **Opportunities** → **Continue**.
- **Group Rows:** `Opportunity.Sales_Staff__c` (Asc)
- **Columns:** `Opportunity.Sales_Staff__c.Name`, `Opportunity.Amount`
- **Filters:** `Opportunity.IsClosed = false`; `Opportunity.Sales_Staff__c IsNull = false`
- **Summaries:** Sum of Amount at Grand Total
- **Save As:** `Open Opps by Sales Staff`, Unique `Open_Opps_by_Sales_Staff`,
  Folder `NG_01_Pipeline`

Now add the three dashboard components:

| # | Component title | Source report | Display as | Settings |
|---|---|---|---|---|
| 1 | Pipeline by Stage | `Pipeline by Stage` in `NG_01_Pipeline` | Vertical Bar | X: StageName; Y: Sum of Amount |
| 2 | Lead Source Effectiveness | `Lead Source Effectiveness` in `NG_02_Leads` | Horizontal Bar | Grouping: Lead.LeadSource; Value: Count of Lead |
| 3 | Open Opps by Sales Staff | `Open Opps by Sales Staff` in `NG_01_Pipeline` | Horizontal Bar | Grouping: Sales_Staff__c; Value: Sum of Amount |

Then set viewer mode:
1. Open the saved dashboard → **gear icon** at the top-left.
2. **"View dashboard as"** → **"The dashboard viewer"**.
3. **Save**.

---

## 4. After you finish: say "done"

The owner will then tell the agent, who will:
1. `sf project retrieve start --metadata Report,Dashboard` for the three reports and the
   dashboard.
2. Run the full-project dry-run and the full test suite.
3. Commit the retrieved XML.

## 5. Also outstanding after this checklist

- **P2-01 ≈80/20 distribution test:** inputs and expected results are proposed in
  `evidence/P2/civility_verification_report.md` §3.3. Not run yet.
- **Probe classes `P2UAT_ProbeTemp` / `P2UAT_Response_Prune`:** decide commit or retire.
- **Cross-transaction round-robin:** record the Phase 2 acceptance exception described in
  the cross-verification report §4, or authorise implementation.
- **ng-demo:** unchanged.
