# Phase 5 to Phase 6 handoff — 2026-10-23

## Decision status

**Owner accepted Phase 5 WITH DOCUMENTED EXCEPTIONS on October 23, 2026.** This records
the owner's decision, not a claim that all original criteria or deferred tests passed.
The authoritative 20-item classification and each deferred item's owner, impact and future
phase remain in `DEMO_ORG_BACKLOG.md`, under "Expedited Phase 5 closure".

The owner reports CSI displays 0 rather than N/A with zero responses and accepts that UI
discrepancy as an exception. Its cause is not diagnosed here and it is not repaired by P6
planning. The scheduler stays inactive, Finance/Service persona acceptance stays pending,
and all data-reconciliation/optional-testing and working-tree exceptions are preserved.

Only `ng-demo` (`00Daj00001Ae3iWEAR`) was accessed. No Phase 6 implementation, scheduler
activation, extra data correction, user change, sharing change, commit or push was performed.

## Completed functionality and evidence

| Area | Evidence | Scope of the claim |
|---|---|---|
| CP2 and Quotes | Existing accepted project evidence; activation preservation fingerprints | Preserved; no reprice or new investigation. |
| Test Drive core and scheduling | Deployment `0Afaj00000ojnxTCAQ`, 20/20 focused tests; owner-confirmed core acceptance | Preserved; no live test booking created in this window. |
| Financing launch context | Deployment `0Afaj00000ojX6KCAU`, 61/61 tests; owner confirms both browser launches, Draft reuse, and 587.07 monthly preview for the 30,742 test Quote | Completed application path, not dedicated Finance-user acceptance. |
| Finance exception approval | `evidence/UAT/live_2026-10-19/finance_uat_completed_2026-10-20.md` | Existing completed approval evidence retained; no resubmission. |
| Delivery and initial Loyalty enrollment | Existing controlled UAT and the 138-method cleanup regression recorded in `P5_EXECUTION_REPORT_2026-10-21.md` | Existing completion/enrollment preserved; accrual/redemption are later Phase 6 items. |
| Executive aggregate reporting metadata | Deployment `0Afaj00000os2RSCAY`, 13/13 components, 7/7 focused tests, publisher coverage 18/18 | Metadata/calculation/security tests passed; actual five-tile VP rendering still needs confirmation. |

No additional broad test suite or project audit was run. Historical test artifacts are dated
evidence, not claims of a new run against every current component.

## Approved activation actually executed

### Prechecks

- Authenticated primary administrator and exact org verified; administrator timezone is
  `America/Toronto`, matching the VP's established report timezone.
- Deployed publisher body matches the approved source. It uses user-mode Service reads
  and an explicit system-mode summary upsert. The administrator's ordinary numeric-field
  FLS remains restricted; the approved method does not require a new field grant for its
  narrowly scoped system-mode write. Source Read/FLS and all 140 source rows were verified.
- Live VP permission metadata contains only Read on Opportunity, Staff, Rooftop and
  Executive Service Metrics, and the five approved readable fields. It contains no
  Service Visit, Finance, operational write, View All or administrative grant.

### Exact results

```text
VP assignment: 0Paaj000017QDt9CAG
User: 005aj00000gE0b3AAC
Permission set: 0PSaj00000gmhQfGAI — PS_VP_Executive_Reporting
Existing Run Reports assignment preserved: 0Paaj000017HnvxCAC

Publisher calls: 1
Publisher DML statements: 1
Metrics records: 1
Record: a0Eaj00000QMH9hEAH
Key: DEALERSHIP
Overdue_Count__c: 14
CSI_Score_Total__c: 0.00
CSI_Response_Count__c: 0
Captured_At__c: 2026-10-23T16:16:17Z
Read-back source comparison: passed
Publisher schedules created: 0
```

The source filter is `Status__c = 'Scheduled' AND Scheduled_Start__c < TODAY`.
Read-only reconciliation established 13 at `2026-10-21T04:00:00Z` and 14 at
`2026-10-22T04:00:00Z`, both Toronto-local midnight cutoffs. `SEED-18-015`
(`a08aj00001SnsjbAAB`, start `2026-10-22T00:00:00Z`, or October 21 at 20:00 Toronto)
accounts for the increase. It was last modified before those cutoffs. No date was changed
to force an expected count of 12 or 13.

Zero CSI responses mean **N/A**, not an observed zero average. The published object has no
customer/vehicle links or appointment timestamps. Required key/capture fields inherit object
Read, while the three numeric fields have explicit Read-only FLS.

### Preservation evidence

Pre/post fingerprints compare record IDs and modification timestamps, not just counts:

```text
Service Visits 140; Financing 61; Opportunities 105; Quotes 65; Test Drives 74;
Tasks 245; Vehicles 120; Vehicle Models 30; Deliveries 13; Loyalty Members 72.
All pre-existing business-record fingerprints unchanged.
Users/profiles/roles, groups, Service sharing and Opportunity sharing unchanged.
All pre-existing permission assignments unchanged; only the approved VP assignment added.
Existing three CronTrigger records unchanged; no publisher schedule added.
Five-component LoggedInUser dashboard definition unchanged during activation.
```

The only Salesforce additions in this activation window were the approved assignment and
one deidentified metrics record. Neither assignment was removed automatically.

## Deferred browser follow-up retained after owner acceptance

Browser navigation reached **Login | Salesforce**, not an authenticated VP session. No
administrator result was used as restricted-persona browser acceptance.

1. Owner signs in as Northgate Persona and opens `DM_Exec_OperationsOverview`.
2. Confirm the correct running-user identity and all five components.
3. Compare Pipeline with the VP-visible source report; do not require the administrator's total.
4. Confirm Inventory 120, Overdue 14, CSI N/A/blank with its explanation, and Loyalty 72.
5. Use the two executive source reports to inspect last capture time and capture age.
6. Confirm Service Visit/Finance record access is still denied; do not attempt write tests
   against live records or broaden permissions to suppress an error.

The capture becomes stale after `2026-10-24T16:16:17Z`. Report formulas suppress values older
than 24 hours. Dashboard refresh does not run the publisher. If owner acceptance occurs
after that time, a new publication requires separate authorization; no automatic repeat or
schedule is approved. Literal N/A, freshness and dashboard rendering remain browser checks.

The earlier closure candidate treated this checkpoint as MUST FINISH. Owner acceptance now
records P5-14 as ACCEPT WITH EXCEPTION, including the observed CSI 0-versus-N/A discrepancy.
The checklist above remains follow-up guidance, not a condition for starting authorized P6
planning or a claim of a new browser pass. Two-persona comparison and additional screenshots
remain deferred. Any correction requires its own scope; do not reopen or alter completed
features automatically.

## Proposed closure exceptions

The backlog retains all original criteria and assigns owners/future phases to the exceptions.
The material limitations are:

- No new exact storage screenshot, global count tie or full post-cleanup orphan/gate sweep.
  Existing data and focused functional evidence are retained. Check storage before future loads.
- Historical ledger/storage/timestamp provenance is incomplete; no fabricated reconciliation.
- Time-dependent inventory/SLA counts, canonical-versus-UAT populations and duplicate-report
  versus native-rule evidence are documented; no history is altered to force planned counts.
- Manager Service/Finance drill-through is not claimed repaired by this executive-only scope.
- Full reset/purge/reload and burst storage-return rehearsal remain unimplemented/unverified;
  snapshot-refusal offline tests are separate passing evidence, not a completed executor.
- Dedicated Finance-user acceptance remains blocked by full Salesforce licenses. Sales and
  Finance stay separate, and both primary and Backup Admin accounts must be preserved.
- Existing Consent data/reporting does not establish an operational consent-enforcement gate;
  the gate is P6-12. Loyalty accrual, tier evaluation and redemption are P6-06 through P6-08,
  not missing Phase 5 enrollment functionality.

These deferrals were accepted through the owner's October 23 decision. No unconditional
original-criteria PASS or newly performed test is implied by that acceptance.

## Git and source handoff

- Branch: `main`; HEAD: `0423863794b70bb13c3c59128f7b57a0313aa0f4`.
- Cached upstream: `origin/main`; comparison is 0 ahead / 0 behind. No fetch or fresh remote
  verification was performed, so this is not a claim about unobserved remote changes.
- Observed status: 315 entries with normal untracked-directory grouping (56 modified tracked
  entries, 259 untracked entries), zero staged entries. These are status entries, not a total
  file count. Approved deployed features remain in a large uncommitted/untracked working tree.
- This window changes only closure documentation locally. Preserve all unrelated source and
  artifacts. Do not clean, reset, stage, commit, push or tag without separate authorization.

## Phase 6 starting point and later scope

**Phase 6 planning is owner-authorized; no Phase 6 feature implementation is authorized.**
The exception-based Phase 5 sign-off is recorded. The next approval is bounded P6-01 local
implementation/tests/check-only after the capacity policy is confirmed; the accepted CSI
display exception is not a prerequisite repair. See
`P6_01_CAPACITY_ENFORCEMENT_PLAN_2026-10-23.md` for the verified baseline and decisions.

Start with the established order:

1. **P6-01:** Service scheduling/capacity enforcement using Rooftop capacity and existing
   Service date validation; include boundary, bulk, sharing and non-bypass persona tests.
2. **P6-02:** Service intake Case creation and `Q_Service_Intake` routing after P6-01.
3. Continue P6-03 through P6-17: escalation, service history, loyalty accrual/tiering/
   redemption, role-aware service reporting, consent/nurture, Entitlements/Milestones,
   Knowledge, console acceptance and tests.

Follow owner-ratified `docs/architecture/AUTOMATION_DIRECTION.md`: no new project-owned
record-triggered/autolaunched Flows; use Apex services/guards for backend rules and preserve
native approvals, escalation, Entitlements, Knowledge, reports and accepted screens. Backlog
FLOW labels remain provisional where that architecture supersedes them.

Before live P6 data expansion or persona UAT, obtain a storage-headroom check and the required
actor/record-scope approval. A dedicated Service/Finance identity may require a separate
licensing decision; isolated Apex fixtures are not evidence that real user seats are free.
Service data changes will not update the cached executive record until another separately
authorized publication; scheduling remains deferred.

**Phase 7 remains in scope:** P7-01 through P7-23, including developer/integration depth,
verified AI/Data Cloud features, Experience seed, images, permission audit, regression and
governance/demo documentation. Deferred reproducibility/reset/burst evidence is carried here,
not silently removed from Phase 5.

**Phase 8 remains in scope:** P8-01 through P8-11, Customer Experience Portal using Experience
Cloud and LWC, relationship-anchored isolation and cross-customer tests. External licensing,
Digital Experiences enablement and any simulation fallback still require owner decisions.
