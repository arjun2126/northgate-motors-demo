# Phase 6 Batch 1 — final design resolution and Big Pickle execution specification

Date: 2026-10-23. Prepared using GPT-6.1 Sol. Status: ready for one local implementation
approval, subject to the timestamp limitations below. No implementation approval is implied.
Target: `ng-demo` only, org `00Daj00001Ae3iWEAR`. Never access another org.

This resolves only P6-03. P6-01, P6-02 and P6-04 retain the consolidated plan's designs.
Evidence: `P6_03_FINAL_DESIGN_EVIDENCE_2026-10-23.md` and read-only retrieval
`09Saj00000mZPWAEA4` under `retrieved/p6_03_final_design/`.

## 1. Recipient decision

Recommend the existing primary administrator, identified by the assignee already in Standard's
eight entries, as both escalation assignee and notification recipient. This is a temporary
administrative fallback, not a staffed Service Manager persona or a production support SLA.

There are no users, active or inactive, with NG_Service or a Service_Manager, Service_Advisor
or Service_Technician role. The roles exist but are empty. The only Case queue is
Q_Service_Intake; it contains the Service_Advisor role group, includes bosses and disables
member email. It is an intake destination with no staffed second tier. Sending an already
queue-owned Case back to that same queue would not establish a managerial handoff.

The primary administrator is active and already has System Administrator access. Using the
existing native recipient requires no user, membership, role, permission or sharing expansion.
Preserve the Backup Admin and the VP Sales persona. Do not turn either into a Service operator.
Read the existing metadata assignee when constructing the rule; do not embed a personal
identity or org-specific User ID in Apex. Reuse the existing reassignment/notification templates.

## 2. Native escalation configuration and timing contract

Extend the active Standard rule with one leading entry. Do not activate another ruleset.
Preserve all eight existing entries, their relative order, recipients, templates, clocks and
business-hours settings. The policy label is ER_Case_HighPriority_4h; native entries do not
provide a separate fullName for that label.

New-entry eligibility:

- RecordType.DeveloperName = Service.
- Priority = High; Status = New; IsClosed = false; IsEscalated = false.
- No Account-country/SLA requirement. No new Owner or queue-membership eligibility condition.
- Age Over = 240 minutes; escalationStartTime = CaseCreation.
- businessHoursSource = None: four elapsed hours, including nights, weekends and DST changes.
- disableEscalationWhenModified = false: unrelated edits do not count as a response or stop
  the clock. Do not use CaseLastModified or disable-on-first-edit.
- Action: reassign and notify the existing primary administrator using Standard's existing
  templates; retain notifyCaseOwner false. No new email recipients or templates.

Four hours is the due threshold, not a guarantee of execution at an exact second. Salesforce's
native processing may execute later. The timestamp must describe an observed event, not the
threshold. No accelerated production rule or shortened test timer is authorized.

Status and priority semantics:

| Change | Required interpretation |
|---|---|
| Remains High/New | Eligible at CreatedDate + four elapsed hours. |
| New becomes Working or Escalated before execution | No longer eligible for the new entry. This does not mean a customer reply was verified. |
| Case closes before execution | No escalation under the new entry; no fabricated timestamp. |
| Priority drops below High or record type changes | No longer eligible for the new entry. |
| Returns to High/New before a native escalation | Re-evaluate against the original CreatedDate. No new four-hour period and no permanent answered flag. An already-old Case may be due immediately. |
| Status changes after native reassignment but before reconciliation | Preserve and record the past reassignment event; do not erase it because current Status is Working/Closed. |
| IsEscalated becomes true | The new entry no longer qualifies. Do not reset the flag or force Status = Escalated. |

Native rule evaluation is first-match. The leading entry intentionally overrides legacy timing
for its matching High/New Service Cases. Outside that scope, existing behavior remains. When
a Case stops matching this entry, another existing Standard entry may still apply. Therefore,
"Working does not escalate under P6-03" is not a claim that no legacy rule can escalate it.
Preventing all such legacy behavior would require a separate policy change and is not included.

The timing contract is based on current state, not proof that the Case has never left New.
Do not add a response-tracking field to change this contract. Native pending-action removal,
rule re-evaluation and status/priority re-entry must be checked in the later live window.

## 3. Timestamp conclusion and smallest supported approach

**Native action alone cannot write Escalated_On__c.** The official EscalationAction schema
provides assignment, timing and notification fields, with no arbitrary custom-field update.
The live DateTime field is writable and non-formula. The live Case Workflow has only the
ChangePriorityToHigh field update and no workflow rule or escalation timestamp action.

Do not treat ordinary DML order-of-execution documentation as proof of a callback from a
native timed escalation. Neither a trigger nor a new workflow bridge is established by this
investigation. New workflow/Flow automation is not the chosen approach.

The documented CaseHistory special value ownerEscalated means "The owner of the case was
changed due to case escalation." Live describe confirms ownerEscalated is available and
CreatedDate is DateTime. Use this event as evidence for a narrow Apex reconciliation job:

1. Add one CaseEscalationStampBatch class implementing Database.Batchable and Schedulable.
   Its scheduler entry only starts the batch. Do not introduce a queueable/trigger framework.
2. Require an explicit rollout boundary in the batch/scheduled instance. Select only Service
   Cases created on/after that boundary with blank Escalated_On__c. This avoids historical
   backfill. An activation time and schedule are selected only in a later approved live window.
3. For each bounded batch, read ownerEscalated history for those Case IDs in bulk. Select the
   earliest event CreatedDate per Case. Duplicate ID/name history rows must not cause extra
   writes or change the selected timestamp. Never query/DML once per Case.
4. Re-read/lock the applicable Cases before updating, rechecking Service scope and blank
   timestamp. Write only Escalated_On__c. Never overwrite an existing value. A repeated run
   is a no-op. Do not require current High/New/IsEscalated: later status or flag changes cannot
   invalidate an already recorded native reassignment.
5. Use narrow internal system context for this maintenance invariant; expose no UI/API method
   or new user permission. It must not reassign Cases, set Status/IsEscalated, send mail,
   execute assignment rules, or perform the four-hour eligibility scan itself.
6. With no matching history, write nothing. Return/log aggregate outcomes through the existing
   job result/logging patterns, without customer details. Do not invent a timestamp from NOW(),
   LastModifiedDate, CreatedDate + four hours, or manual Owner changes.
7. An unexpected validation/DML failure stops the affected work. Do not change a Case
   validation rule, suppress the error or retry speculatively to force stamping to succeed.

### Exact semantics and remaining limitations

Escalated_On__c means **the earliest recorded native escalation reassignment time for an
in-scope post-rollout Service Case**, copied later. It is not necessarily the P6-03 rule's
execution time: history does not identify the originating rule. Other preserved Standard
entries may generate the same event type. Do not claim rule-specific attribution.

Population is eventual. A later owner-approved 15-minute schedule is a reasonable demo
cadence, but neither that cadence nor Salesforce job timing guarantees a 15-minute bound.
Without later activation or an explicitly approved one-off run, the field stays unpopulated.
No schedule or one-off execution is part of the requested local approval.

If escalation targets the current owner and emits no ownerEscalated row, or history is missing,
deleted or unavailable, this approach cannot recover an exact timestamp. Leave null and report
the limitation. The normal intake-queue-to-administrator path changes owner, but its actual
native event must still be observed in controlled acceptance. This is not an atomic timestamp
guarantee for every possible escalation. Exact universal/atomic stamping remains unsupported
by the evidence gathered; do not silently describe that stronger acceptance criterion as met.

Live queries returned zero IsEscalated Cases, zero non-null Escalated_On__c values and zero
ownerEscalated history rows. Thus the API/schema path is verified, but no existing live event
can prove end-to-end native timing/stamping behavior without a separately approved live test.

## 4. Exact P6-03 implementation components

Modify one existing component:

```text
force-app/main/default/escalationRules/Case.escalationRules-meta.xml
```

Add exactly four source files, two Apex components:

```text
force-app/main/default/classes/CaseEscalationStampBatch.cls
force-app/main/default/classes/CaseEscalationStampBatch.cls-meta.xml
force-app/main/default/classes/CaseEscalationStampBatchTest.cls
force-app/main/default/classes/CaseEscalationStampBatchTest.cls-meta.xml
```

No new field, Case trigger, Flow, workflow, queue, template, permission set or scheduled-job
record. Escalated_On__c remains the existing DateTime. All other Batch 1 component boundaries
remain in P6_BATCH1_IMPLEMENTATION_PLAN_2026-10-23.md.

## 5. Single execution task for OpenCode Big Pickle

After explicit approval, assign the following as one task:

> Implement Phase 6 Batch 1, P6-01 through P6-04, locally and in backlog order using the
> consolidated plan and this final P6-03 specification. Do not repeat capacity investigation
> or redesign intake/history. Preserve approved capacity policies, trigger bypass and timing
> validation. Reuse the same Service trigger for capacity and intake. Preserve Phase 5 accepted
> exceptions, Sales/Finance separation, both administrators and VP metrics-only access.
>
> Implement P6-03 by extending Standard and adding only the history reconciliation batch/test
> specified above. Use the existing primary-administrator fallback recipient. Do not replace
> native escalation with Apex. Accept eventual history-evidenced timestamp semantics and
> report missing-event/same-owner/rule-attribution limitations explicitly.
>
> Inspect dirty source before each edit and preserve unrelated changes. The local escalation
> XML currently matches the fresh retrieval; its pre-existing administrator substitutions
> relative to Git HEAD must remain. Do not deploy the working tree wholesale.
>
> Add focused executable coverage for capacity, intake, native metadata configuration and
> history UI as specified in the consolidated plan. For timestamp reconciliation, test earliest
> event selection, duplicate history rows, missing evidence, existing timestamp, scope/rollout
> boundary, 200-row processing, idempotency and later Working/Closed states. CaseHistory is
> read-only: use small in-memory synthetic event inputs through a private @TestVisible seam
> for event-selection logic, plus real test-transaction Case queries/updates for integration.
> Do not insert fake CaseHistory or claim manual IsEscalated DML simulates the native timer.
>
> Run the existing ExecutiveServiceMetricsPublisherTest regression in test isolation, never
> the live publisher. Build an exact scoped package and perform check-only deployment to
> ng-demo with focused tests. Record raw outputs, job IDs and coverage; distinguish test-proven
> behavior from later native timed acceptance. Stop and escalate unexpected failures.
>
> No live deployment, records, security changes, users, memberships, page activation, scheduling,
> one-off reconciliation execution, Git staging, commit or push. Do not access ng-dev.
> Finish with files/diff, focused validation evidence and remaining live acceptance gates.

### Later live acceptance, not part of local execution approval

Observe an eligible Case at the four-hour threshold, actual reassignment, notification and
ownerEscalated row. Then approve one reconciliation run and compare Escalated_On__c exactly
with that row's CreatedDate. Check cancellation/re-entry and an unrelated Standard-rule Case.
Check same-owner behavior separately without assuming an event exists. Do not use
Test.stopTest() as proof of Salesforce's native timer. Do not mark P6-03 complete until its
accepted timestamp semantics and actual timed behavior have evidence or an explicit exception.

## 6. One consolidated approval request

Approve Big Pickle to implement all P6-01–P6-04 locally, run focused tests and perform the
scoped check-only deployment to ng-demo, including the existing intake/history designs,
temporary primary-administrator escalation recipient, Standard-rule extension and four new
timestamp source files. Four elapsed hours is already fixed by the owner.

This approval must explicitly accept eventual history-based timestamp semantics, the missing
event/same-owner and rule-attribution limitations, and later live activation/acceptance gates.
If atomic or universally populated timestamps are required instead, P6-03 remains unresolved;
do not assign Big Pickle an unsupported stamp implementation or silently waive that requirement.

No live changes are authorized by this request. Operational Service persona acceptance and
the original P6 evidence requirements remain pending. All other Phase 6–8 scope remains intact.
