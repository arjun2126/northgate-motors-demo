# D08 local presentation corrections — owner approval package

## Disposition

Local corrections prepared under the owner's scoped October 28 authorization. **Not deployed,
not browser-verified, no D08 closure or phase acceptance.** No Salesforce access was needed.
The current UAT register supersedes stale handoff headers; do not reopen CP2, owner portal
smoke passes, D01–D04 diagnoses or D15 reconciliation. Existing dirty source was patched in place
only at the presentation hunks identified below; no Apex, pricing, permission or record changes.

| Finding | Source-supported local action | Limit / remaining evidence |
|---|---|---|
| D08-a print layout | Quote Summary names/line descriptions wrap; screen grids wrap; print-only two-column summary, full-width fixed-layout line table, visible overflow, repeating header, row-level break avoidance, hidden action/help controls and tighter spacing | Partial component-level correction. `handlePrint` still calls `window.print()`. Scoped LWC CSS cannot suppress Salesforce shell/ancestor overflow or control native Quote PDF templates; no guaranteed one-page output for arbitrary lines. Need actual preview/screenshot/paper settings to isolate any remaining shell/native-PDF issue |
| D08-b conflicting finance notices | One conditional state-aware notice, suppressed during loading/errors; explicit existing/new/saved/ambiguous/neutral copy. Server save errors remain authoritative and no stale new banner is rendered alongside them | Source exposes a duplicate-Draft rejection string while loaded mode can still be new; previously two template branches were mutually exclusive, so two simultaneous informational branches are not independently reproduced. This change covers the contradictory error/banner and stale post-save notice paths, not a proven live root cause. No automatic open, retry, draft mutation or save contract change |
| D08-c Executive readability | Widen/nest no tiles: two 6-column metrics per row, extra height for footers, full-width CSI; report references/formulas/footer caveats/type preserved | Original source rectangles did not mathematically overlap; the owner saw content overlap/unreadability. Wider geometry is a conservative local correction, not proof of rendered fix. Requires actual dashboard/viewport validation |
| Numeric-only lists | Six new `NG_Overview` views with existing contextual fields; retain Name as link, no renaming/auto-number changes, no replacement of existing All or Recently Viewed | Metadata candidate only. Existing Delivery/Loyalty All source is Name-only; other live views not inspected. Select/pin the new view manually after approved deployment. Actual readers still require existing FLS/lookup target Read; never add permissions for missing columns |
| Photo mismatch D08-d | No asset/path/data changes | Existing inventory explicitly uses illustrative licensed stock for fictional models, not exact identity/colour. Need exact Vehicle ID, component, expected body/appearance, image URL and screenshot to distinguish a bad mapping from accepted stock illustration. No plausible replacement can be selected safely from this report alone |
| Empty finance dashboard | Exact UI/footer proposal below; no Deal Desk/report edit packaged | Source reports intentionally filter Submitted exceptions, decided statuses, or Funded dates. Empty result sets alone are not defects. No eligible record creation/status updates/filter broadening/zero substitution |

## Exact local deployment candidate

`manifest/d08-presentation-local.xml`, API 68.0, **9 metadata components**:

1. `LightningComponentBundle:quoteSummary` — changed HTML, new CSS; JS and metadata descriptor unchanged.
2. `LightningComponentBundle:financeApplication` — changed HTML/JS notice rendering/getter only.
3. `Dashboard:NG_Sales/DM_Exec_OperationsOverview` — geometry only.
4. `ListView:Financing__c.NG_Overview`
5. `ListView:Trade_In__c.NG_Overview`
6. `ListView:Delivery__c.NG_Overview`
7. `ListView:Loyalty_Member__c.NG_Overview`
8. `ListView:Loyalty_Transaction__c.NG_Overview`
9. `ListView:Consent__c.NG_Overview`

No CustomObject/CustomField/PermissionSet/Profile/Sharing/Report/Apex/Flow/asset/site/page-activation
or destructive members. Deploy only selected source from `force-app/`, never records. The manifest
does not deploy all of each parent object. No deployment command was issued. Owner must separately
approve server check-only validation, then deployment; offline checks are not compiler/schema proof.
The 370-test suite must not be repeated for these local UI changes.

**Working-tree caveat:** Finance JS and some dashboard/bundle source already contained earlier
uncommitted project work. A bundle deploy includes its complete files, not just these hunks;
owner review must cover those pre-existing contents before approving exact source. The baseline
records this task's starting bytes, not HEAD or proof of live source parity. No user changes were
reverted or overwritten. There is no Quick Deploy ID for this candidate.

### Executive dashboard: exact native layout proposal

Open **DM_Exec_OperationsOverview → Edit** only in a separately approved configuration window.
Match the packaged 12-column grid (`rowHeight=100`; zero-based coordinates below); do not
change dashboard type, running user, reports, aggregates, stale/CSI semantics or filters.

| Header | Column | Row | Width | Height |
|---|---:|---:|---:|---:|
| Pipeline Amount | 0 | 0 | 6 | 3 |
| Inventory Aged Over 60 Days | 6 | 0 | 6 | 3 |
| Overdue Service Visits | 0 | 3 | 6 | 4 |
| Loyalty Members | 6 | 3 | 6 | 4 |
| CSI Proxy (Recorded Scores) | 0 | 7 | 12 | 4 |

Prefer the reviewed metadata candidate over ad-hoc editing. This table is a UI fallback/proposal,
not a record of settings applied. Confirm live dashboard identity/source first so owner UAT
changes are not overwritten. Keep the `LoggedInUser` type and both 24-hour cache disclaimers.

### List-view UI proposal and exact columns

After approved deployment, open each object tab → list selector → **Northgate Overview**
(`NG_Overview`). Optionally pin for that user's session only after approval. Do not edit Recently
Viewed/Search Layouts or overwrite existing user-managed views. New view `filterScope=Everything`
means all **already accessible** rows, not View All/Modify All; there is no `sharedTo` grant in
the candidate. Verify native view availability and visibility behavior in the target org first.

| Object | Columns, in order (API names) |
|---|---|
| Financing__c | NAME, Opportunity__c, Applicant__c, Status__c, Amount_Financed__c, Application_Date__c |
| Trade_In__c | NAME, Contact__c, Opportunity__c, Trade_Make__c, Trade_Model__c, Status__c, Trade_Equity__c |
| Delivery__c | NAME, Buyer__c, Opportunity__c, Vehicle__c, Status__c, Scheduled_Date__c, Completed_Date__c |
| Loyalty_Member__c | NAME, Member_Number__c, Contact__c, Status__c, Tier__c, Points_Balance__c |
| Loyalty_Transaction__c | NAME, Loyalty_Member__c, Type__c, Points__c, Transaction_Date__c, Expiry_Date__c |
| Consent__c | NAME, Contact__c, Channel__c, Purpose__c, Status__c, Revoked_On__c |

No Annual Rate, consent Evidence, contact email or new computed display fields added. A hidden
field stays hidden; a view is not a reason to change FLS. These internal list candidates do not
repair portal transaction Read/FLS D06 and do not activate loyalty.

### Empty finance dashboard — exact UI correction proposal, not packaged/applied

Target **DM_DealDesk** (not every Finance dashboard). No source totals or report semantics change.
In an approved owner configuration window: Edit → select each named metric → add the following
footer through the native component editor. If footer editing is unavailable in the live editor,
stop and request the owner-selected presentation path; do not invent an unsupported empty-state
flag, custom dashboard component or formula returning zero.

- **Financing Approvals Pending:** `Submitted exceptions only, within the report date filter. No eligible rows may display zero or no data; this is not all Draft applications.`
- **Financing Decline Rate:** `Approved, Funded and Declined applications only. No eligible decisions means no rate, not a 0% decline rate.`
- **Average Days to Fund:** `Funded applications with both dates only. No eligible dates means no average, not zero days.`

Keep the source report date filter visible during review. Do not change fixed running user,
folder/permissions, native component type, reports, filters or formulas. Do not click a data
publisher/scheduler. Need owner screenshot/reader/filter evidence before deciding if larger
tile geometry is necessary. These notes explain eligible populations without asserting that any
current empty report is correct or complete. **Not included in the nine-component manifest.**

## Focused validation and preservation

Raw receipts: `evidence/UAT/FULL_PROJECT_2026-10-28/D08_LOCAL/`.

CONFIRMED — `focused-ui.tap` raw excerpt:
```text
# tests 14
# suites 0
# pass 14
# fail 0
```

Command executed: `node --test scripts/tests/finance_launch_context.test.mjs scripts/tests/d08_quote_presentation.test.mjs`.
Existing four Finance launch tests remain intact; six new Finance notice tests and four Quote
state/static tests reuse the repository's Node VM/mocked-service pattern. No actual Apex calls.

CONFIRMED — `metadata-tests.txt` raw excerpt:
```text
Ran 4 tests in 0.007s

OK
```

Command executed: `python3 -B scripts/tests/d08_metadata_test.py`.
Checks geometry/nonoverlap, unchanged known report references/aggregates/type/caveats, six views'
existing-field columns/no grants and exact manifest. Before hashes also prove all pre-existing
captured Apex/classes, permission-set and Quote Builder bytes unchanged and only the four
intended pre-existing source files changed. New CSS/list metadata are additional files.

**Skipped / not verified:** actual browser/print/PDF rendering, deployed modal behavior, dashboard
readability, list view visibility/field access, live source parity, LWC compilation and Salesforce
schema validation/check-only deployment. Existing local tooling tests state/static contracts,
not Salesforce DOM, SLDS shadow internals or native dashboard rendering. No full Apex rerun,
deployment, live data write, permission change, activation, Git commit or push.

## Regression risks and owner acceptance

- Print CSS may produce different page counts depending on browser, shell width, paper and line
  count; long line rows still legitimately require pages. Verify desktop/mobile and Letter/A4,
  multi-line and long names; compare all CP2 figures without saving/repricing historical Quote.
- Single Finance notice deliberately disappears when an authoritative error is shown. Existing
  backend “opening it instead” text is not changed and still does not automatically navigate;
  actual duplicate-Draft/opening behavior is a separate functional question, not fixed here.
- Dashboard becomes taller; verify smallest supported viewport and footer text, with viewer scope
  unchanged. No assertion that increased dimensions alone cure the reported overlap.
- Views are additive and must be selected; FLS/lookup target access can remove columns. Do not
  solve absent columns by permission escalation. Existing Name auto-numbers remain unchanged.
- Deployment of whole bundles may include earlier owner work; compare exact source and live
  dashboard/view names before applying. Preserve owner's ongoing UAT data/settings.

Owner approval requested: review this exact nine-component scope, authorize targeted server
validation separately, then authorize deployment and actual-persona read-only presentation UAT.
Keep D08-a/b/c open until browser evidence; D08-d, empty-finance presentation proposal and all
unverified functional/data-quality concerns remain pending. No full project UAT acceptance.
