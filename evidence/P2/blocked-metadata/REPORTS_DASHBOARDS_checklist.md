# P2-09 / P2-10 / P2-11 — Owner click-by-click checklist

Folders already created in ng-dev (created via API during earlier attempt — DO NOT duplicate).
IDs and access currently `Hidden`; the click steps below change access to `Public` for visibility.

| Folder | DeveloperName | Type | ID | Current access | Action |
|---|---|---|---|---|---|
| Report  | NG_01_Pipeline | Report | 00lg8000007YAc1AAG | Hidden | Set Public |
| Report  | NG_02_Leads    | Report | 00lg8000007YAddAAG | Hidden | Set Public |
| Dashboard | NG_Sales    | Dashboard | 00lg8000007YAfFAAW | Hidden | Set Public |

To change access: Setup → Reports or Dashboards → open the folder → Share → Public.
(or Setup → Folder Sharing for the folder type).

---

## P2-09 — Report: Pipeline by Stage (DATA_MODEL §5.6 pipeline)

Report folder: `NG_01_Pipeline` (already exists)
Report unique name (Report Builder label): **Pipeline by Stage**
Report API name: `NG_01_Pipeline/Pipeline_by_Stage`
Report type: **Opportunities**
Report format: **Matrix**

### Columns (add in order)
1. Opportunity Name (field: `Opportunity.Name`)
2. Opportunity Owner (field: `Opportunity.Owner.Alias` — use the Owner record's Alias)
3. Amount (field: `Opportunity.Amount`)

### Group Rows (Down)
- Stage (field: `Opportunity.StageName`), sort Asc, dateGranularity Day

### Group Columns (Across)
- Opportunity Owner Alias (same Owner.Alias field as column #2), sort Asc, dateGranularity Day

### Filters
- Show: All opportunities
- Add filter row:
  - Field: `Opportunity.StageName`
  - Operator: `not equal to`
  - Value: `Closed Lost`
  - Logic: AND

### Summaries (group-level subtotals on the matrix)
- Add summary to **Amount** at the **Total** level: Sum, position `Matrix Grand Total`
- Add summary to **Amount** at each Row grouping (Stage): Sum
- Add summary to **Amount** at each Column grouping (Owner): Sum

### Running user (running as)
- **Run as specified user** → select `arjun.ngdev@northgate.demo`
  (so the Owner grouping resolves to staff names, not “Anonymous User”)

### Save
- Report label: `Pipeline by Stage`
- Report unique name: `Pipeline_by_Stage` (auto)
- Folder: `NG_01_Pipeline`
- Click **Save**

---

## P2-10 — Report: Lead Source Effectiveness

Report folder: `NG_02_Leads`
Report label: **Lead Source Effectiveness**
Report API name: `NG_02_Leads/Lead_Source_Effectiveness`
Report type: **Leads**
Report format: **Summary**

### Columns
1. Lead Source (field: `Lead.LeadSource`)
2. Status (field: `Lead.Status`)
3. Converted (`Lead.IsConverted`, checkbox — show as a check)

### Group Rows (Down)
- Lead Source (`Lead.LeadSource`), sort Asc

### Filters
- Show: All leads
- Standard filter: **Created Date** = **All Time** (or Current FY if you prefer; backlog acceptance is open-ended)
- No extra filters

### Summaries
- Add summary on **Converted** field: **Count**, position **Grouping Row: Lead Source** (this is the conversion rate proxy).
  (Optional: add a Percent summary “Records where Converted = true” — depends on your UI build; not required for acceptance.)

### Running user
- **Run as specified user** → `arjun.ngdev@northgate.demo`

### Save
- Folder: `NG_02_Leads`
- Click **Save**

---

## P2-11 — Dashboard: Sales Pipeline Snapshot (dynamic, #1 of 3)

Dashboard folder: `NG_Sales`
Dashboard label: **Sales Pipeline Snapshot**
Dashboard API name: `NG_Sales/Sales_Pipeline_Snapshot`
Dashboard type: **Specified User** (not Logged-in user) — required so the
Owner-grouping widgets stay person-agnostic and the “dynamic by role” behaviour
is achieved by switching the running user (Phase 3).

### Layout
- **Left section**, column size: **Medium**
  - Widget #1: a **Report Chart** component (Bar)
    - Component title: `Pipeline by Stage`
    - Component type: Bar
    - Source report: `Pipeline by Stage` (in folder `NG_01_Pipeline`)
    - X-axis: `Opportunity.StageName`
    - Y-axis: Sum of `Opportunity.Amount`
    - Grouping: **Stage**
    - Show refresh: checked
- **Right section**, column size: **Medium**
  - Widget #2: a **Report Chart** component (Horizontal Bar)
    - Component title: `Lead Source`
    - Component type: Horizontal Bar
    - Source report: `Lead Source Effectiveness` (in folder `NG_02_Leads`)
    - X-axis: Count of `Lead.Id`
    - Grouping: `Lead.LeadSource`
    - Show refresh: checked

### Running user
- **Run as specified user** → `arjun.ngdev@northgate.demo`
  (dynamic-by-role for Phase 3 will toggle the running user via the Persona Switcher;
  for now set it to the demo admin so the rep/manager viewers see consistent owner names.)

### Folder sharing
- Dashboard folder `NG_Sales` — **Share with Public Group** (or set Public) so all
  persona logins can see the dashboard under their app.
  Path: Setup → Dashboards → open `NG_Sales` → Share → Public (or pick a Public Group).

### Save
- Folder: `NG_Sales`
- Click **Save** then **Done** in the builder.

---

## After the clicks: tell me “done”.

I will then:
1. Verify each report/dashboard is retrievable via `sf project retrieve start`
   and the returned XML matches the structure above (columns, groupings, summaries,
   running user, dashboard components).
2. Validate the same XML parses with `sf project deploy start --dry-run` and that
   the components land in the **same** folder paths.
3. Commit the retrieved XML under `force-app/main/default/{reports,dashboards}/NG_*`,
   keep this diagnostic in `evidence/P2/reports_blocked.txt` next to the new files,
   update `docs/security/PERMISSION_MATRIX.md` and `evidence/P1/users.txt` to record
   the folder API names, and update `BUILD_STATUS.md` only after the org-side checks
   pass and the original acceptance criteria are met.
