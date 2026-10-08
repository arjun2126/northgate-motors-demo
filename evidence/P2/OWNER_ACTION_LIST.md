# Owner Action List — Phase 2 (corrected)

This is the single source of owner click steps. Independent agent work continues in the
background (UAT and demo script already committed). Two things block M1: the
P2-01 routing flow and the P2-09/10/11 reports + dashboard. Both have corrected,
authoritative designs below.

Before you start, create the **persona public groups** in Setup. None exist yet.

---

## 0. One-time: persona public groups (do this first, every later step depends on it)

In Lightning: **Setup → Quick Find `Groups` → Public Groups → New**.

| Group | Type | Members (Username) | Access rule |
|---|---|---|---|
| `PG_All_Sales` | Public | `ngrep@northgate.demo`, `arjun.ngdev@northgate.demo` | All sales: rep, manager, finance, admin |
| `PG_All_Service` | Public | `ngsvc@northgate.demo`, `ngtech@northgate.demo`, `arjun.ngdev@northgate.demo` | Service advisor, technician, admin |
| `PG_All_Inventory` | Public | `nginv@northgate.demo`, `arjun.ngdev@northgate.demo` | Inventory coordinator + admin |
| `PG_All_Finance` | Public | `ngpersona@northgate.demo`, `arjun.ngdev@northgate.demo` | Persona switcher (finance) + admin |
| `PG_Admins` | Public | `arjun.ngdev@northgate.demo` | Admin only |

Why: least-privilege folder sharing. Public groups exist; individual user access is
deprecated. Save after each group; ignore "Collaboration" settings.

Also ensure **Folder Sharing for Lightning Experience** is on (it is in DE by default).
Setup → Quick Find `Folder Sharing` → if a toggle exists, set **Enhanced folder
sharing = ON**; if only classic toggle, leave as is.

---

## 1. P2-09 / P2-10 / P2-11 — Reports and dashboard (corrected)

Folder records in ng-dev (already present from earlier work; **do not re-create**):

| DeveloperName | Type | ID | Current sharing |
|---|---|---|---|
| `NG_01_Pipeline` | Report | `00lg8000007YAc1AAG` | Hidden |
| `NG_02_Leads` | Report | `00lg8000007YAddAAG` | Hidden |
| `NG_Sales` | Dashboard | `00lg8000007YAfFAAW` | Hidden |

For each, in **Setup → Reports** (or **Dashboards**) → locate the folder → **dropdown →
Share → Public Groups** (not Public) → pick the right group → Access `View` → **Share**.

| Folder | Share with | Access |
|---|---|---|
| `NG_01_Pipeline` | `PG_All_Sales` | View |
| `NG_02_Leads` | `PG_All_Sales` | View |
| `NG_Sales` | `PG_All_Sales` | View |

### 1a. Report — `Pipeline by Stage` (Lightning path)

App Launcher → **Reports** → **New Report**.
- Report type picklist: search and select **"Opportunities"** → **Continue**.
- **OUTLINE** panel:
  - **Group Rows (Down)**: drag `Opportunity.StageName`. Sort Asc.
  - **Group Columns (Across)**: drag `Opportunity.Sales_Staff__c` (the lookup, not the
    `Owner.Alias` we tried before — Staff__c is the reporting dimension per
    DATA_MODEL §3.15 and §7). Sort Asc.
  - **Columns**: add `Opportunity.Name`, `Opportunity.Sales_Staff__c.Name` (the joined
    column), `Opportunity.Amount`.
  - **Summaries**: click the Amount column at the **Grand Total** cell → **Summarize** →
    **Sum**. Repeat at each row/column grouping so totals show at every level.
- **Filters**:
  - Show: All Opportunities.
  - Add filter row: `Opportunity.StageName` **not equal to** `Closed Lost`.
- **Lightning click path to Save**: top-right **Save & Run** → **Save As**:
  - Report Name: `Pipeline by Stage`
  - Report Unique Name: `Pipeline_by_Stage`
  - Folder: `NG_01_Pipeline` (must be created/visible — it is)
  - Click **Save**.

### 1b. Report — `Lead Source Effectiveness` (with actual conversion %)

App Launcher → **Reports** → **New Report**.
- Report type: **Leads** → **Continue**.
- **OUTLINE**:
  - **Group Rows (Down)**: `Lead.LeadSource` (Asc).
  - **Columns**: `Lead.LeadSource`, `Lead.Status`, then add a **Summary Formula**
    (the Σ icon at the top of the Columns panel) — the UI now exposes **Add Summary
    Formula** (Lightning) and **Add Formula** (row-level). Build two:
    1. **Row-level formula** `Converted_Flag`:
       - Name: `Converted_Flag`
       - Formula Output: **Number**, Decimal Places: 0
       - Formula: `IF(IsConverted, 1, 0)`
       - Place it in Columns (it's per-row).
    2. **Summary formula** `Conversion %`:
       - Click the **Σ** → **Add Summary Formula** (or right-click the grouping →
       "Add Summary Formula").
       - **Column Name**: `Conversion %`
       - **Formula Output Type**: **Percent** (set decimal places to 1 or 2).
       - **Display**: choose **"At all summary levels"** OR **"Specific groups" → GRAND_SUMMARY**.
       - **Formula**: `Sum(Converted_Flag) / RowCount` (Lightning will render it
       as a Percent). Save the formula.
  - **Summaries** for the existing standard columns: add a Count of Lead ID at the
    Grouping Row level.
- **Filters**: Show **All Leads** (no time restriction, per backlog).
- **Save & Run** → Save As:
  - Report Name: `Lead Source Effectiveness`
  - Report Unique Name: `Lead_Source_Effectiveness`
  - Folder: `NG_02_Leads`
  - **Save**.

### 1c. Dashboard — `Sales Pipeline Snapshot` (viewer mode, 3 widgets)

App Launcher → **Dashboards** → **New Dashboard**.
- **Name**: `Sales Pipeline Snapshot`
- **Folder**: `NG_Sales` (already exists)
- **Layout**: choose **3-column** equal width → **Create**.

Drag these **three** components into the layout (left → right). For each, click
**+ Component → Report** and pick the source report.

| # | Component Title | Source report | Display As | Notes |
|---|---|---|---|---|
| 1 | Pipeline by Stage | `Pipeline by Stage` (folder `NG_01_Pipeline`) | Vertical Bar | X: StageName, Y: Sum Amount, Grouping: Stage |
| 2 | Lead Source Effectiveness | `Lead Source Effectiveness` (folder `NG_02_Leads`) | Horizontal Bar | Grouping: Lead.LeadSource, Value: Count of Lead |
| 3 | Open Opps by Sales Staff | `Open Opps by Sales Staff` (you will create this report) | Horizontal Bar | See below |

For component #3, create the report first:

App Launcher → **Reports** → **New Report** → **Opportunities** → **Continue**.
- **Group Rows**: `Opportunity.Sales_Staff__c` (Asc).
- **Columns**: `Opportunity.Sales_Staff__c.Name`, `Opportunity.Amount`.
- **Filters**: add `Opportunity.IsClosed = false` (so only open opps), and
  `Opportunity.Sales_Staff__c IsNull = false` (exclude unstaffed).
- **Summaries**: Sum of Amount at Grand Total.
- **Save As**: Report Name `Open Opps by Sales Staff`, Unique `Open_Opps_by_Sales_Staff`,
  Folder `NG_01_Pipeline` → Save. (Same folder as the pipeline report; both are sales.)

Now back in the dashboard, add component #3 with this report. Then **Save**, **Done**.

#### Set the dashboard to viewer mode (the magic)

With the dashboard saved and open:
1. Click the **gear icon** at the top of the dashboard's left panel.
2. In the **"View dashboard as"** section, choose **"The dashboard viewer"**.
3. Click **Save**.

This makes the dashboard **dynamic by role**: when `ngrep` opens it, the Sales_Staff
grouping resolves against `ngrep`'s visibility; when `ngpersona` (manager) opens it,
they see staff across Downtown/North/Airport. No "Run as specified user" toggle is used
anywhere. (Permission note: viewers need no extra permission to *see* a dynamic
dashboard; to allow them to *change* the "view as" user, enable `View My Team's Dashboards`
on the persona, or grant `View All Data` for full flexibility.)

#### Sharing the dashboard folder

Already covered in the table above: `NG_Sales` shared with `PG_All_Sales` (View).

---

## 2. P2-01 — Lead Enrich Rooftop flow (corrected, no Apex action in before-save)

The hand-written Flow failed because **record-triggered before-save Flows cannot call
invocable Apex actions** (Salesforce Help: "Flow Types" — only Assignment, Decision,
Get Records, Loop are allowed in before-save). The corrected design splits routing
into **two** source-deployed pieces, each with a single, buildable responsibility:

### 2a. Before-trigger Apex — handles round-robin Owner assignment

Already deployable from source. The agent will commit
`force-app/main/default/triggers/LeadRoutingTrigger.trigger` and
`force-app/main/default/classes/LeadRoutingTriggerHandler.cls`. Responsibilities:
- (none) on insert; the Flow sets the round-robin slot.
- Reads `Rooftop__c` and `Assigned_Batch__c` (set by the Flow).
- Calls `LeadRoundRobin.nextSlot` (already deployed) using a
  `Map<Rooftop__c, List<Id>>` of owner lanes (one rep + one queue per rooftop).
- Sets `OwnerId` and overwrites `Assigned_Batch__c` with the lane index (e.g. `M-R1`).
- Honors `Bypass_Automation`.

### 2b. Before-save Record-Triggered Flow — `Lead_Enrich_Rooftop` (build this in UI)

Lightning click path (canonical): **App Launcher (waffle) → search `Flows` → Flows →
New → Create from Scratch → Next → pick "Record-Triggered Flow" → Create**.

Start-element dialog (exact text to pick):
- **Object**: `Lead`
- **Trigger the Flow When**: `A record is created`
- **Entry Conditions**: **"All conditions are met"** with one condition:
  - `Lead.PostalCode` `IsNull` `false`
- **Optimize the Flow for**: **Fast Field Updates** (this is the before-save path)
- **Run Asynchronously**: leave unchecked
- **Done**

Bypass guard (MASTER_PLAN §5.6): **Add a Decision element first** named `Not Bypassed`,
formula: `{!$Permission.Bypass_Automation} = false`. Connect **Start → Not Bypassed**,
and **Not Bypassed's "false" outcome → No_Op** (a no-op Assignment). Connect **"true"**
to the rest of the flow.

Flow body (drag in this order; connect outcomes as noted):
1. **Get Records** `Lookup_Routing` — Object: `Lead_Routing__mdt`; Condition:
   `{!$Record.FSA_Prefix__c (Lead.PostalCode…)}` use a **formula condition** to set
   `FSA_Prefix__c` from `PostalCode`:
   - Formula: `IF(LEFT(SUBSTITUTE({!$Record.PostalCode}," ",""),1)="M","M",IF(LEFT(SUBSTITUTE({!$Record.PostalCode}," ",""),1)="L",LEFT(SUBSTITUTE({!$Record.PostalCode}," ",""),3),"UNROUTED"))`
   - Set `FSA_Prefix__c = {!formulaResult}` as the filter on `Lead_Routing__mdt`.
   - Store first record in `var_Route`.
2. **Decision** `Has_Route` — if `{!var_Route.Id} IsNull = false` → continue; else → **Assignment** `Mark_Unrouted` which sets:
   - `Assigned_Batch__c` = `UNROUTED`
3. **Get Records** `Lookup_Rooftop` — Object: `Rooftop__c`; condition `Name = {!var_Route.Rooftop__c}`; store in `var_Rooftop`.
4. **Assignment** `Apply_Route` — sets:
   - `Rooftop__c` = `{!var_Rooftop.Id}`
   - `Assigned_Batch__c` = `{!FSA_Prefix__c} -R` (literal prefix + "-R"; the trigger replaces
     the slot digit).
5. **Save** the flow as:
   - **Flow Label**: `Lead Enrich Rooftop`
   - **Flow API Name**: `Lead_Enrich_Rooftop`
   - **Folder**: any (no folder needed for record-triggered flows). Leave **Active**
     unchecked.
6. **Export the Flow XML** (Setup → Flows → next to the flow name, **View Details →
   Download → Metadata XML**). Save the file as
   `force-app/main/default/flows/Lead_Enrich_Rooftop.flow-meta.xml` in the repo and
   tell the agent **done**. (Do not export other settings.)

#### Why the round-robin is Apex, not Flow

Apex `(before insert) trigger` calls the existing `LeadRoundRobin.nextSlot` invocable
pattern. This cannot run in a before-save Flow because Salesforce restricts before-save
flows to Assignment/Decision/Get Records/Loop. Putting the round-robin in a before
trigger keeps the Flow declarative and within the supported element set.

---

## 3. Flow activation approval gate (per MASTER_PLAN §7.5)

Follow these for **any** flow that mutates leads:

1. **Deploy inactive** to `ng-dev` (change set or `sf project deploy start` with status
   `Draft` in the XML).
2. **UAT pass**: walk `evidence/UAT/UAT_P2.md` Section 1 (web lead routing). Confirm
   the batch label is set, the rooftop resolves, and the owner is round-robined.
3. **Activate in `ng-dev`** (Flow Builder → Activate). Record the activation in
   `metadata-log/README.md` under "User/License Changes" table:
   `2026-10-08 | ng-dev | Activated Lead_Enrich_Rooftop v1 (routing + round-robin) | P2-01 | <your initials>`
4. **Validate-only deploy to `ng-demo`** (per Phase 2 ng-demo gate) and re-run
   the same UAT. Then activate there. The `metadata-log` activation entry for
   ng-demo is the second signature.
5. **Do not** modify or re-deploy an active flow without a new owner approval. Edit
   as a new version; the old version stays active until the new one is activated.

---

## 4. Consolidated click order (do in this order)

1. **Step 0** — create the five public groups (Setup → Public Groups → New).
2. **Step 1a** — build `Pipeline by Stage` report; save into `NG_01_Pipeline`.
3. **Step 1b** — build `Lead Source Effectiveness` report (with the row-level
   `Converted_Flag` formula + the `Conversion %` summary formula); save into `NG_02_Leads`.
4. **Step 1c** — build `Open Opps by Sales Staff` report; save into `NG_01_Pipeline`.
5. **Step 1c-share** — share each folder per the table above (`PG_All_Sales`).
6. **Step 1c-dashboard** — build the `Sales Pipeline Snapshot` dashboard in
   `NG_Sales` with the three components; **Save**; **Done**.
7. **Step 1c-viewer** — open the dashboard, click the **gear icon**, set
   "View dashboard as → The dashboard viewer", Save.
8. **Step 2b** — build the `Lead_Enrich_Rooftop` record-triggered (before-save)
   Flow in Flow Builder per §2b.
9. **Step 2b-export** — export the Flow metadata XML; place at
   `force-app/main/default/flows/Lead_Enrich_Rooftop.flow-meta.xml`; tell the
   agent **done**. (Agent will commit the matching before-trigger Apex for the
   round-robin slot at the same time.)
10. **Step 3** — activation gate: UAT pass, activate, `metadata-log` entry, then
    tell the agent **done**.

When you finish the whole list, reply **"done"** and I will:
- retrieve the reports and the dashboard into source,
- validate the dry-run with tests and the CI workflow,
- re-run the round-robin Apex trigger to match,
- produce the Phase 2 exit report and the M1 gate report.

---

## 5. References used in this checklist

- Salesforce Help, "Flow Types" — before-save element restrictions
  (https://help.salesforce.com/s/articleView?id=flow_concepts_type.htm)
- Salesforce Help, "Dynamic Dashboards"
  (https://help.salesforce.com/s/articleView?id=analytics.dashboards_dynamic_overview.htm)
- Salesforce Help, "Share a Lightning Report or Dashboard Folder"
  (https://help.salesforce.com/s/articleView?id=analytics.rd_folders_share_enhanced.htm)
- Salesforce Help, "Summarize Report Data" and "Build Custom Summary Formulas"
  (https://help.salesforce.com/s/articleView?id=sf.building_custom_summary_formulas.htm)
- Salesforce Dictionary, "How to: Activation" (https://salesforcedictionary.com/how-to/activation)
- DEMO_ORG_MASTER_PLAN.md §7.5 (Flow activation gate) and §5.5 (folder convention)
- DEMO_ORG_DATA_MODEL.md §3.15 (Staff__c) and §7 (Opportunity field set)
