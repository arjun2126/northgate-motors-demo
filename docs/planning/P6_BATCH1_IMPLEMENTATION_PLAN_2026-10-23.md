# Phase 6 Batch 1 — service capacity, intake, escalation and history

Date: 2026-10-23. Status: proposed; implementation approval is pending.
Target: `ng-demo` only. Authorization remains read-only investigation and local documentation.

## Scope and precedence

Treat P6-01 through P6-04 as one approval package, implemented in backlog order. This replaces
the earlier proposal for separate P6-01 and P6-02 approval cycles. It does not authorize code,
check-only execution, deployment, live records, permissions, sharing, users or schedules.

Reuse `P6_01_CAPACITY_ENFORCEMENT_PLAN_2026-10-23.md`; do not repeat its investigation.
The owner-approved capacity policies supersede that document's pending-policy wording:

- Shared Rooftop/day capacity in `America/Toronto`, including DST.
- Requested, Scheduled, Checked_In and In_Progress consume capacity.
- Completed, No_Show and Cancelled release capacity.
- Missing Rooftop or invalid capacity fails closed for new/increasing reservations.
- Preserve the owner-controlled trigger bypass and existing timing validation.

Preserve Phase 5 acceptance WITH DOCUMENTED EXCEPTIONS: CSI shows 0 rather than N/A,
the executive publisher is not scheduled, reconciliation and optional evidence remain deferred,
and Finance/Service persona acceptance remains pending. Preserve Sales/Finance separation,
both administrators, VP metrics-only access and unrelated working-tree changes.

## Assessment inputs and limits

Use the retrieved live metadata snapshots, not an assumption that local source matches the org:

- `retrieved/p6_batch1_case_baseline/`, retrieval `09Saj00000mZAfBEAW`.
- `retrieved/p6_batch1_service_profile/`, retrieval `09Saj00000mZGcXEAW`.
- `DEMO_ORG_BACKLOG.md`, P6-01 through P6-04.
- `docs/architecture/AUTOMATION_DIRECTION.md`: no new backend Flows; retain native escalation.

The Case snapshot has an active Standard escalation rule with eight entries. Their configured
minutes are 120, 360, 240, 480, 720, 1440, 360 and 1080. Entries depend on Account country/SLA;
all use CaseCreation and Case business hours. None implements the requested general
unanswered-high-priority four-hour service policy. Standard assignment has five entries.
Preserve these existing entries; do not replace or deactivate them implicitly.

Existing `Q_Service_Intake` supports Case and includes the Service_Advisor role. Case.Service
uses NG_Support_Process: New, Working, Escalated, Closed. Its permitted origins are Email,
Phone and Web; priorities are High, Medium and Low. Case and Service Visit are Private.

`Service_Visit__c.Case__c` already supplies child relationship `ServiceVisitCase__r`.
Case already has Vehicle__c, ContactId, Service_Type__c and Escalated_On__c.
`ServiceCaseList` already joins Cases to their linked visits. Case-Service Layout has no visit
related list. That related list alone cannot display earlier visits linked to other Cases.

Access dependencies are not authorized fixes: NG_Service currently hides Case.Service;
PS_Service_Advisor has Case/visit operations but no Rooftop object permission entry.
Neither observation alone establishes the user's effective access. Verify effective grants
and sharing as an actual Service persona before operational acceptance. License capacity
and the pending Service persona remain owner dependencies; never grant VP operational access.

No new live BusinessHours, existing Case-link totals or native timed execution are claimed
verified here. The focused P6-03 resolution and Big Pickle execution specification are in
`P6_BATCH1_FINAL_DESIGN_AND_EXECUTION_SPEC_2026-10-23.md`. That document supersedes the
earlier recipient/timestamp design gate, subject to approval of its explicit limitations.

## Implementation sequence under one approval

### 1. P6-01 — capacity

Use the existing six-file plan: ServiceVisitTrigger, ServiceVisitCapacityGuard and its test,
each with metadata. Lock Rooftop parents, count private cross-owner reservations internally,
apply old/new batch accounting and keep errors free of customer details. Test partial saves,
failed moves, DST and neutral updates. Do not modify VR_ServiceVisit_FutureForNew.

### 2. P6-02 — intake and routing

Extend the same trigger after insert and add ServiceIntakeCaseService plus its test.
Proposed behavior for consolidated approval:

- Create one Case for a newly inserted consuming-status visit without Case__c. Do not backfill
  existing visits or create Cases for terminal-history inserts. Reopening an existing unlinked
  visit does not implicitly create a Case under this after-insert scope.
- Preserve a supplied Case link; do not overwrite or reparent an existing Case.
- Resolve Case.Service and Q_Service_Intake by developer name, never hardcoded org IDs.
- Set Status New, Priority Medium and Origin Web. Web denotes this system-created intake
  channel, not an assertion that an email or phone interaction occurred.
- Copy Contact, Vehicle and Service Type; derive Account from Contact where available.
  Use a neutral generated Subject. Do not copy unrelated free-text customer data.
- Set queue ownership explicitly without enabling default assignment-rule routing.
- Create Cases and link visits in bulk within the booking transaction. A Case/link failure
  must not leave an accepted unlinked booking or an orphan Case. Cover partial-success DML
  with executable tests before selecting the final error-propagation approach.
- Case-link writes are capacity-neutral; after-insert-only intake avoids duplicate recursion.
  Preserve the trigger bypass. Internal side effects do not grant users Case visibility.

Medium is the intake default. A later authorized user may raise Priority to High; Batch 1
does not infer urgency from arbitrary notes or introduce a new priority mapping field.

### 3. P6-03 — native four-hour escalation and history-based timestamp reconciliation

The owner sets four elapsed hours for High-priority Cases that remain New. Use Case.Service,
Priority High, Status New, not closed and not already escalated; CaseCreation, 240 minutes,
businessHoursSource None and disableEscalationWhenModified false. Working is the response
proxy. A status change away from New removes eligibility for this entry, not for every legacy
Standard entry. Re-entering New uses the original creation clock, not a fresh four hours.
Native timing, cancellation and re-entry require later controlled acceptance.

Keep Standard active and preserve all eight existing entries in their original relative order.
Insert the scoped service entry first. It intentionally takes precedence for matching Service
Cases; all other Cases retain the legacy evaluation path. ER_Case_HighPriority_4h is the policy
label, not a second active ruleset. Native escalation does not imply Status becomes Escalated.

Recommend the primary administrator already used by all eight native entries as a temporary
administrative escalation assignee and notification recipient. No user currently occupies
NG_Service or the Service_Manager/Advisor/Technician roles; no manager Case queue exists.
The existing intake queue remains the booking intake owner. Do not substitute VP Sales or
pretend the unstaffed Service_Manager role is a deliverable user recipient.

Native EscalationAction supports assignment and notifications, not arbitrary field updates.
The live Case Workflow contains no stamping rule. Do not assume a Case trigger or workflow
will run because the native action fires. Instead add CaseEscalationStampBatch and its test:
one Batchable/Schedulable class reads documented CaseHistory ownerEscalated events and copies
the earliest applicable event's CreatedDate into a blank Escalated_On__c. This observes native
escalation; it must never perform or replace escalation itself.

This is eventual population of the recorded native reassignment time, not an atomic native
field stamp, scheduled due time or polling time. If no ownerEscalated event exists, leave the
field null and report the gap. Same-owner escalation, history availability and rule attribution
are explicit limitations. The event identifies native reassignment, not which rule caused it.
The final specification defines scope, idempotency, tests and the four additional source files.
No reconciliation execution or schedule activation is authorized by local implementation approval.

### 4. P6-04 — service history on Case

Reuse the Case/visit lookups and report type. Add the direct visit related list to Case-Service
Layout. This covers the linked intake visit, but not the full prior-history requirement.

For an inline chronological history, propose one small read-only caseServiceHistory LWC and
CaseServiceHistoryController plus its test. Query the accessible Case first. Show visits for
the same Vehicle; when Vehicle is absent, fall back to the Case's Contact. Include visit date,
status, service type and a record link. Order chronologically with stable pagination; never
silently truncate and label results complete. Missing keys produce an explicit empty state.

Use with-sharing and user-mode queries for Case and visits. Do not reuse elevated capacity
counting for this UI. Hidden history stays hidden; inaccessible Case IDs return no history.
No copied history records, circular lookup, custom timeline framework or Vehicle-page work.
P6-05 owns the Vehicle history page. Owner approval must cover this inline UI scope because
the original ADMIN-only estimate does not account for cross-Case prior-visit history.

## Expected file boundaries

Paths below are relative to `force-app/main/default/`; feature files do not yet exist:

| Item | Proposed files |
|---|---|
| P6-01 | `triggers/ServiceVisitTrigger.trigger{,-meta.xml}`; `classes/ServiceVisitCapacityGuard.cls{,-meta.xml}`; `classes/ServiceVisitCapacityGuardTest.cls{,-meta.xml}` |
| P6-02 | Extend the same trigger; `classes/ServiceIntakeCaseService.cls{,-meta.xml}`; `classes/ServiceIntakeCaseServiceTest.cls{,-meta.xml}` |
| P6-03 | `escalationRules/Case.escalationRules-meta.xml`; `classes/CaseEscalationStampBatch.cls{,-meta.xml}`; `classes/CaseEscalationStampBatchTest.cls{,-meta.xml}` |
| P6-04 | `layouts/Case-Service Layout.layout-meta.xml`; `classes/CaseServiceHistoryController.cls{,-meta.xml}`; `classes/CaseServiceHistoryControllerTest.cls{,-meta.xml}`; `lwc/caseServiceHistory/caseServiceHistory.{html,js,js-meta.xml}`; proposed `flexipages/NG_Service_Case_Record_Page.flexipage-meta.xml` |

The proposed Case page is not globally activated by a local/check-only approval. Determine
the existing live page assignment before any later activation. Class access, record-type
visibility and any operational permission changes require an explicit security scope first.
Existing dirty escalation metadata must be diffed against the retrieved baseline; never
deploy the whole working tree or overwrite unrelated changes.

## Validation and acceptance gates

1. Run focused capacity and intake tests, including a 200-row batch, private bookings under
   System.runAs, rejected bookings creating no Case, prelinked visits, terminal imports,
   correct queue/record type and transactional rollback/partial-save behavior.
2. Test history using non-admin access, hidden visits, inaccessible Cases, Vehicle/Contact
   matching, empty states and pagination. Run existing LWC checks where available.
3. Run ExecutiveServiceMetricsPublisherTest as a Service-data regression in the test sandbox
   transaction only; never invoke the live publisher or schedule it.
4. Validate native criteria/actions and the history-based timestamp implementation, including
   missing evidence, idempotency and later status changes. Apex unit tests do not establish
   that Salesforce's four-hour escalation scheduler fired or emitted a native history event.
5. Check-only deploy only the exact approved source package to ng-demo with focused tests.
   Record raw output, job IDs, coverage and CONFIRMED/REFUTED claims. An unexpected failure
   stops the affected work under repository escalation policy.
6. Later, separately authorized live acceptance must capture capacity_block.png,
   case_queue.png, escalation.png and case_timeline.png under evidence/P6. Native elapsed-time
   behavior, timestamp, record-page activation, two-session contention and licensed Service
   browser access remain pending until actually exercised. Check storage before live writes.

No feature tests, check-only deployment or live acceptance ran during this documentation task.
Local documentation checks establish only plan integrity, not feature acceptance.

## Consolidated approval requested

Approve one Batch 1 local implementation, focused tests and check-only package under the
policies above, including intake defaults and the inline history UI. No live deployment,
records, permissions, assignments, page activation or scheduler changes are included.

In that same response, approve the temporary primary-administrator recipient, Standard-rule
extension and eventual history-based timestamp semantics/limitations in the final execution
specification. Four elapsed hours is already the owner's timing decision. Reconciliation
activation and native timed acceptance remain a later approved live window. This is one batch
authorization, not four separate item approvals; it is not a claim that live acceptance passed.

The remaining Phase 6 items and all Phase 7/8 backlog items retain their scope and order.
