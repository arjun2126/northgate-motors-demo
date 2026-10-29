# Phase 6 Batch 2 — consolidated implementation plan

Date: 2026-10-24. Status: locally implemented and check-only validated under provisional demo
defaults; not deployed or owner-accepted. Scope: P6-05 through P6-08 as one release package.
Target: `ng-demo`, `00Daj00001Ae3iWEAR` only. Never access `ng-dev`.

Latest results are in section 11 and `evidence/P6/BATCH2_EXECUTION_2026-10-24.md`. Original
planning evidence and decisions below remain historical; their no-code/no-test statements
describe the earlier planning session, not the subsequent authorized overnight execution.

## 1. Authority, current state and boundaries

### Overnight local execution policy — provisional, not owner-approved monetary rules

The owner subsequently authorized local implementation, ordinary defect repair and scoped
check-only testing, including choosing configurable demo defaults. This supersedes the numeric
input hold below for local work only. Deployment, activation, schedules, assignments and live
balance/record changes remain prohibited. The original D1–D6 questions are retained as history.

- D1: 1 point/CAD on Completed customer-paid service (Total_Cost); 0.10 point/CAD on sale
  Opportunity.Amount behind Completed Delivery. Exclude Recall/Warranty_Repair. Both bases are
  stored demo amounts, not invoices/payment proof; no added tax/fee/finance calculation. Floor
  once after multiplier. Null/negative spend rejected; zero or rounded-zero creates no credit.
- Tier table (lifetime CAD threshold, multiplier, expiry days): Bronze (0,1,365),
  Silver (5000,1.25,365), Gold (25000,1.5,540), Platinum (50000,2,730).
- D2: lifetime-spend qualification; upgrade-only by default, configurable Allow_Downgrades=false.
  Tests exercise true/false. Only managed Active members are evaluated. No historical rebase or
  legacy tier demotion. Record last transition, not a fabricated immutable tier history.
- D3: unscheduled eventual accrual, one Service Visit / sale Opportunity key; existing Active
  membership only. Source CreatedDate cutoff is configurable, provisionally 2026-10-25T04:00:00Z
  (Toronto midnight). Program Default remains inactive. Actual rollout requires owner approval.
  First posting uses Toronto processing date. Replays do not reprice/recredit; changed posted
  recipient/spend is rejected for manual review. No automatic enrollment or reversal.
- D4: positive integer redemption, minimum 1, no increments beyond integer points, configurable
  CAD 0.01/point (display value only, not cash/payment/Quote integration). Earliest expiry first,
  no-expiry last, Id tie-break; expiry strictly before Toronto as-of date. Debits per lot, linked
  to the originating accrual; expiry does not increment redeemed lifetime points. Use additive
  Service_Redemption reason. Only new managed lots are spendable/expirable.
- D5: preserve all historical balances, tiers and 110 source-less/expiry-less transactions;
  no provenance backfill, balance reconstruction or default historical expiry.
- D6: intended operator is licensed Service Advisor via new local PS_Loyalty_Operator and
  Redeem_Loyalty_Points custom permission; test-only users/assignments stay in test isolation.
  No live assignments, VP expansion or existing permission-set edits. Managed balance/tier/
  provenance edits go through guarded services. Existing unmanaged enrollment remains unchanged.

All rates, tier thresholds/multipliers/expiry and downgrade policy are metadata-configurable.
The new configuration is inactive, and every monetary entry point must enforce that gate.

Read: repository `AGENTS.md`, `NORTHGATE_PROJECT_HANDOFF.md`, `DEMO_ORG_BACKLOG.md`,
`DEMO_ORG_MASTER_PLAN.md`, `DEMO_ORG_DATA_MODEL.md` sections 3.7–3.10 and 5.2–5.6,
`docs/architecture/AUTOMATION_DIRECTION.md`, `SIMULATION_FINANCE.md`, the permission matrix,
and the relevant service, enrollment, delivery, metadata and test source. Later owner decisions
and the ratified no-new-Flow direction supersede historical planning-only/Flow wording.

Phases 1–4 are owner-reported complete and accepted. Phase 5 remains accepted with documented
exceptions. Batch 1 deployed by Quick Deploy `0Afaj00000owPUHCA2` at 2026-10-24T02:42:00Z,
using stored validation `0Afaj00000ovK6sCAE`: 14 components, 33 passing tests. These are prior
execution results, not tests repeated during this planning session. Batch 1 owner acceptance is
**deferred, not passed**; carry its obligations into section 9 below.

Authorized now: read-only repository/org investigation and local planning documentation.
No Batch 2 source, metadata, tests, check-only request, deployment, records, permissions,
assignments, schedules, reconciliation, page activation, staging, commit or push was performed.
The working tree is dirty; existing changes are not a baseline to overwrite or deploy wholesale.

## 2. Focused baseline and evidence

The following are raw excerpts from successful read-only CLI queries in this session.
Queries ran with explicit `--target-org ng-demo`; inventory queries used Tooling API where required.
No personal/customer records were exported into this plan.

### CONFIRMED — target and configuration

`SELECT Id FROM Organization` returned:
```json
{"Id":"00Daj00001Ae3iWEAR"}
```
`SELECT DeveloperName, Tier__c, Threshold_Amount__c, Accrual_Multiplier__c, Expiry_Days__c,
Is_Active__c FROM Loyalty_Tier__mdt ORDER BY Threshold_Amount__c` returned:
```json
{"records":[],"totalSize":0,"done":true}
```
There is no approved numeric tier/rate/expiry configuration to reuse. CP2's four loyalty
**discount** records are not point-accrual rates and must not be repurposed.

### CONFIRMED — historical population must not be rebuilt

Member aggregate:
```json
{"members":72,"points":0,"spend":null}
```
Transaction aggregates:
```json
[
  {"Type__c":"Redemption","transactions":28,"points":-5418},
  {"Type__c":"Accrual","transactions":82,"points":22788}
]
```
Transaction provenance/date coverage:
```json
{"transactions":110,"withExpiry":0,"withOpportunity":0,"withVisit":0,"withSource":0}
```
Duplicate-membership query, grouping by Contact with count > 1:
```json
{"records":[],"totalSize":0,"done":true}
```
All 72 members currently have Status Active: Bronze 40, Silver 18, Gold 9, Platinum 5.
The historical transaction net is 17,370; stored balances total zero and lifetime spend is
unpopulated. This is a preservation/migration decision, not authorization to reconcile balances,
invent source links, populate expiry dates, demote members or replace historical records.
Generator source (`data/scripts/generate.ts:866–925`) independently seeds tiers and transaction
points; it is not a business-rule engine or evidence of a valid historical opening balance.

### CONFIRMED — schema and running code

FieldDefinition inventory returned 65 fields across the three loyalty types, including:
```json
[
  {"QualifiedApiName":"Loyalty_Member__c","DataType":"Master-Detail(Loyalty Member)","IsCalculated":false},
  {"QualifiedApiName":"Source_Reference__c","DataType":"Text(80)","IsCalculated":false},
  {"QualifiedApiName":"Next_Tier_Threshold__c","DataType":"Number(9, 0)","IsCalculated":false},
  {"QualifiedApiName":"Is_Expired__c","DataType":"Formula (Checkbox)","IsCalculated":true}
]
```
The relationship field above is on `Loyalty_Transaction__c`. Existing member fields include
balance, earned/redeemed totals, lifetime spend, activity/join dates, tier/evaluation date,
next threshold and expiring flag. Existing transaction fields include signed points, type/reason,
transaction/expiry dates, optional Opportunity/Service Visit lookups and unique seed key.
The three native roll-ups described in the data-model document are **absent** from source and
live field inventory. Do not depend on them or add historical roll-ups that change existing totals.
`Source_Reference__c` is not unique; its documented purpose is source provenance, not deduplication.

Tooling Apex inventory returned `LoyaltyEnrolmentService`, its test, `DeliveryCloseService` and
deployed `CaseServiceHistoryController`; no accrual, tier, redemption or expiry engine matched
the planned names. All 12 Apex triggers were enumerated: none is on either loyalty object.
FlowDefinition inventory contains five definitions: active Lead enrichment, Test Drive booking
and appraisal plus two inactive definitions. No loyalty Flow exists. Named Loyalty CronTrigger
query returned zero rows; this is not a claim about differently named schedules.

Live enrollment/delivery bodies match inspected source: delivery completion closes the
Opportunity, stamps completion, increments Contact lifetime and enrolls at Active/Bronze/zero.
Late null-to-value buyer assignment enrolls; replacing a non-null buyer does not.
Enrollment checks existing membership in USER_MODE and performs per-delivery queries/DML.
Do not silently change that access contract or its zero-balance synchronous outcome.
Its existing per-row delivery bulk ceiling is an inherited limitation, not a Batch 2 refactor.

Service fields already exist: Vehicle, Contact, Case, scheduled start, status, mileage,
parts/labour cost and `Total_Cost__c` formula. Delivery has Buyer, Opportunity, Vehicle,
status and completion Date; Opportunity has Amount. These are not proof of a final invoice,
payment, tax base or actual Service completion timestamp.

### CONFIRMED — security/configuration observations, not persona acceptance

Live EntityDefinition results:
```json
[
  {"QualifiedApiName":"Case","InternalSharingModel":"Private"},
  {"QualifiedApiName":"Service_Visit__c","InternalSharingModel":"Private"},
  {"QualifiedApiName":"Vehicle__c","InternalSharingModel":"ReadWrite"},
  {"QualifiedApiName":"Loyalty_Member__c","InternalSharingModel":"ReadWrite"},
  {"QualifiedApiName":"Loyalty_Transaction__c","InternalSharingModel":"ControlledByParent"}
]
```
ObjectPermissions/FieldPermissions returned Service Advisor Read on Vehicle and CRUD on Case
and visits, but no loyalty grants in that set. Sales Rep and Finance Officer have member CRU,
not transaction grants in the inspected sets. Sales Rep can edit balance, lifetime spend and
tier; Finance Officer has Read-only on those three fields. This is a set-level observation,
not the effective permission union of any licensed user. The historical permission matrix is
not the current live access baseline. VP operational permissions must remain absent.

### UNVERIFIED — live validation formula

One Tooling query stopped on:
```text
No such column 'ErrorConditionFormula' on entity 'ValidationRule'.
```
No retry/workaround was attempted. Local `VR_Loyalty_NonNegativeBalance` is active and uses
`AND(NOT($Permission.Bypass_Automation), Points_Balance__c < 0)`; local transaction expiry
formula is `Expiry_Date__c < TODAY()`. Neither live formula is newly certified here.
Owner manual follow-up: open Setup > Object Manager > Loyalty Member > Validation Rules >
VR_Loyalty_NonNegativeBalance and confirm Active/formula. Open Loyalty Transaction > Fields >
Is Expired to confirm formula. No Setup edits are requested. No files had changed when the query
failed; successful field/configuration queries above remain the last verified org state.

## 3. One sequence and release unit

Implement in backlog order: **P6-05 → P6-06 → P6-07 → P6-08**, within one approved task.
P6-05 is independently read-only. P6-06 supplies the ledger/locking foundation used by P6-07/08;
design the debit/expiry lot fields with that foundation so P6-08 does not require a ledger rewrite.
One coordinated manifest, focused regression gate and owner deployment approval cover all four.
No per-block permission/deployment approvals. Resolve section 7 once in the consolidated reply.

Recommended delivery mechanism: explicit, unscheduled `LoyaltyAccrualBatch` with Service Visit
and Delivery modes, sharing `LoyaltyAccrualService`/`LoyaltyLedgerService`. This observes committed
source data after enrollment, avoids changing accepted delivery code or Batch 1 Service trigger,
and preserves synchronous zero-balance enrollment. Accrual is eventual, not immediate or a
payment-capture integration. No live batch execution is included in local implementation approval.

## 4. Proposed architecture (requires the section 7 policy approval)

### P6-05 — Vehicle service history

Add `VehicleServiceHistoryController` and `vehicleServiceHistory` LWC on a new unactivated
Vehicle page. Reuse Batch 1 DTO/display/security conventions, not its Case-only endpoint.
Leave `CaseServiceHistoryController`, Case LWC and all Batch 1 files unchanged.

Query the accessible Vehicle first, then visits by exact Vehicle Id in USER_MODE. Return
scheduled date/time, status, service type and recorded mileage; include current and past visits.
Query Cases independently in USER_MODE: direct Vehicle matches plus Case IDs from accessible
visits. Never treat an accessible Vehicle/visit as permission to expose its private Case.
Show accessible Cases even without a linked visit. Do not use Contact fallback on a Vehicle page.
Use separate stable date/Id keyset pages for visits and Cases; explicit loading/error/empty and
more-results states. Blank mileage stays unknown; do not infer odometer changes or repair
missing historical links. A chronological mileage table satisfies the requirement; no chart
dependency, copied history or new history object is needed. Do not replace existing photo/detail
experience or activate/assign the new page. Existing dirty Vehicle layouts need not enter the package.

### Shared loyalty transaction boundary

Create a small `LoyaltyLedgerService` as the only writer for **new engine-managed** transactions.
Resolve source records server-side; never accept caller-supplied rates, point deltas, tier or
arbitrary balance field updates. Acquire member locks in one consistent bulk pattern before
reading balance, deduplication keys or lots; lock/re-read source eligibility for accrual.
All accrual/redemption/expiry paths use the same parent locking protocol. No DML/SOQL per source.

Use additive fields on Loyalty Transaction:
- `Event_Key__c`: unique, case-sensitive Text(80), external ID; hash canonical action/source
  identifiers where necessary. Preserve Seed_Tag and Source_Reference semantics.
- `Source_Spend__c`: Currency snapshot for an accrual's accepted monetary base.
- `Remaining_Points__c`: Number(8,0), populated only on managed accrual lots.
- `Source_Accrual__c`: optional self-lookup linking each debit/expiry to its managed accrual lot.
- `Request_Key__c`: Text(80) grouping one redemption request's lot debits.

Add member `Managed_From__c` DateTime, nullable: first managed activity opt-in, not a backfill.
Do not recompute opening balance or totals from all 110 historical rows. Apply new signed deltas
to existing stored balance and earned/redeemed totals only when an explicitly approved live
operation runs. Historical transactions remain non-managed and excluded from lot expiry/debits.
Redemption availability is bounded by BOTH stored balance and unexpired managed-lot remainder.
If those disagree, reject rather than silently repair or debit unsupported historical points.

Transaction insertion, lot decrements and member delta updates must commit together. Use
all-or-none DML for each atomic scope; never pair independent partial-success ledger/member
writes. A failed member update rolls back ledger creation; a failed ledger write rolls back
lot/balance changes. Repeating a committed event is a verified no-op. A unique-key collision
must not be swallowed while applying its balance delta. Lock failures propagate; no speculative
retry loop or static processed-ID set that survives partial-save rollback.

Protect managed records with thin `LoyaltyTransactionTrigger` and `LoyaltyMemberTrigger`,
delegating guards to the ledger service. Engine-write authorization is private transaction-local
state, set/reset only around validated service DML. No remotely settable bypass or public setter.
Reject external creation/alteration/deletion/reparenting of managed ledger rows and changes to
managed member balances, counters, tier or Contact attribution. Preserve legacy/unmanaged
records and Phase 4 enrollment defaults. These prospective managed-record edit restrictions
require explicit owner approval in D6; do not revoke existing permission-set grants implicitly.
Retain the established trigger-bypass convention for trusted loading; engine arithmetic still
rejects overdrafts even when the invoking administrator has Bypass_Automation.

### P6-06 — accrual

Batch reads only post-rollout, currently Completed sources in bounded scopes. Required rollout
boundary is explicit; recommend source CreatedDate on/after boundary, excluding older open
sources even if completed later. That limitation needs D3 approval. Do not use LastModifiedDate
as evidence of completion. No historical enrollment or accrual backfill.

For Service: proposed base `Service_Visit__c.Total_Cost__c`, member by Contact, one credit key
per visit. For sale: proposed base `Opportunity.Amount` behind a Completed Delivery, buyer from
Delivery, one credit key per Opportunity (not per delivery, Quote or Funded Financing).
Conflicting buyers across deliveries of one sale are rejected, not selected arbitrarily.
These monetary bases require D1 approval; they are simulation inputs, not proof of settled spend.
Do not read finance-only rate/cost fields or alter CP2 totals.

Require exactly one Active membership and valid configuration. Missing/ambiguous membership
is reported with aggregate reason counts, not auto-enrolled or merged. Reuse the existing
membership created by Phase 4, including its late-buyer path. Record tier/rate and spend used
in the transaction calculation/result evidence; freeze posted points and expiry on repeats.
Null/negative spend, overflow or missing rates fail closed. Zero-value policy and rounding are
specified in D1. Recompletion, cost edits and retries cannot create another credit. Changed
posted-source value/recipient is reported for an owner-controlled adjustment, not recredited.
Current-state polling cannot prove a source never left Completed; make no stronger claim.

Add `Loyalty_Program__mdt` with `Is_Active__c`, `Eligible_From__c`,
`Service_Points_Per_CAD__c` and `Sale_Points_Per_CAD__c`. Default remains inactive until a
later activation approval. Existing `Loyalty_Tier__mdt` supplies approved tier multiplier,
threshold and expiry-day rows. All values must be owner-supplied; no invented tier table.
Use a private test-visible config seam for boundary/malformed-config tests, not test-only
production behavior. No trigger hooks in Delivery or Service Visit are required.

### P6-07 — tier reevaluation

`LoyaltyTierEvalBatch` implements Batchable/Schedulable; scheduler delegates only. No schedule
record is created. For opted-in managed members, lock/re-read stored lifetime spend and active
configuration, select highest qualifying threshold, then update tier, next threshold and
`Tier_Evaluated_On__c`. Record the most recent actual tier transition in additive member fields
`Previous_Tier__c` and `Tier_Changed_On__c`; unchanged evaluations do not invent a transition.
This is last-transition evidence, not an immutable complete history of every tier change.

Recommend lifetime-spend qualification and upgrade-only behavior for this batch, protecting
existing seeded tiers from null-spend demotion; D2 must approve or replace that policy.
Skip non-managed members. Missing/duplicate tier rules or thresholds not representable in
existing Number(9,0) Next_Tier_Threshold fail before writes. Do not silently round thresholds,
hardcode thresholds in Apex or add a second competing balance/tier engine.
Future Quotes naturally use updated member tier through existing CP2 behavior; do not reprice
or stamp any existing Quote/Opportunity. Record this intended downstream interaction in tests.

### P6-08 — redemption and expiry

`RedemptionService` is a small authenticated action with `with sharing`, USER_MODE access
checks and a dedicated custom permission before narrowly elevated ledger writes. Require
positive integer points, accessible Active member, request idempotency token and sufficient
balance AND managed-lot availability. Repeated member/token with identical input returns the
same result; changed amount/context is rejected. No caller-supplied negative delta.

Recommend earliest-expiring-first consumption, with non-expiring lots last and Id tie-breaker.
Each consumed lot produces a negative Redemption row with Source_Accrual and shared Request_Key;
the request's rows sum exactly to the requested points. Lookup existing request rows under lock
and compare their total/input before changing anything. No negative points, orphan debits or
partial multi-lot redemption commit. Reuse an existing appropriate reason value only if D4
approves its meaning; otherwise add a dedicated approved redemption reason, never mislabel
a normal redemption as a manual correction.

`Loyalty_ExpiryBatch` processes opted-in managed lots only, locking member then lots and
re-reading remaining amounts. Recommend expiry when Expiry_Date is strictly BEFORE the
explicit Toronto as-of Date, consistent with local Is_Expired formula. One deterministic
expiry event per lot debits only unspent remainder, sets remainder to zero, and reduces balance;
never subtract original points after partial redemption. Do not increment lifetime redeemed
for expiry. Rerun is a no-op. Historical transactions without expiry dates remain untouched.
Use fixed as-of dates in tests and consistent scheduled-user/explicit Toronto date handling;
do not let API actor timezone change expiry eligibility. No jobs or one-off executions now.

## 5. Security and operating model

- History uses with-sharing/USER_MODE for Vehicle, visits and Cases; customer details never
  escape via elevated capacity paths. P8 external access remains out of scope.
- Accrual/tier/expiry are internal admin-approved maintenance, not public source-query APIs.
  No new integration permission, VP operational grant or Finance/Sales persona merge.
- Propose `Redeem_Loyalty_Points` custom permission and `PS_Loyalty_Operator` for only the
  selected internal operator. Read-only member/ledger fields plus action class access; no direct
  ledger/balance write grants. D6 must choose operator before assigning anything later.
- Propose `PS_Vehicle_Service_History` for class access only; existing object/FLS/sharing
  remain required. It must not grant Sales access to private Cases/visits just to populate a page.
- Source permissions for new fields are narrowly scoped; users must not set Event_Key,
  Managed_From, lot remainders, derived tier/counters or internal write authorization.
- Missing class/FLS/license/persona readiness is a documented acceptance prerequisite, not
  permission expansion by the executing agent. No user or live assignment changes in local scope.

## 6. Expected implementation file boundary

All paths below are **proposed, not created**. Relative to `force-app/main/default/` unless stated.
Every Apex class/trigger includes its matching `-meta.xml`; every new custom field has its own
`.field-meta.xml`. Final manifest must enumerate these exact approved files, not wildcards.

| Block | Expected source / metadata |
|---|---|
| P6-05 | `classes/VehicleServiceHistoryController.cls`, `VehicleServiceHistoryControllerTest.cls`; `lwc/vehicleServiceHistory/vehicleServiceHistory.{js,html,js-meta.xml}`; `flexipages/NG_Vehicle_Service_History.flexipage-meta.xml`; `permissionsets/PS_Vehicle_Service_History.permissionset-meta.xml` |
| P6-06 shared core | `classes/LoyaltyLedgerService.cls`, `LoyaltyLedgerServiceTest.cls`, `LoyaltyAccrualService.cls`, `LoyaltyAccrualServiceTest.cls`, `LoyaltyAccrualBatch.cls`, `LoyaltyAccrualBatchTest.cls`; `triggers/LoyaltyMemberTrigger.trigger`, `LoyaltyTransactionTrigger.trigger` |
| P6-06 fields | `objects/Loyalty_Transaction__c/fields/{Event_Key__c,Source_Spend__c,Remaining_Points__c,Source_Accrual__c,Request_Key__c}.field-meta.xml`; `objects/Loyalty_Member__c/fields/Managed_From__c.field-meta.xml` |
| Configuration | `objects/Loyalty_Program__mdt/Loyalty_Program__mdt.object-meta.xml`; its `fields/{Is_Active__c,Eligible_From__c,Service_Points_Per_CAD__c,Sale_Points_Per_CAD__c}.field-meta.xml`; `customMetadata/Loyalty_Program.Default.md-meta.xml` (inactive); `customMetadata/Loyalty_Tier.{Bronze,Silver,Gold,Platinum}.md-meta.xml` only after approved numeric table |
| P6-07 | `classes/LoyaltyTierEvalBatch.cls`, `LoyaltyTierEvalBatchTest.cls`; `objects/Loyalty_Member__c/fields/{Previous_Tier__c,Tier_Changed_On__c}.field-meta.xml` |
| P6-08 | `classes/RedemptionService.cls`, `RedemptionServiceTest.cls`, `Loyalty_ExpiryBatch.cls`, `Loyalty_ExpiryBatchTest.cls`; `lwc/loyaltyRedemption/loyaltyRedemption.{js,html,js-meta.xml}`; `quickActions/Loyalty_Member__c.Redeem_Points.quickAction-meta.xml`; `customPermissions/Redeem_Loyalty_Points.customPermission-meta.xml`; `permissionsets/PS_Loyalty_Operator.permissionset-meta.xml` |
| Conditional D4/D6 | Dedicated redemption reason addition to `objects/Loyalty_Transaction__c/fields/Reason__c.field-meta.xml`; all existing values retained. Action placement/page assignment and live permission assignments remain separate approval. No existing page/layout replacement. |
| Tests/evidence | New LWC Jest tests alongside both new bundles if existing test tooling supports them; otherwise identify the smallest executable UI check and browser gap before adding tooling. `manifest/p6-batch2-check.xml`; focused results under `evidence/P6/`; validation-time hashes for every selected source and manifest. |

Existing production files intentionally excluded: Batch 1 classes/trigger/LWC/escalation;
DeliveryTrigger, DeliveryCloseService, LoyaltyEnrolmentService; CP2/Quote/approvals/Finance/
delivery/pricing engines; existing PS_Sales_Rep; old Vehicle/Case layouts; seed generator,
historical CSVs, balances and ledger. Existing tests are regression inputs, not rewrite targets.
Local-only plan approval may cover creation of new permission metadata, not deploying or assigning it.
P6-09 reporting, P6-10 seam deliverable and later backlog remain unstarted; this plan labels the
custom loyalty simulation honestly without marking those items done.

## 7. One owner decision set — resolve before monetary implementation

| Decision | Required owner answer / recommendation (not an established rule) |
|---|---|
| D1: calculation table | Supply service and sale points-per-CAD rates and Bronze/Silver/Gold/Platinum threshold, multiplier, expiry-day values. Approve or replace proposed Service Total_Cost / sale Opportunity.Amount bases. Recommend integer floor rounding once per source after tier multiplier, null/negative base rejected, zero spend/zero rounded points a no-credit/no-spend operation. Confirm tax/fees, discounts, warranty/non-customer spend eligibility. No figures inferred from CP2 discounts or seeded data. |
| D2: tiers | Approve lifetime-spend basis, upgrade-only evaluation, existing tier grandfathering, managed-members-only evaluation and last-transition fields; or supply downgrade/lookback/status policies. Define Platinum next threshold as blank. No legacy demotion/reconstruction. |
| D3: event/rollout semantics | Approve eventual batch accrual with no Service/Delivery trigger edits, source-CreatedDate cutoff, one credit per service visit / sale Opportunity, Active existing member only, no service auto-enrollment, no historical backfill, and manual review rather than automatic reversal for posted-source changes. Approve first-posting Toronto date for transaction/expiry origin; later activation supplies exact rollout instant. |
| D4: redemption/expiry | Approve managed-lots-only availability, earliest-expiring-first consumption, strict-before-Toronto-date expiry, one debit per consumed lot, and no expiry increment to lifetime redeemed. Choose whether one point has monetary redemption value/minimum/increments; if money is represented, supply conversion and eligibility. Choose normal redemption Reason value (recommend additive `Service_Redemption`, not Manual_Adjustment). Recommend no cash/payment/Quote integration in Batch 2. |
| D5: historical preservation | Approve leaving the 110 transactions without expiry dates/source links and 72 current balances/tiers intact. New managed events add deltas; no ledger-net rebuild. Existing positive opening balances, if later encountered, are not redeemable without managed provenance/reconciliation approval. No default expiry of seed records. |
| D6: security/UX | Name authorized internal redemption persona; approve new local permission metadata and prospective managed-record write guards. Existing Sales edit grants are not silently revoked, but managed balances/tiers become service-maintained. Approve Vehicle history LWC/new unactivated page and redemption action, with assignment/activation deferred. No change to VP, licenses, both admins, Sales/Finance separation or live assignments. |

Missing D1 values or a materially different D2–D6 answer is a real design dependency. Do not
claim the batch is execution-ready from a generic "go" while policies remain blank. These
decisions can be supplied once with the consolidated approval; do not start four planning cycles.

## 8. Coordinated validation strategy

Use isolated fixtures, no SeeAllData and actual non-admin/no-bypass personas. Existing executive
and service tests show why a test name in `--tests` does not package its repaired local source.
Include any intentionally changed regression test and required source in the exact manifest.
No org-wide deployment/validation. Target >=90% meaningful coverage on new engines and branches.

| Area | Required checks |
|---|---|
| P6-05 | Current/prior visits; mileage null/zero/order; direct and visit-linked Cases; inaccessible Case; hidden private visits; denied Vehicle/object/FLS; invalid Id; stable pagination beyond one page; UI loading/error/empty/more states. |
| P6-06 | Owner-approved maths, rounding, all tier multipliers, zero/null/negative/overflow; 200-source accrual; two sources for one member; repeated scan, re-completion and source edits; multiple deliveries for one Opportunity; missing/ambiguous member; first-run boundary; disabled/missing/duplicate config; unique-key replay; source mismatch. |
| Atomicity | Real failed ledger insert and real failed member update roll back all related writes. Mixed valid/invalid input never leaves a surviving credit without its balance or a debit without lot consumption. Test `Database.insert/update(..., false)` at guarded boundaries and subsequent Salesforce retry, asserting row-level results and persisted ledger/lot/member state. Batch scope may roll back as a unit; do not promise per-source success inside a failed scope. No static processed set. |
| P6-07 | Each threshold below/equal/above, malformed/tied config; next threshold/top tier; inactive/legacy member skips; grandfathered tier; repeated runs; current/previous tier and change/evaluation dates; 200 members; scheduler delegate via Test.stopTest without a live schedule. |
| P6-08 | Positive integer request, inaccessible/inactive member, permission denial, exact balance, insufficient points, expired vs unexpired lots, multi-lot sum, same-token retry and altered-payload rejection, concurrency protocol, partial redemption then expiry, no evidence/zero remainder, duplicate expiry, exact expiry date and next Toronto day, DST and non-Toronto actor, numerical overflow, negative-balance VR with no bypass. |
| Preservation | LoyaltyEnrolmentServiceTest, DeliveryCloseServiceTest and DeliveryCompletionGuardTest (zero initial balance, late buyer, replacement exclusion, repeats, closing flag/date/lifetime assertions); existing 33 Batch 1 methods; ExecutiveServiceMetricsPublisherTest; QuotePricingServiceTest and buyer-specific loyalty portions of QuoteBuilderControllerTest because new tiers affect FUTURE pricing. No broad unrelated suite or production rewrite. |
| Security | Internal maintenance sees all eligible sources without returning private source details. Redemption verifies custom permission AND accessible member/read fields; no direct managed ledger/member forgery. Existing non-managed enrollment and admin/Finance/Sales boundaries preserved. Public internal loyalty OWD is not cross-customer isolation; no external access added. |

Run new block-focused checks as development gates within one task, then one exact combined
Batch 2 check-only package with all affected regressions. Capture raw output, validation ID,
component/test counts, individual failures and coverage. Stop/escalate unexpected failures per
AGENTS.md; never edit assertions or validation rules to force green. Before approval review,
record SHA-256 of each included local file and manifest plus validation-time archive/source map.
Future Quick Deploy should use the stored validation payload, never a broad dirty-tree upload.
No tests or check-only were executed during this planning session.

## 9. Acceptance and later operating approvals

Batch 2 is not accepted until evidence proves the four backlog outcomes: Vehicle history,
configured service/sale point maths, tier movement and rejected overdraft/correct expiry.
Owner browser acceptance must use the named licensed persona, not admin output: Vehicle page
including private Case handling, redemption action, idempotent double-submit and visible balance/
tier changes. Live writes require exact-record/data-window approval and storage headroom check.
Actual concurrent accrual/redemption/expiry and lock contention require controlled live acceptance;
Apex unit tests alone do not certify multi-session race freedom.

Tier/expiry scheduler code may be tested; activating nightly jobs or invoking a real batch is
separate. Program activation/cutoff, seeded-balance reconciliation, backfill, permission assignment,
action placement and page activation are not part of local implementation approval. No live
financial/loyalty balance changes occur during planning or check-only tests.

Carry Batch 1's deferred owner obligations unchanged: two-session capacity contention, licensed
Service booking/intake, four elapsed-hour native escalation including cancellation/re-entry,
notification delivery and actual ownerEscalated emission; separately approved reconciliation
with rollout boundary and timestamp comparison; missing-history/same-owner/no-rule-attribution
limitations; Case history browser experience and separately approved page activation. Preserve
Phase 5 CSI display, inactive publisher schedule, provenance/storage/reconciliation and persona
exceptions. Batch 2 planning does not satisfy any of these obligations.

## 10. Single consolidated implementation approval request

> Approve one local P6-05–P6-08 Batch 2 implementation under this plan, after supplying D1's
> numeric table and confirming/replacing D2–D6 in the same reply. Implement all four blocks in
> backlog order without per-block approval pauses. Include the proposed new ledger fields,
> private writer/managed-record guards, unscheduled accrual/tier/expiry batches, Vehicle history
> and redemption UI plus narrowly scoped local permission metadata. Preserve Phase 4 enrollment
> and all deployed Batch 1/Phase 1–5 behavior; use only the approved event/monetary policies.
> Run focused isolated regressions and exact Batch 2 check-only validation against ng-demo,
> including changed local test source and validation-time source hashes. No actual deployment,
> live batch/reconciliation execution, records/balance repair, permissions/assignments, schedule,
> page activation, ng-dev access, staging, commit or push. Finish with one approval-review package
> for the whole batch, raw validation evidence and explicit remaining acceptance gates.

If approved business rules require payment/Quote integration, historical reconstruction,
financial reversals or materially different security, update this bounded file plan before
implementation; do not treat those as implicit additions to Batch 2.

## 11. Overnight execution results — 2026-10-24

Implemented all four blocks locally under the owner's autonomous local/check-only authorization.
No feature deployment or live operation occurred. The program remains inactive. The D1–D6
provisional policy at the top of this document supersedes the earlier policy-input hold only
for local implementation and test isolation, not final owner approval of economics or activation.

Focused check `0Afaj00000oyNGHCA2`: 58/58 components, 21/21 new tests, Succeeded.
Final coordinated check **`0Afaj00000oyOkDCAU`**: 58/58 components, **108/108 tests**, zero
component/test errors and no coverage warnings, Succeeded at 2026-10-24T10:54:12Z.
Actual counts, coverage, individual development failures/fixes and exact edited/new source paths:
`evidence/P6/BATCH2_EXECUTION_2026-10-24.md`. Existing 33 Batch 1 tests and selected enrollment,
delivery and CP2 regression sources were included unchanged; no stale deployed test substitution.

Implemented deviations/clarifications from the original proposed file table:
- Added Applied_Rate, Applied_Multiplier and Applied_Tier transaction snapshot fields (all __c),
  plus program Allow_Downgrades and Redemption_Value metadata fields, to keep defaults auditable
  and configurable. Shared isolated test fixture is LoyaltyBatch2TestData.
- Self-lookup deletion policy is SetNull because Salesforce rejects Restrict self-lookups.
  Managed-row deletion remains blocked by Apex; no historical lookup repair is performed.
- New unactivated Vehicle page contains highlights/history only. Unsupported optional native
  record-detail decoration was removed after its exact check-only error; no existing Vehicle
  page, photo or detail metadata was changed. Review composition before any assignment.
- Internal maintenance selectors explicitly use SYSTEM_MODE; UI queries remain USER_MODE.
  Private write authorization is reset in finally, and failed DML rolls back ledger/lot/member
  changes through a savepoint. No public authorization setter or direct remote ledger endpoint.
- Scheduler delegate tests only enqueue within discarded test transactions and verify no
  CronTrigger. Direct batch start/execute/finish paths and tier/expiry behavior are tested;
  no live schedule or active-program async job is claimed proven.
- Date-filter work is configuration-only owner instructions in
  `SERVICE_VISIT_DATE_FILTER_PLAN_2026-10-24.md`; no All-view/schema/backfill change was needed
  or made for the candidate native-calendar UX. Object-calendar setup/browser acceptance is pending.

Source snapshot and converted archive are retained under evidence/P6; local hashes were captured
after the passing request in the same session, with no selected source edits afterwards.
`python3 scripts/tests/check_p6_batch2_package.py` checks explicit scope, inactive config, XML
well-formedness and emits selected-file/aggregate hashes. It does not claim independent server ZIP
byte parity. Stored successful request is the future Quick Deploy candidate, subject to eligibility.

Remaining: owner review of provisional rates/tiers/eligibility/operator, new metadata deployment
approval, separate program activation/cutoff, assignments, action placement, page activation,
browser/mobile/token handling, and live concurrency acceptance. Historical balances and ledger
remain unchanged. The native date filter and all still-deferred Batch 1/Phase 5 obligations are
not retroactively accepted. No Batch 3 implementation began.
