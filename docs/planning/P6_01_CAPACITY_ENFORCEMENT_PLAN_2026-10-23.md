# P6-01 Capacity Enforcement — focused implementation plan

Date: 2026-10-23. Target: `ng-demo` (`00Daj00001Ae3iWEAR`) only.

## Authorization and Phase 5 acceptance

The owner accepted Phase 5 WITH DOCUMENTED EXCEPTIONS on October 23, 2026 and authorized
Phase 6 planning/documentation only. No feature source was implemented or deployed, no Apex
tests/check-only feature deployment were run, and no Salesforce records, permissions,
sharing, users or schedules were changed in this kickoff.

Preserve the exceptions: CSI displays 0 instead of intended N/A; executive metrics scheduling
is inactive; data/count/ledger reconciliation and optional tests/screenshots/reset/burst work
remain deferred; Finance and Service persona acceptance is pending; the existing working tree
remains dirty/untracked. Sales/Finance stay separate and both administrator accounts remain.
These are tracked in the Phase 5 backlog; acceptance is not proof that deferred checks passed.

## Governing requirements and architecture

- `DEMO_ORG_BACKLOG.md`, P6-01: reject an over-capacity Service booking using
  `Rooftop__c.Service_Capacity__c`; retain existing Service timing validation.
- `DEMO_ORG_DATA_MODEL.md` section 3.8 describes advisor/day counting, while the Rooftop
  field is labeled Service capacity/day. That bucket definition is not settled merely by
  existing schema; obtain the policy confirmation below before feature implementation.
- `docs/architecture/AUTOMATION_DIRECTION.md` is owner-ratified: before-insert/update
  `ServiceVisitTrigger` calls `ServiceVisitCapacityGuard`. No new project-owned Flow.
- P6-02 is next, not part of P6-01: after-insert Apex creates the linked Case and routes
  to `Q_Service_Intake`. Native queue/validation/report functionality is preserved.

## Verified baseline

Read-only metadata retrieval `09Saj00000mYbBBEA0` is retained under
`retrieved/p6_01_planning_baseline/`. Raw query observations:

```text
Service_Visit__c entity: 01Iaj00000Fq37p
Live Apex triggers on that entity: 0
ServiceVisitCapacityGuard / ServiceIntakeCaseService classes: 0
Retrieved Flow references to Service_Visit__c or Service_Capacity__c: 0
Rooftop__c.Service_Capacity__c: Number(4,0), already deployed
Northgate Downtown: 6
Northgate North: 7
Northgate Airport: 8
Northgate Service Centre: 6
Service Visits: 140; visits without Rooftop: 0
Service Visit sharing: Private
Q_Service_Intake: 00Gaj00000ZYeznEAD, supports Case
```

Rooftop, Advisor Staff, Duration and Case are optional fields; Scheduled Start is required.
No persisted Service end-time field or duration-based capacity calculation exists in this
baseline. Daily capacity is not automatically the same as concurrent bay/interval capacity.

The active `VR_ServiceVisit_FutureForNew` formula is:

```text
AND(NOT($Permission.Bypass_Automation),
    ISPICKVAL(Status__c, "Scheduled"),
    Scheduled_Start__c <= NOW())
```

It contains no ISNEW check: a historical Scheduled visit may already fail an unrelated edit
under this rule. The new capacity guard must avoid adding retroactive restrictions, but it
cannot claim to remove this existing timing behavior. Do not edit the rule under P6-01.

## Policies to confirm in the next implementation approval

Recommended defaults, not yet implemented:

1. **Bucket: Rooftop plus dealership-local calendar day.** Treat the configured number as a
   shared rooftop daily active-reservation limit, not a separate allowance for every advisor.
   Changing Advisor alone does not create another capacity pool.
2. **Consuming statuses:** Requested, Scheduled, Checked_In and In_Progress. Completed,
   No_Show and Cancelled do not consume an active-reservation slot. Owner must confirm that
   Requested reserves capacity, including the Rooftop requirement this imposes on a new
   Requested booking; optional Rooftop schema alone does not establish that policy.
3. **Timezone:** fixed dealership timezone `America/Toronto`, not the current API user's
   timezone. Validate local-midnight and DST boundaries explicitly. Reuse timing test ideas
   from the executive publisher, not its runtime-user timezone assumption.
4. **Bad configuration:** fail closed for a new/increasing reservation with no Rooftop or a
   missing/zero/negative capacity. Do not globally make existing optional fields required or
   retroactively edit seed/history. All four current capacities are positive.
5. **Lifecycle:** check inserts, moves to another rooftop/day and terminal-to-consuming
   reopenings. Permit slot release and capacity-neutral updates without revalidating an
   already full/overfull historical bucket. Changing duration does not alter a daily count.
6. **Bypass:** retain the existing owner-controlled `Bypass_Triggers__c` convention for the
   trigger, with isolated bypass tests. Do not add a user-grantable capacity bypass or assume
   `Bypass_Automation` automatically replaces the trigger setting. No live toggle is authorized.

## Smallest proposed implementation

1. Add one thin `ServiceVisitTrigger` for before insert/update. Pass new rows and oldMap to
   the guard; do not create Cases or republish executive metrics in this workstream.
2. Collect affected old/new rooftop/day buckets and scheduling-relevant changes. Return
   early for capacity-neutral updates so feedback and the future Case-link write do not
   acquire unnecessary locks or fail solely due to existing capacity drift.
3. Lock affected Rooftop parents in a bulk query using `FOR UPDATE`; read their configured
   capacity. Use no SOQL/DML per visit and add no capacity-ledger object. Parent locking
   serializes different dates of the same rooftop too; test/record contention limits rather
   than claiming unit tests prove live race freedom. Do not rely on unsupported locking-query
   ordering or build speculative retry loops.
4. Read only the scheduling fields needed to count all relevant reservations, including
   bookings private to another owner. Use a narrowly scoped internal system-mode/no-sharing
   aggregate path, not a viewer-filtered user-mode count that would undercount hidden rows.
   This is internal object-invariant enforcement, not a VP/customer-access endpoint. Expose
   only a generic full-capacity error, never another customer's appointment details.
5. Exclude rows being updated from persisted counts and apply final batch deltas exactly
   once. Account for old-day/old-rooftop release, cancellation and reactivation; do not count
   an existing visit twice. Allocate remaining slots deterministically within a bulk request.
6. Reject capacity-increasing rows above the approved limit. Test partial-save behavior,
   particularly a failed move that must not falsely free its old slot. Do not silently repair
   historical over-capacity records or block legitimate slot releases.

Timezone conversion and query windowing must be verified in implementation; a naive
DAY_ONLY/convertTimezone grouping under the caller's timezone is not sufficient for the
fixed-dealership policy. Keep any helper private within the guard unless demonstrated reuse
requires otherwise. No new field, permission set, UI wizard or Flow is needed for P6-01.

## Focused acceptance and tests

- Below capacity succeeds; exactly at the limit succeeds; the next consuming booking fails.
- Every consuming and non-consuming status follows the approved policy.
- Different rooftops/days do not interfere. Advisor changes do not multiply rooftop capacity.
- Local midnight, UTC day differences, DST and a non-Toronto API actor use the same dealer day.
- Updates exclude self; moving buckets uses final values; cancellations free slots; reopening
  consumes a slot. Same-batch inserts/updates/cancellations are counted correctly.
- Partial-success DML does not reuse a slot from an update that was rejected.
- Null Rooftop and invalid capacities fail only the applicable new/increasing reservation.
- Unrelated/capacity-neutral historical edits are not newly blocked by the guard. Test the
  existing timing rule separately; do not describe its Scheduled-update restrictions as fixed.
- A private booking owned by another user still counts, tested with `System.runAs` under a
  genuine non-admin Service persona without bypass. VP still cannot perform user-mode
  Service operations; internal counting does not grant record visibility.
- A 200-row mixed batch is bulk-safe, and the documented trigger bypass is covered using
  isolated test settings only. Trusted fixture creation must not weaken restricted assertions.
- Existing executive publisher tests remain a focused Service-data regression; no live
  publisher execution or schedule is part of testing. Add unrelated suites only for an actual
  dependency, not a new broad project audit.
- A native check-only deploy must compile the exact scoped package and run focused tests.
  Actual two-session concurrency and licensed Service browser acceptance require separate
  owner approval before any race-free/live-persona acceptance claim.

## Expected feature files after separate approval

Create only these six source files initially:

```text
force-app/main/default/classes/ServiceVisitCapacityGuard.cls
force-app/main/default/classes/ServiceVisitCapacityGuard.cls-meta.xml
force-app/main/default/classes/ServiceVisitCapacityGuardTest.cls
force-app/main/default/classes/ServiceVisitCapacityGuardTest.cls-meta.xml
force-app/main/default/triggers/ServiceVisitTrigger.trigger
force-app/main/default/triggers/ServiceVisitTrigger.trigger-meta.xml
```

That is three deployable components: guard class, test class and trigger. Reuse existing
capacity/scheduling fields and validation metadata unchanged. If implementation discovers a
required permission, schema, timing-policy or UI change, stop and request the exact additional
scope instead of including unrelated working-tree files. Local validation evidence and this
plan may be updated; no feature file above exists as a result of this planning task.

## P6-02 next-workstream contract

After P6-01, extend the same trigger for after insert and call a proposed
`ServiceIntakeCaseService` plus its focused test class. Use the existing Case queue and
optional `Case__c` link. Decide intake statuses, required Case values/record type, ownership,
duplicate prevention and transactional failure behavior in that separate workstream.

The Case-link update must be capacity-neutral and must not recursively create a second Case.
Rejected/over-capacity bookings must create no Case. Do not create Cases for historical data,
change Case assignment/escalation rules or add a new Flow as an implicit part of P6-01.
Check storage headroom before authorizing live Service/Case creation. Finance/Service persona
licensing and browser acceptance remain separate; VP executive Read is not operational access.

## Risks and phase boundary

The material implementation decisions are bucket/status policy, required Rooftop handling,
fixed-timezone bucketing, private cross-owner counts, bulk partial-save accounting and parent
lock contention. The existing Scheduled timing rule is an explicit baseline limitation.
Production/user/permission changes, operational UI acceptance and concurrent live tests are
not authorized by a planning or check-only approval.

The next requested approval is **local P6-01 implementation and focused tests/check-only
only**, confirming the six recommended policies above and the six-file/three-component scope.
No deployment, live booking/data change, permission assignment, scheduler change or P6-02
implementation follows automatically.

All 17 Phase 6 items remain in the backlog. Phase 7's 23 developer/AI/integration/governance
items and Phase 8's 11 Experience Cloud/LWC portal items remain in scope, including deferred
P5 evidence with its original owners and impacts. No later-phase work is started here.
