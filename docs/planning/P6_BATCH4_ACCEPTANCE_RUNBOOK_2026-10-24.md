# Batch 4 — deferred activation and acceptance runbook

These steps require separate owner authorization. They were not executed during local work or
check-only validation. Batch 4 deployment, live records, assignments, Knowledge enablement,
publication and page activation are separate approvals; none is implied by this document.

## P6-14 native SLA

- New process: `NG Platinum Care`, active metadata but never the existing process replacement.
  Milestones: `NG First Response` (240 minutes), `NG Resolution` (2880 minutes), non-recurring.
  Both use the existing Default business-hours calendar; these are 4/48 business hours, not
  elapsed hours or a promise of 24-hour support. Existing calendar/timezone settings are untouched.
- Enrollment is explicit: an authorized owner creates an appropriate Entitlement, associates
  this process, and attaches it only to a matching authorized Service Case. Check the entitlement
  Account, Contact, validity dates and actual service agreement. No automatic Platinum eligibility
  inference from loyalty, historical Cases or Account names exists.
- Native clocks start from Case.SlaStartDate. Native CaseMilestone records contain StartDate,
  TargetDate, CompletionDate and IsViolated. New metadata does not backfill existing Cases.
- An advisor records `Case.First_Response_On__c` only after an actual customer response. Working,
  assignment, escalation, Case creation and closure do not imply a first response. Future and
  pre-Case timestamps are rejected. The field is history-tracked. Updating a recorded timestamp
  does not revise an already-completed native milestone; resolve disputed evidence explicitly.
- `CaseMilestoneTrigger` delegates to `CaseMilestoneService` after update, honoring the existing
  org bypass. Only named Northgate milestones on this process's Service Cases are eligible for
  narrow internal completion writes. Response completes on its first recorded value; first
  closure completes resolution. Reopen/reclose never overwrites completion history. Closing
  without response does not fabricate response evidence. There is no sender or scheduled job.
- `Case-NG Service SLA Layout` and `NG_Service_SLA_Case_Page` are new and unassigned. The page
  includes native Visualforce `apex:milestoneTracker`, standard details and existing service
  history. `NG_Case_Milestones` uses the standard Case controller, not an elevated custom UI
  controller. `PS_Service_SLA` provides the response field and native evidence reads/page access,
  not Case CRUD, entitlement edits, View All or Modify All. Existing Service Advisor grants are
  still required. Explicit Account Read is the native prerequisite for Entitlement Read.
- Breach report: `NG_Service_Operations/Native_SLA_Breaches`, using Salesforce's native
  `CaseMilestone` report type and `IS_VIOLATED=true`. It includes native milestones across
  accessible Cases, including completed-late breaches. It is not the simulated Service Visit
  overdue report and does not alter that report or its expected population.

After deployment and separate authorization, assign the new page/layout and permission set only
to approved personas. Use a separately approved isolated entitlement/Case. Capture native targets,
actual timer rendering, response/closure completion and breach reporting as the Service user.
An elapsed timer/breach and screenshots remain live acceptance, not inferred from tests.

## P6-15 Knowledge

Follow `docs/knowledge/README.md`. Knowledge was disabled during Batch 4 preparation; the
subsequent owner browser check and read-only retrieval `09Saj00000mhMEYEA2` confirm both Knowledge
and Lightning Knowledge enabled. That prerequisite blocker is resolved. Ten local drafts still
do not satisfy native import, search, publication or Case-attachment acceptance. Body field,
category group and an unassigned article layout are prepared separately, not part of the deployed
Batch 4 package. Obtain bounded configuration/data/publication/attachment approvals and verify
actual author/reader access before execution. No feature re-enablement is needed.

## P6-16 consoles

New apps: `Northgate_Sales_Console` and `Northgate_Service_Console`. Existing Sales/Service apps
are unchanged. Sales Console retains the accepted Quote Builder, Quote Summary and Finance
record-page references. Service Console exposes existing service objects and reporting; it does
not grant those records. No Omni-Channel routing or presence configuration is added.

`PS_Northgate_Consoles` contains only application visibility and the native console permission,
with no object/FLS/sharing expansion. Do not merge or repurpose the existing Sales and Finance
identities. A future dual-role demonstration requires an owner-approved existing persona and
only already-approved object grants; console navigation alone grants no Sales or Finance data.
After separate assignment approval, open both apps as that persona, verify workspace tabs and
existing Quote/Finance entry points, and verify hidden records remain hidden. Capture browser
evidence. Do not claim dual-role browser usability from metadata validation alone.
