# Remaining acceptance and Phase 5 readiness — 2026-10-20

> Historical investigation. Owner subsequently retained every original P5-01…20 criterion,
> SEED-98 and the P2-03 screen Flow. Earlier deferral/native-form recommendations below are
> superseded, not approved exceptions. Current implementation status and Phases 6–8 roadmap:
> `docs/planning/P2_P5_IMPLEMENTATION_2026-10-20.md`.

## Scope and decision

Investigation used `ng-demo` only (`00Daj00001Ae3iWEAR`). Salesforce actions were
read-only SOQL, GET requests, and Metadata API retrieval. No deployments, record writes,
persona changes, commits, staging, or pushes occurred in this work package.

Completed Quote Builder remediation, Manager/VP/Finance UAT, and Sales Rep UAT remain
accepted at their documented scope. Phase 2 remains UNVERIFIED. Phase 5 has real
development and acceptance work remaining; a successful canonical load is not its exit gate.

## A. Empty Leads

### Confirmed evidence

Live Lead aggregates contain 152 records: 130 canonical Leads owned by
`005aj00000feqbNAAQ` (admin, no role), plus 22 owned by `005aj00000fH2LxAAK`.
All 152 have `IsConverted=false`. None is owned by `ngpersona` or a queue.

Live Metadata API retrieve `09Saj00000lhmHdEAI` returned:

```xml
<sharingModel>Private</sharingModel>
```

`Lead.sharingRules` is empty. `LeadShare` contains only owner shares: 130 admin rows,
22 other-owner rows. The available All Open Leads list is already organization-scoped:

```json
{
  "scope": "everything",
  "query": "SELECT Name, Company, toLabel(StateCode), Email, toLabel(Status), CreatedDate, Owner.NameOrAlias, IsUnreadByOwner, Id, RecordTypeId, LastModifiedDate, SystemModstamp, Owner.Id, OwnerId FROM Lead WHERE IsConverted = false AND (NOT Status like '%closed%') ORDER BY Name ASC NULLS LAST, Id ASC NULLS LAST"
}
```

The administrator-visible ListView inventory has no separate `All Leads` definition;
the exact user-selected/private view cannot be reconstructed without its browser URL.
That does not change the record-access diagnosis: a read-only `UserRecordAccess` check
against the actual `ngpersona` user covered every existing Lead:

```json
{
  "userId": "005aj00000gE0b3AAC",
  "leadCount": 152,
  "accessRows": 152,
  "readable": 0,
  "editable": 0
}
```

The `NG_Sales` profile has Lead Read/Create/Edit/Delete, no View All/Modify All, and
Lead tab `DefaultOn`. `PS_Sales_Rep` also has Lead CRUD. This is not a tab or missing
Lead-object-Read defect, and not the Loyalty `Mine` list-view defect.

Current persona remains baseline `VP_Sales`, `NG_Sales`, `ManagerId=null`, no persona
PSGs. Neither owner is below its role, and there are no Lead shares to it. A role does
not give visibility into admin-owned private records when admin has no role.

### Conversion and routing preconditions

`PermissionsConvertLeads=false` on `PS_Sales_Rep`, `PS_Sales_Manager`, the `NG_Sales`
profile PermissionSet, and `NG_Lightning_Experience_Access`. Existing `PS_Sales_Rep`
already grants CRUD on Account, Contact, Opportunity, and Test Drive. Conversion is a
separate permission gap, not an explanation for empty lists.

No active user currently holds `Sales_Rep`; no user is assigned `PSG_Rep`. The inbound
Lead queue contains the Sales Rep role group. `LeadRoutingHandler` resolves active sales
users by role, otherwise uses the queue. The smallest testable correction is therefore:

1. Prepare a conversion-only permission grant, added to the existing rep PSG.
2. After approval, activate rep persona for the new Phase 2 run.
3. Create new controlled UAT Leads owned/routed to the rep or its queue. Preserve all
   canonical and historical Lead owners; do not change OWD or add broad sharing.

No Lead list-view change is prepared because the available All view already uses
`Everything`, and sharing denies all existing records independently of its filters.

### Minimum meaningful Phase 2 acceptance

- Verify actual rep identity, PSG, `ConvertLeads`, no bypass, and owned/queue Lead access.
- Execute the existing ten-row FSA table in `evidence/P2/cross_verification_report.md`
  §3.3: eight mapped rows and two unmatched rows; record Rooftop and batch results.
  The 80/20 metric is postal/rooftop consistency, not rep/queue ownership. Preserve the
  documented cross-transaction round-robin exception; do not claim durable rotation.
- Discover an owned Lead in All Open Leads; qualify it using the statuses allowed by
  its actual record type. Capture owner, qualification result, and follow-up Task.
- Convert one new UAT Lead to a new UAT Account/Contact/Opportunity. Never select a
  canonical Account/Contact/Opportunity: the existing after-conversion trigger clears
  `Seed_Tag__c` on linked converted records. Verify `IsConverted`, converted IDs, and no
  propagated seed tags. Do not use a historical Lead for this destructive lifecycle step.
- Book a future Test Drive for the new Contact and an authorized available Vehicle;
  prove overlap rejection and a valid non-overlapping slot. Capture follow-up Tasks,
  confirmation-email result or explicit deliverability exception, and counters.
- Move the new Opportunity through Prospecting, Qualification, and Test_Drive; verify
  `Previous_Stage__c` and `Stage_Last_Changed__c`. Exercise reservation and blocked second
  reservation on a new controlled Vehicle if required for full P2-06 sign-off.
- Run Lead Source Effectiveness and Sales Pipeline Snapshot for actual user scope;
  complete tester/date/result/screenshots and explicit exceptions in UAT_P2.

Live FlowDefinition inventory contains only active `Lead_Enrich_Rooftop`, active
`Trade_In_Appraisal`, inactive `Test_Screen_Flow`, and the inactive standard report-export
flow. `TestDrive_Book_Screen` is absent. Source has Test Drive booking guards and forms,
but those do not prove the exact P2-03 screen-flow requirement passed. Owner must approve
native Test Drive form as an acceptance exception or authorize a separately scoped screen
flow. No new flow is prepared under this investigation.

## B. DM_DealDesk

### Confirmed live context

GET `/analytics/dashboards/01Zaj00000BRzXJEA1` returned `SpecifiedUser`, running user
`005aj00000feqbNAAQ` (admin), no dashboard filters, no component errors, and refresh date
`2026-10-20T06:05:08.000+0000` for all three components. Admin profile has View All Data.
All reports use organization scope and the current fiscal quarter, Application Date
2026-10-01 through 2026-12-31.

| Metric | Source report | Filters / measure | Current result |
|---|---|---|---|
| Financing Approvals Pending | `00Oaj00000UhW1lEAF` | Submitted AND (Manual Exception OR Sub Prime); row count | 0 |
| Financing Decline Rate | `00Oaj00000UhW1nEAF` | Approved OR Funded OR Declined; declined flag sum / RowCount | 0 rows; formula null; dashboard displays 0.00% |
| Average Days to Fund | `00Oaj00000UhW1mEAF` | Funded; average Days_To_Fund | 0 rows; dashboard displays 0 |

Live aggregate:

```json
{"Status__c":"Draft","n":63,"firstApplication":"2026-06-16","lastApplication":"2026-10-20","avgDays":58}
```

Both `data/csv/15-financing.csv` and its resolved CSV contain 60 Draft rows. Direct SOQL
with the pending/Funded filters returns zero qualifying records; source reports run via
GET also return zero rows. Opportunity counts/amounts do not drive these financing metrics.
The zero displays are expected for this data, not evidence of broken visibility, stale
refresh, or a calculation defect. Decline rate with zero denominator is undefined; a zero
display is not proof of a real 0% business rate. Draft rows can carry dates, but the funded
metric correctly excludes them.

No dashboard correction is needed for this observation. Do not alter financing lifecycle
data or approval state to manufacture a nonzero dashboard. Non-empty metric correctness
remains separate evidence work; UI access UAT remains passed. The pending report is a
Submitted/exception-candidate proxy, not a direct count of ProcessInstance work items.

## C. Phase 5 evidence

### P5-03 storage

Supported read-only GET `/services/data/v68.0/limits` returned:

```json
{"DataStorageMB":{"Max":5,"Remaining":1},"FileStorageMB":{"Max":20,"Remaining":20}}
```

Nominal API arithmetic is 4 MB consumed. The resource reports whole-MB figures, not an
exact byte reading; do not carry forward the historical 3.00 MB figure as current usage.
Owner still needs Setup → Storage Usage, showing org identity, capture date, Data Storage
used/limit/percentage and breakdown. Save `evidence/P5/storage.png`; the exact displayed
used figure must meet ≤4.0 MB. File Storage alone does not satisfy P5-03.

### P5-05: reject the proposed 16 inserts as acceptance evidence

Live ledger is still 20 placeholder rows, all Mixed / Loaded, Inserted=0, Failed=0,
Loaded_At=2026-10-01. No changes were made.

The proposal's arithmetic can total 2,085 only by choosing 1,013 for its inconsistent
steps-1–12 aggregate, then adding 1,072 for steps 13–27. This does not establish per-batch
insert counts or completion timestamps. Specific evidence defects:

1. Contrary to the proposal, wrapper evidence for steps 1–12 exists in
   `20261018T030350Z-wrapper.log` (lines 30–58), including three separate Lead chunks.
   One aggregate timestamp is not a row per actual Bulk API batch.
2. There are 59 wrapper files, 26 `detected mode: execute` entries and 15 strict-success
   lines. The proposal's 31-file/25-run/19-success account is not supported by current logs.
3. Wrapper filename timestamps are start/snapshot times, not proven batch completion
   times. Canonical record CreatedDate cannot replace missing completion times.
4. `20261018T054204Z` processed Campaign 3/5, then `20261018T054410Z` upserted 5/5 with
   3 existing rows. Five successful upserts is not evidence of five new inserts.
5. Proposed QuoteLineItem job `750aj00001HpBiKAAV` appears in earlier failed-accounting
   log `20261018T042819Z`, not in the final successful `20261018T043636Z` log.
6. Calling QuoteLineItem object `Consent` is false attribution. Use a truthful object
   category or Mixed with exact object in Notes; do not choose the closest unrelated value.
7. Proposed rows do not establish the required per-batch anchor date/storage reading.
   Current storage cannot be retroactively called historical per-batch storage.
8. Adding 16 `SEED-EXEC-*` ledger records changes the expected 20 ledger rows to 36 and
   adds nonmanifest SEED tags. Current canonical gate 8/10 assumptions would be violated.
9. `SEED_VERSION.txt` contains EXPECTED_TOTAL_RECORDS=2123, final LOADED_RECORDS=2085,
   old blocked-step markers, and PHASE_5_STATUS=COMPLETE. Data plan says 1,835 clean plus
   250 activities plus 30 deferred legacy = 2,115. Backlog P5-03 still says 1,843 clean.
   These competing baselines need reconciliation; new ledger rows cannot resolve them.

Recommendation: preserve placeholders as seed fixtures, reject this insert proposal, and
prepare an evidence-backed reconciliation specification distinguishing inferred snapshot
totals from actual execution batches, inserted/updated/failed records, start/completion
times, and unknowns. Keep P5-05 open. Future loader telemetry must record actual job outcomes;
do not reload historical data just to create new logs.

Existing `verify_gates.txt` reports 14/14 for its narrowed canonical/deferred scope. Its
gate 9 checks only ledger Status, not the backlog's matching-count requirement. The report
explicitly says the full 2,115 envelope is not satisfied. It is not proof of Phase 5 exit.

### SEED-98

P5-07 requires 30 intentionally schema-invalid fixtures: 10 malformed Contact phones,
8 missing Contact postal codes, 6 invalid Trade_In VINs, and 6 mixed-case duplicate Contact
emails. Load with bypass, revoke bypass, log both, document in `docs/DATA_QUALITY.md`, and
verify counts/screenshot. Dependencies: P5-02/P5-03; consumers P5-09 and P5-13.

Read-only counts show zero SEED-98 Contacts and zero SEED-98 Trade-Ins. Generator has a
30-row mixed CSV, but loader explicitly skips Legacy as a separately loaded batch.
`docs/DATA_QUALITY.md` is absent. Current `SEED98_Defect_Accounts` report targets Accounts,
whereas the specification's fixtures are Contacts and Trade-Ins. The current duplicate
audit is a Contact listing, not verified defect/pair detection. Those reports cannot be
accepted as satisfying the missing fixture merely by inserting 30 rows.

Recommend explicit deferral of P5-07 and dependent SEED-98 portions of P5-09/P5-13 for the
connected dealership demonstration. It demonstrates imported-data quality, not Lead-to-sale
functionality. It remains mandatory for an unqualified Phase 5 acceptance unless owner
approves an exception. Do not implement or load under this work package.

## D. Local corrections and Git scope

Prepared, not deployed:

| File | Change | Impact |
|---|---|---|
| `permissionsets/PS_Lead_Conversion.permissionset-meta.xml` | New ConvertLeads-only grant | No record sharing, object CRUD, FLS, View All or Modify All grants |
| `permissionsetgroups/PSG_Rep.permissionsetgroup-meta.xml` | Add the conversion set to existing PS_Sales_Rep membership | Takes effect only for assigned rep PSG; baseline restore removes that PSG |
| `reports/NG_06_Loyalty/Loyalty_Tier_Distribution.report-meta.xml` | Replace stale distribution/grouping text; explicitly preserve live current-interval Join Date filter | No changes to rows, grouping, balances or sharing |

Paths above are under `force-app/main/default/`. Supplemental permission set avoids
redeploying the already known unrelated `PS_Sales_Rep` source/live differences. No Lead
list-view, dashboard, profile, OWD, sharing rule, routing code, or historical record changed.

Live Loyalty report returns 12 current-quarter members. Canonical all-date query returns
Bronze 39, Silver 18, Gold 9, Platinum 4. Report description was presenting an all-date
canonical expectation without explaining its date filter. Description now states that rows
depend on selected Join Date range and viewer access; canonical distribution is a separate
acceptance query. Current report accessibility UAT remains passed.

Future commit candidates with existing deployment/test/owner evidence:

- P3-DEF-01's two tracked Apex file diffs, its remediation record, and scoped UAT evidence.
- Two standalone Delivery/Loyalty `All.listView-meta.xml` files and their deployment evidence.
- Relevant status/handoff hunks, after removing or marking stale backlog status text.

The two object container diffs are newline-only and are not needed for a list-view commit.
`PS_Sales_Rep` mixes deployed AccountId FLS and an undeployed tab change; exclude it.
Do not stage whole folders: `QuotePricingService.cls` and related CP2 prerequisites are
still untracked, as are unrelated reports, loader code, private-path logs, backups, CSV
results and configuration. A narrow patch can be reviewed independently, but a clean-checkout
release claim requires reconciliation of these prerequisites. No files were staged.

The three new/prepared metadata components above are not yet deploy-validated or UAT-accepted.
Keep them separate from a completed-work commit unless intentionally labelled local preparation.

## E. Actual remaining phase scope

### Phase 5

| Items | Evidence / remaining work |
|---|---|
| P5-01 generator | Source and deterministic/count tests exist; deterministic same-anchor checksum evidence is not archived. Do not regenerate canonical CSVs during closeout. |
| P5-02 loader | Source and strict result tests exist; one full second-load/idempotency acceptance artifact is absent. Existing retries are not the full criterion. |
| P5-03 load | Canonical 2,085 documented; full volume baseline conflicts and 30 legacy rows deferred. Current exact Storage Usage screenshot/count artifact needed. |
| P5-04 integrity | Explicit zero-orphan lookup/MD artifact is absent; the 14-gate summary is not a full relationship audit. |
| P5-05 ledger | Real functional/evidence gap described above, not just a missing screenshot. |
| P5-06 edge cases | Generator embeds several BAD scenarios; separable SEED-99 file is skipped by main loader. BAD-01…10 scaled counts/resetability are not proved by gate 8. |
| P5-07 legacy | Deferred; proper per-object loader, truthful reports, bypass evidence, and DATA_QUALITY doc needed if implemented. |
| P5-08 gates | Script and recorded canonical 14/14 exist; reconcile gate definitions with full backlog and real ledger checks. No broad rerun made here. |
| P5-09 DQ reports | Eight report definitions exist, but expected-count and drift evidence are incomplete; SEED-98 Account report targets the wrong objects. No delete-for-drift action authorized. |
| P5-10 inventory | Report present; grouping uses rooftop/model, not directly make; verify >60/>120 distributions and required make grouping before acceptance. |
| P5-11 service | Report present; verify exactly 12 overdue visits under agreed anchor/date semantics. |
| P5-12 loyalty | Report opens; current-quarter 12 is not all-date 70 distribution evidence. Canonical SOQL matches 39/18/9/4; capture unsaved report filters and matching totals for sign-off. |
| P5-13 duplicate audit | Present Contact listing does not establish 8 duplicate pairs / 6 legacy email findings; depends on P5-06/P5-07. |
| P5-14 executive dashboard | `DM_Exec_OperationsOverview` absent from live NG_Sales dashboards and source; actual development remains. Dynamic by role; pipeline, aging, SLA, loyalty, CSI proxy; depends P5-10…13. |
| P5-15 manager dashboards | Sales/Service/Finance fixed-user operations dashboards are not evidenced. Existing PipelineSnapshot, QuoteHealth and DealDesk do not prove all three manager dashboards. Depends P5-14. |
| P5-16 report types | Three requested joined report types exist in source; builder usability screenshots/sign-off still needed. |
| P5-17 reset | `scripts/reset.sh` absent. Child-first reset, purge, reload, storage check and controlled execution are actual development/acceptance work. Backlog requests ng-dev execution; current org restriction forbids it. |
| P5-18 snapshot gate | No reset entry point to enforce fresh snapshot; refusal behavior and evidence remain. Depends P5-17. |
| P5-19 burst | CSV exists; special batch is skipped; load/teardown/storage proof absent. Destructive protocol requires separate explicit approval. |
| P5-20 loaded docs | Source plan is marked loaded but cannot claim Phase 5 exit while remaining criteria are open. Reconcile version/count/status documents. |

Phase 5 exit is a consistent edge-case-rich dataset under 4 MB and dashboards that tell a
true story. Outstanding dashboards, ledger, reset/snapshot guard, and expected-count reporting
are development gaps. Screenshot archival and explicit agreed exceptions are evidence gaps.

### Phase 6 — service, cases, post-sale

| IDs | Required scope, dependencies and acceptance |
|---|---|
| P6-01 | Service scheduling; capacity flow vs Rooftop service capacity and new-visit timing; depends P1-16; reject over-capacity booking. |
| P6-02…05 | Case from visit, Q_Service_Intake routing; high-priority unanswered 4-hour escalation and Escalated_On stamp; contact/vehicle/prior-visit linkage; vehicle visits/cases/mileage history. Depends P6-01, queue, then Case intake; verify queue, escalation, timeline and seeded related lists. |
| P6-06…08 | Rule-based service/sale point accrual; nightly LoyaltyTierEvalBatch; redemption and Loyalty_ExpiryBatch; nonnegative balance. Depends P4-08 and validation rules; assert point math, tier moves and rejected overdrafts. |
| P6-09 | Fixed loyalty liability/tier dashboard and dynamic-by-role DM_Service_Operations; third/final planned dynamic slot; depends P6-05…08; advisor/manager scope differs. |
| P6-10…13 | Loyalty seam doc; repeat buyers report (service + new Opportunity, depends P5-12); consent-gated campaign membership; nurture seam doc. Prove report rows and nonconsented exclusion; label simulations. |
| P6-14…16 | Verified entitlements/milestones (4-hour response, 48-hour resolution example), about 10 Knowledge articles searchable/attached to Cases, Service Console/sales coexistence. Depend capability verification and Case intake/history; historical capability notes are not fresh ng-demo verification. |
| P6-17 | ≥90% on accrual, tier, redemption and capacity; depends P6-01/P6-06…08. |

Exit: post-sale lifecycle, SLA/Knowledge demo, honest paid-product seams. Existing service
objects, queues, enrollment and seed records are foundations, not proof that these items passed.

### Phase 7 — developer depth, integrations, governance and polish

| IDs | Required scope, dependencies and acceptance |
|---|---|
| P7-01…02 | Filterable vehicle photo gallery with Reserve (depends P2-06/P7-22), and interactive trade/payment widget (P4-01/P3-01); reserve without reload, correct math, errors/loading handled. Existing calculator is a foundation; avoid duplicate builds. |
| P7-03…06 | Named Credential VIN decoder mock callout with timeout/error tests; API contract; Vehicle_Reserved__e and gallery subscription; honest CDC/Pub-Sub mapping. Callout precedes contract, gallery precedes event. |
| P7-07…08 | One-handler-per-object, recursion/bulk-safe trigger architecture honoring bypass; inventory-age/counter reconciliation Queueable; 200-row/bypass tests and stopTest results. |
| P7-09…14 | Governance pack, honest tech debt, permission audit, optional verified territory tree, org strategy, complete simulation seam index. Depends foundation/security matrix, conflict debt, P3-11/P4-12/P6 seam docs. Do not reopen accepted behavior without a defect. |
| P7-15…16 | Capability-gated Agentforce service agent + Prompt Builder (labelled triage fallback), and Data Cloud ingestion/identity resolution. Depend P6 Case/Knowledge/history and live eligibility/licensing; not automatically authorized by planning. |
| P7-17 | One-command dry-run + Apex + DQ regression from clean checkout; depends P5-08 and CI. |
| P7-18 | Small authenticated Experience Cloud owner site, 1–2 external users, depends licence/security verification and P6 history. Multi-Framework React is only a conditional unapproved evaluation; no site enablement authorized. |
| P7-19…21 | Automotive Cloud mapping document only; actual-state README after regression; full admin/developer/analyst/support/architect demo scripts, every script starts Activate persona. |
| P7-22…23 | About 30 fictional logo-free WebP photos (~50 KB each), NG_VehicleImages resource/model image path/formula; graceful vehicle header with/without photo. Depends schema/storage verification, then gallery/header. |

Exit: four skill domains demonstrable from clean tag with honest labels. Phase 7 is not just
UI polish. Feature availability and external-user permission design are real dependencies.

## Consolidated next authorization package

1. Deploy only `PS_Lead_Conversion`, `PSG_Rep`, and the Loyalty report after scoped
   check-only succeeds. Permission impact: ConvertLeads for rep PSG only; no new record
   visibility. Exclude the drifted `PS_Sales_Rep`, all profiles/sharing, and completed P3 classes.
2. Approve a separate Phase 2 owner run: rep activation/restoration with pending-approval
   guards; ten new UAT Leads using the established table, one conversion to new UAT records,
   two successful Test Drive bookings and one rejected overlap; use only a controlled new
   Vehicle if reservation writes are needed. Use `UAT-P2-20261020-*` identifiers outside
   canonical `SEED-*` ranges. No canonical owner changes or existing-record
   conversion. First choose native-form P2-03 exception or separately approve the screen flow.
3. Keep ledger inserts and SEED-98 deferred. Approve truthful ledger/version specification
   work before authorizing any record changes. Do not reset, reload, purge, burst, or fabricate
   nonzero dashboard metrics for acceptance.
4. If desired, authorize explicit-file/hunk commits of reviewed completed P3/list-view/UAT
   changes, plus a separate local-preparation commit. No push; no broad staging; reconcile
   untracked CP2 prerequisites before claiming a clean-checkout release.

Remaining Phase 5 implementation should proceed in independently testable blocks:
(1) evidence/ledger/volume baseline and expected-count reports; (2) executive and fixed-user
manager dashboards; (3) reset/snapshot/burst safeguards, locally verified before any execution.
Each block needs its own precise scope and acceptance evidence before live actions.

## Short owner browser checklist (after applicable approval)

1. As the future rep, open All Open Leads, discover owned/queue UAT records, qualify and
   convert one new Lead; record resulting IDs and actual user identity.
2. Book Test Drive, show rejected overlap and free-slot success, then verify Opportunity
   stages/tasks; capture the approved reservation check if in sign-off scope.
3. Open the three DealDesk source reports with the dashboard. Confirm zero qualifying rows,
   and record decline rate as N/A when denominator is zero; do not label this 0% business rate.
4. Capture Setup → Storage Usage Data Storage total/limit/date as `evidence/P5/storage.png`.
5. Open Loyalty report; temporarily select All Time and canonical seed filter without
   saving; verify 39/18/9/4, then restore view filters. Capture current-quarter 12 separately.

No new Apex tests or deployment check-only was run during investigation. Only targeted GET
report execution, SOQL, metadata reads, and local XML/diff validation were used.

## Local validation

`xmllint --noout` succeeded for the conversion PermissionSet, rep PSG, and Loyalty report.
XPath checks on the new PermissionSet returned:

```text
ConvertLeads
0
```

The second result is the number of objectPermissions/fieldPermissions entries. `git diff
--check` returned no errors, and `git diff --cached --name-only` returned no staged files.
Scoped live comparison confirms the Loyalty report retains the existing current-interval
Join Date filter and grouping. Salesforce check-only, effective conversion access as rep,
and browser acceptance of the proposed grant remain pending owner authorization.
