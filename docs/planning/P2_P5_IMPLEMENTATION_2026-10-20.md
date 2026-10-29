# Phase 2 remediation and original Phase 5 completion — 2026-10-20

> Latest continuation: `evidence/P5/continuation_2026-10-20.md`. Eleven offline checks pass;
> manager-access/SLA check-only `0Afaj00000oSg4LCAS` succeeds 5/5. Read-only native job
> reconciliation covers all 2,085 canonical IDs across 37 jobs. No deployment or data/persona
> write occurred in this continuation. Earlier Phase 2/5 real releases are recorded in
> `evidence/P5/release_uat_2026-10-20.md`. Failed-job sections below are historical.

## Owner decisions and boundaries

All original P5-01…P5-20 requirements, SEED-98 and its dependencies remain mandatory.
P2-03 requires `TestDrive_Book_Screen`; no native-form exception applies. Northgate has
eight implementation phases; Phase 8 remains on the roadmap. Earlier recommendations to
defer legacy or substitute a form are superseded. Completed P3 remediation and persona
UAT remain unchanged. This continuation made no Salesforce deployment, DML, persona switch,
reset, deletion, commit or push. Only ng-demo check-only was used.

## Local implementation and validation state

| Requirement | Local implementation | Remaining blocker/evidence |
|---|---|---|
| P2-02 conversion access | Four-component Phase 2 package deployed; self-contained conversion dependencies | Actual rep browser UAT remains pending |
| P2-03 screen booking | Deployed native Flow with lookup/date/duration/overlap/fault/confirmation handling | Runtime/browser acceptance pending; no Opportunity input |
| P2-04 overlap guard | Existing TestDriveBookingGuard/trigger reused unchanged; Flow pre-check includes Requested/Scheduled and strict overlap bounds | Rep browser free/conflicting/boundary cases still required |
| P2-14 UAT preparation | Genuine rep browser procedure prepared; admin setup attempt aborted before inserts and persona restored | Do not rerun setup as admin or disable its guard; owner must start a new window |
| P5-01 deterministic generator | Two isolated same-anchor runs compare 30 CSVs; new vehicle/service date fixtures retain all other fields in those files | Offline checks pass; canonical CSVs unchanged; anchor distributions do not prove live-clock counts |
| P5-02 loader | Existing dependency resolver/strict bulk accounting preserved | Full second-load/idempotency org evidence not performed; telemetry/write-through ledger still incomplete |
| P5-03/P5-20 count/version | Governing 60 Product2/12 Delivery allocation settled: 2,085 canonical + 30 legacy = 2,115; historical 2,123 labelled | Exact storage and mandatory legacy/full acceptance still outstanding |
| P5-04 integrity | Read-only lookup anti-join verifier prepared | Live query/schema validation, required-parent completeness and polymorphic Task/Event checks remain |
| P5-05 ledger | Native 37-job reconciliation: 2,085 inserts, 403 updates, 142 failed attempts; all 2,085 canonical IDs covered | Historical storage and 20-placeholder write model missing; final modification is not a completion timestamp; no ledger DML |
| P5-06/P5-09 findings | Read-only expected-count checks and local drift failure check | Actual BAD-01…10 fixture proof, report correlation, resetability and live drift evidence still open |
| P5-07 legacy | Resolved six same-account parent pairs and prepared separate 24/6 CSVs outside canonical files | Parent/data approval, bypass and duplicate-rule verification pending; expected Contact rule not found live |
| P5-08 release gates | Strict original criteria; missing legacy/ledger cannot be silently green | Full live run not attempted while known required data is missing; exact storage screenshot required |
| P5-10 inventory | Deployed numeric >60 filter/make grouping; source fixture now generates 15 >60 and 12 >120 at anchor | Live 120 >120 differs from requirement; >120 slice/data correction and pricing-impact review pending |
| P5-11 service SLA | New check-only narrows Status to Scheduled, retaining start < TODAY | Live matching query gives 13, not 12; no fixed-anchor acceptance substitution or data write |
| P5-12 loyalty | All-date Join Date window; counts/balances grouped by tier/status | Canonical-filtered 39/18/9/4 and screenshot still required; old current-quarter UAT remains valid at its scope |
| P5-13 duplicate audit | Original source preserved; CLI compares actual household surname/address/postal + distinct Account links | Exact eight duplicate-rule hits/pairs and six legacy-email findings not fully implemented as report acceptance |
| P5-14 executive | Dynamic five-metric operations dashboard and CSI proxy report deployed | Authorized two-persona scope and populated CSI evidence pending; no blanket read grants |
| P5-15 managers | Three fixed-user dashboards deployed; dedicated folder View group and RunReports-only supplement now check-only validated | Exact membership/deployment approval and runtime acceptance pending; no group members or new object/FLS grants |
| P5-16 joined reports | Existing three joined report types preserved; no broad rewrite | Owner builder usability screenshots pending |
| P5-17 reset | Read-only full snapshot and exact-ID child-first reset plan | Destructive executor/reload/purge is not implemented or accepted; original ng-dev test evidence conflicts with no-ng-dev boundary |
| P5-18 snapshot refusal | Wrong-org/stale/future/incomplete/foreign-tag/invalid-ID/external-dependent refusals; exact manifest scope | Offline checks pass; complete external-reference discovery and executor integration remain open |
| P5-19 burst | Separate 200 Lead/60 Service Visit/40 Task CSVs prepared and live parent IDs resolved; burst-only exact-ID teardown planner | No insert/delete/purge executor or execution/storage screenshots; original return-to-storage criterion retained |

No item requiring Salesforce data or browser evidence is marked passed based on local files.

## Native check-only blockers — stop-and-escalate record

### Phase 2, job `0Afaj00000oPyx5CAC`

Scope: Flow, PS_Lead_Conversion, PS_Test_Drive_Booking, PSG_Rep; four components; checkOnly=true.

```text
PS_Lead_Conversion: Permission ConvertLeads depends on permission(s): EditTask
PSG_Rep: Cannot create Permission Set Group Components since the following permission set names are invalid: PS_Lead_Conversion
TestDrive_Book_Screen: field integrity exception: unknown (You can set either allowFinish or allowBack to false, but not both.)
```

No real deployment occurred. No permission expansion or follow-up fix was attempted after
failure. Owner action needed: approve adding the platform-required EditTask dependency to
the conversion set and correcting Flow navigation, then authorize exact scoped revalidation.

### Phase 5, job `0Afaj00000oPzQ6CAK`

Scope: exact 15 components in `manifest/p5-completion-preparation.xml`; checkOnly=true.

```text
NG_05_DataQuality/SEED98_Contacts:
columns-field: You can't include groupings in the selected columns list: 00Naj000062JKX5.
NG_05_DataQuality/SEED98_TradeIns:
Invalid field name: Trade_In__c$CreatedDate
NG_Management/DM_Finance_Operations, DM_Sales_Operations, DM_Service_OperationsFixed,
NG_Sales/DM_Exec_OperationsOverview:
Metric, gauge, or table dashboard component missing indicatorLowColor attribute
```

Nine component validations succeeded inside the failed check-only: reporting make formula,
three report types, inventory/SLA/CSI/Loyalty reports and private management folder. Nothing
persisted. Metadata work stopped on failure; no corrective loop or real deploy followed.
Owner action needed: approve bounded report-column/date-token and metric-attribute fixes,
then repeat the same manifest. Do not broaden to permissions/profiles or existing P3 metadata.

## Phase 2 controlled acceptance procedure (NOT EXECUTED)

Use `docs/planning/P2_BROWSER_UAT_PROCEDURE_2026-10-20.md`. Owner must explicitly start the
window. Authorized CLI handles guards, persona setup/restoration and read-only evidence.
Owner creates ten Leads, qualifies/converts one into new records and runs booking success,
overlap rejection and a free interval in the genuine rep browser. Admin CLI authentication
does not become rep authentication after a persona switch. Do not rerun `p2_setup.apex` as
admin or remove its bypass guard. Preserve private sharing and complete prior UAT.

## Safe dependency-based release/data sequence

1. Resolve the missing live Contact duplicate-rule identity with the owner; do not retry a
   guessed rule or deploy local metadata to force a match. Preserve genuine recovered jobs.
2. Obtain separate approval for the five-component manager-access/SLA deployment, exact
   dedicated-group members and fixed-admin aggregate exposure. No actual deploy is authorized.
3. After owner starts a controlled Phase 2 window, perform the genuine browser procedure and
   restore the captured persona baseline. Original Flow acceptance remains mandatory.
4. Approve exact dated fixture corrections and pricing impact, six Trade-In parent links,
   24 Contact + 6 Trade-In inserts, bypass/restoration controls and a truthful ledger write
   model. No canonical reload or historical owner change is authorized by this plan.
5. After approved data work, run strict gates, complete lookup/polymorphic integrity and all
   original expected findings. Capture report ties, joined builder usability, dashboard refresh,
   fixed-user rendering, two-persona legitimate scope and exact Storage Usage. Empty CSI is
   not numerical validation.
6. Design and validate destructive reset/snapshot/burst executor separately before any use.
   Any future execution requires exact-ID approval and protection of non-SEED dependent records.
   Retain original ng-dev acceptance until owner resolves that org boundary; do not access it.
7. Complete P5-01…20 evidence matrix and accurate version/status documents. Full Phase 5 stays
   incomplete until all original criteria are met. No commits/pushes under current authorization.

## Remaining roadmap — eight implementation phases

- **Phase 6 (P6-01…17):** capacity-safe service booking → visit-linked Case intake/queues →
  escalation/history → accrual, tier evaluation, redemption/expiry → loyalty/service dashboards,
  consent/nurture and repeat purchases → entitlements, milestones, Knowledge and console UX.
  Depends on P4 enrollment, P5 data/reporting and verified platform capabilities. Gate: working
  post-sale lifecycle, demonstrable SLA/Knowledge, simulation seams and ≥90% relevant tests.
- **Phase 7 (P7-01…23):** images/gallery/reservation and calculator UX; VIN mock integration,
  contract/events/CDC; trigger/bypass/bulk architecture and counter Queueable; governance/debt,
  permission/territory review; capability-gated Agentforce/Data Cloud; clean-checkout regression,
  small authenticated Experience seed, Automotive Cloud mapping, README and full demo scripts.
  Gate: all four skill domains demonstrated from clean tag with honest licensed-product labels.
- **Phase 8 (P8-01…11):** depends on P7-18, P5, P6 and P1 security. Block A: explicitly authorized
  Digital Experiences scaffold, measured licence/access model, relationship-filtered CRUD/FLS
  controllers and cross-customer negative tests. Block B: authenticated home, owned vehicles,
  service history, capacity-checked appointment request, Cases/comments and read-only loyalty
  LWCs. Block C: responsive/accessibility/branding, owner UAT, demo script and seam note.
  Experience Cloud + LWC only; React excluded. Gate M4: measured licences, per-object isolation,
  own-account-only results and responsive evidence, or separately owner-authorized labelled
  fallback. No Phase 6–8 implementation or enablement occurred in this package.
