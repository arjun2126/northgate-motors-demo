# Remaining UAT defects — scoped local candidates, not release acceptance

## Outcome and authorization

Two **separate local permission-metadata candidates** are prepared: Executive metric field
visibility (D16) and Portal Loyalty Read/FLS (D06). No dashboard/report formulas, Apex or Owner
Portal LWC files were edited by this task. D07 is diagnosed only to a submit-versus-refresh
ambiguity and remains blocked for the actual failed response. Customer A login and separate A/B
vehicle dashboards are recorded as **OWNER-REPORTED** positives, not independently retested.

No deployment, server validation, live permissions/assignments/sharing/data changes, password
operations, full-suite rerun, Git write or ng-dev access. Current owner scope and before-state
are in RUN.md. Older harness-only planning headers do not authorize or describe this UAT task.

## 1. Executive components — missing reader FLS, not a speculative formula rewrite

Read-only investigation targeted only `Executive_Service_CSI` (`00Oaj00000Ux9vdEAB`) and
`Executive_Service_Overdue` (`00Oaj00000Ux9veEAB`) and their existing Executive dashboard.
Source was retrieved into `live-source/`, never over force-app. Actual API reader is
`005aj00000feqbNAAQ`, `arjun.ngdemo@northgate.demo`, org `00Daj00001Ae3iWEAR`.

CONFIRMED — raw `metric_reader_fls.json`:
```json
"records": [],
"totalSize": 0,
"done": true
```
This query covered all permission-set IDs assigned to the identified reader, including its
profile-owned set, scoped to Executive_Service_Metrics__c. `metric_reader_object.json` separately
returns existing object `PermissionsRead=true` on the profile. No new object access is needed
for this measured reader. Actual browser reader identity must still be confirmed before assignment.

CONFIRMED — raw Analytics describe excerpts for **both** reports:
```json
"aggregates": [
  "s!CDF1",
  "RowCount"
]
```
The live report-type categories expose Name, Metric_Key__c and Captured_At__c, plus row formula
CDF1, but omit Overdue_Count__c, CSI_Score_Total__c and CSI_Response_Count__c. FORMULA1 is absent
from the reader's available aggregate catalog. Retrieved report metadata still contains the
intended FORMULA1 expressions and numeric source columns. Therefore the dashboard is referring
to a metric the **reader cannot currently resolve**; changing it to RowCount, bypassing FLS,
refreshing the publisher or fabricating data would not be a safe correction.

Prepared local dependency correction:

- New `force-app/main/default/permissionsets/PS_Executive_Service_Field_Read.permissionset-meta.xml`.
- Exactly **Read=true/Edit=false** for `Executive_Service_Metrics__c.Overdue_Count__c`,
  `.CSI_Score_Total__c`, `.CSI_Response_Count__c`.
- No object CRUD, class/system/custom permissions, report/folder shares, running-user changes,
  assignments, metrics publication, schedules or formula changes.
- Separate manifest: `manifest/uat-executive-field-read.xml`, **one PermissionSet component**.

This is a locally prepared fix for the observed missing field dependency, **not a proven live
visual correction**. Deployment alone leaves the new set unassigned and cannot resolve a user's
FLS. A separate assignment approval is needed for the confirmed intended internal reader(s).
Do not assign this internal reporting set to portal customers or reuse the broader VP set as a
workaround. After approved application, check the report aggregate catalogs as the intended
reader and then the two tiles; stop if FORMULA1 is still unavailable. Retain 24-hour stale-to-blank
and no-response CSI N/A behavior. Report formulas and the D08 geometry were deliberately preserved.

## 2. D06 — minimal existing runtime-set correction

Changed locally:
`force-app/main/default/permissionsets/PS_Owner_Portal_Dashboard_Runtime.permissionset-meta.xml`.
Exact three-entry delta, preserved in `d06_delta.diff`:

1. Add Loyalty_Transaction__c object Read; Create/Edit/Delete/View All/Modify All remain false.
2. Add Loyalty_Transaction__c.Points__c Read=true/Edit=false.
3. Add Loyalty_Transaction__c.Type__c Read=true/Edit=false.

Existing nine field grants, three Read object grants, class access, description and all other
entries remain unchanged. The pre-change source matches the live retrieved runtime set after
ignoring XML order and platform-default `viewAllFields=false`. No Batch B/Reviewer set is assigned
or amended. No Case/Visit/native Vehicle/Model/ownership-ledger permission changes.

Saved live schema confirms Id, required master-detail Loyalty_Member__c and required
Transaction_Date__c are nonpermissionable; no speculative FLS entries were added for them.
Points__c/Type__c are permissionable. Existing `getLoyalty` is unconditional even for an empty
membership, explaining why absent transaction Read/FLS can break a legitimate empty state.
No controller or LWC behavior changes are required in this candidate.

Isolation analysis: transaction sharing is parent-controlled MasterDetail. The facade continues
to use actual-caller/Contact checks, USER_MODE, both member-ID and related Contact filters,
duplicate-membership denial and 20-row pagination. **These guards do not certify native access**:
new object Read must not expose foreign transactions through an already-readable foreign parent.
Actual A/B and same-Account/native parent/child negatives remain required before security closure.
Existing Apex tests using the broader Batch B fixture cannot certify the minimal runtime-set
combination without a separately approved actual-license fixture/test plan.

Separate manifest: `manifest/uat-d06-loyalty-read.xml`, **one existing PermissionSet component**.
It is already assigned to A/B; deployment would immediately change effective permissions for
all current assignees. Owner must approve that exact delta and confirm the assignee inventory
before any deployment. No assignment or membership change is part of the candidate. No loyalty
activation, member creation, balance reconstruction or transaction backfill.

## 3. D07 — submission outcome still unknown; no speculative production fix

Read-only source review retains public Foundation context, actual caller/Contact checks, own
readable Case guard, USER_MODE comment insert, forced published flag and published-only reads.
Case Create/Edit remain denied; no Case permission broadening is justified. Previous zero-row
comment evidence and effective permission investigation were reused, not repeated.

Three local diagnostic tests use the real current `ownerPortalCases.comment()` handler with
mocked endpoints; no LWC is edited and no actual addComment is invoked:

- addComment rejection retains entered text, makes no refresh call and does not retry;
- successful addComment followed by getComments rejection clears entered text but emits the
  same generic “could not be submitted” error;
- mocked submit+refresh success returns one visible row.

This proves the current displayed error is **ambiguous about persistence**, not the cause of
the owner's actual failed action. It is not permission to fix the presentation in parallel with
Expansion or to submit another comment. Need the existing failing addComment/getComments action
responses (each action's state/error/returned Id), caseId, actual customer and timestamp. A 200
HTTP response can still contain an errored Aura action. Distinguish submission from refresh;
redact session/reset tokens and comment bodies. If no original capture exists, owner must
separately authorize one controlled synthetic attempt or narrow trace; no retry loop or trace
flag change here. D07 remains FAIL with backend cause BLOCKED; no deployable D07 candidate.

## 4. Existing ten Apex failures — disposition, not a new investigation/run

Reused `triage/results.json`, `triage/reconciliation.json` and existing register diagnoses for
run `707aj00001OOD4U`. `failure_disposition.json` preserves all ten exact result IDs, messages,
stacks, class/methods and per-row next action. No test file or production Apex correction was
made during this task and no existing failure was waived.

| Defect | Rows | Required next action | Production logic correction established? |
|---|---:|---|---|
| D01 | 1 | Actual test-only correction: deterministic same-Toronto-day capacity fixture plus explicit cross-day case in OwnerPortalVehicleBrokerTest | No; keep daily capacity/ownership/service authorization implementation |
| D02 | 2 | Actual test-only correction: explicit restricted internal runAs and legitimate Reviewer positive cases in OwnerPortalOwnershipTest and OwnerPortalShareReconcilerTest | No; do not remove the legitimate Reviewer assignment |
| D03 | 6 | Documented infrastructure BLOCKED disposition, not a pass: separately approved isolated/serial verification of Foundation, Batch B and reporting tests. Includes one @TestSetup and two inherited reporting failures | No; no fixture/business-data repair justified merely by lock contention |
| D04 | 1 | Notification-contract test work remains required: observable send outcome, independent Task and hidden-field assertions; diagnose narrowly before deciding if production code needs change | No; never force Expected 0→1 or infer delivery/FLS leakage from invocation count |

D15 remains CLOSED: 370 = 360 Pass + 10 Fail. Focused verification should follow approved
test-only changes/diagnosis, not a full-suite rerun. No >=90% fresh coverage or release regression
PASS is claimed. D01/D02 changes are **not** included in either permission manifest. D03 cannot
be accepted by documentation alone; the previously unexecuted assertions must run or receive an
explicit owner exception at acceptance, not be silently marked passed.

## 5. Customer UAT and existing D08 deployment

**OWNER-REPORTED:** Customer A successfully logged in; A and B displayed separate customer
vehicle dashboards. Record scoped PASS for A login and observed A/B positive vehicle/dashboard
separation. No screenshot/record list/timestamp was supplied in this prompt; no independent
browser run, negative direct-URL test, same-Account proof or complete security certification is
implied. Do not reopen password-reset work or withdraw prior B/history/My Cases positives.

D08 deployment is already complete. CONFIRMED — existing raw `D08_DEPLOYMENT/deployment.json`:
```json
"id": "0Afaj00000paG2TCAU",
"checkOnly": false,
"numberComponentErrors": 0,
"numberComponentsDeployed": 9,
"numberComponentsTotal": 9,
"status": "Succeeded"
```
No D08 redeployment, package regeneration or print/banner/layout walkthrough was repeated.
Deployment still does not close its visual acceptance or resolve the newly diagnosed reader FLS.

## 6. Minimum remaining checks — delta only, not a repeat full walkthrough

### Negative security (separately approved rollback tests / actual-persona checks)

1. **Changed permission combinations:** runtime+Foundation/profile as actual licensed A/B;
   own/foreign Member and transactions, empty and ambiguous membership, both cursor pages,
   direct native parent/child access including same-Account/other-readable-parent case. All
   transaction/member writes denied; stored balances unchanged. No fabricated live membership.
2. **Caller boundary:** guest/no Live Network/no portal custom permission/disabled or restricted
   identity denied; substituted Contact, foreign IDs/cursors must not broaden data. Preserve
   native Case/Visit writes and all Vehicle/Model/ownership-ledger CRUD denials.
3. **Reviewer/service boundaries:** explicit unapproved internal and external Reviewer denial,
   legitimate Reviewer positive; no/expired/exact-boundary/revoked/conflicting Ownership and
   independent Service_Authorization cases. Existing owner positive booking is not replayed.
4. **Comments:** once actual error evidence is available and a fix separately approved, own
   published comments round-trip, internal notes hidden, foreign/null Case and invalid body
   denied, no duplicated successful submit after refresh failure. Do not enable native Case writes.
5. **Internal reporting:** approved intended reader sees required metric fields/aggregate;
   no new writes/object data exposure, viewer-scoped reports retain filters, stale/CSI null
   semantics and lookup-target scope. Admin access is not Finance/Service/portal certification.

### Missing workflow/regression evidence (reuse prior positives)

- Only missing segments: actual Lead conversion/seed hygiene; saved/automatic Task owner/due
  date and email outcome; actual manager/VP/Finance approval routing/no-self-approval/write-back;
  funding/status/checklist invalid transitions and linked completion→Closed Won→eligible
  enrollment. Do not repeat Test Drive 74, Trade-In 52, Finance 64 creation, portal booking,
  service history/My Cases or historical CP2 pricing as another full-project walkthrough.
- Protect one-Quote, primary-vehicle basis, signed premium/discount, rounding and approval state
  by reusing applicable prior tests; any new write-negative tests use separately approved
  isolated/rollback fixtures, never historical Quote 00000069 or owner records.
- D01/D02 test-only corrections and D04 diagnosis need separate approval; then only affected
  tests plus one bounded D03 serial/isolated verification. Failed/unexecuted assertions remain
  open; no repeat 370-test run is needed merely to rediscover them.
- D05/D11 canonical CSV/provenance/exact Storage Usage and full strict DQ remain blocked. Do not
  re-run the known missing-file failure, regenerate data or force time-dependent report counts.
- Preserve accepted P5/P6 exceptions. Owner must explicitly disposition remaining live concurrency,
  notification/SLA clocks, Knowledge search/publication, inactive loyalty/consent operations and
  P7 native capability/placement gates; none is passed or activated by this task. Final owner
  sign-off requires the retained release/coverage/demo/visual gaps or explicit accepted exceptions.

## 7. Validation, coordination and exact next approvals

CONFIRMED — `focused-metadata.txt`:
```text
Ran 7 tests in 0.028s

OK
```
CONFIRMED — `comment-diagnosis.tap`:
```text
# tests 3
# pass 3
# fail 0
```
CONFIRMED — `harness-fast.txt` raw excerpts:
```text
Receipt consistency: PASS; 8 receipts; 91 criterion groups
Historical Apex: 360 Pass / 10 Fail; NOT rerun
PASS: selected available LOCAL checks only; review SKIPPED lines. Full project acceptance remains BLOCKED.
```
Local source conversion succeeded separately for both one-PermissionSet manifests; converted
packages are `mdapi-executive/` and `mdapi-d06/`. This is not server validation. All actual
permission effects, license compatibility, actual-persona negatives and report rerendering remain
unverified. Harness fast does not probe Salesforce; this task's separate read-only calls do.

Production source edited by this task: existing runtime set and new Executive field-only set.
Other task files: two manifests, `scripts/tests/uat_remaining_defects_test.py`,
`scripts/tests/uat_comment_diagnosis.test.mjs`, register updates and these scoped evidence files.
`source_before.json`/`scope_and_preservation.json` show **ten concurrent CSS/HTML changes in
Expansion-owned areas** outside this task. Writer attribution is not independently established;
these files were not edited, overwritten, reverted or deployed by this task. All captured Apex,
CP2 and approval source remained unchanged. Harness files were read, not edited.

**Harness handoff:** do not run old historical-baseline guards to manufacture a pass or reset their
receipts. `d08_metadata_test.py` compares all captured permission sets against a D08-only snapshot;
`validate_p8_dashboard_runtime_permission.py` expects the earlier three-object/nine-field scope.
The local D06 candidate deliberately supersedes those specific permission assumptions; neither
historical checker was run/edited. New seven-test exact-delta checks supplement them. Harness
owner should account for the approved change as a scoped successor before full local/release
gating. No hardcoded historic hash should be blindly refreshed. The orchestrator's historical
openDefects list also does not automatically include new D16; current register remains authoritative.
The fast receipt applies to the harness version that ran. The Harness stream subsequently added
the scoped preservation protocol; this receipt is not a certification of later harness edits.
No automatic repeat was triggered by unrelated work. A separate `scoped_preservation.json` uses
the current preservation helper to check the unchanged source inputs consumed by the focused
checks and classify other source drift as informational with attribution unknown. It does not
retroactively fingerprint every byte consumed by the earlier harness invocation.

**Next approval A — D16 CLOSED (owner visually accepted, 2026-10-28):** the one-component
`manifest/uat-executive-field-read.xml` check-only validation (`0Afaj00000paL8bCAE`), deployment
(`0Afaj00000paLbdCAE`, 1/1) and the owner-confirmed exact-reader assignment
(`0Paaj000018MIu2CAG`, user 005aj00000feqbNAAQ only) were performed. Read-only follow-up confirms
both source reports expose the three stored fields and FORMULA1, and the owner confirms both
Executive components render correctly. No further D16 action; do not redeploy or broaden
assignment. See `D16_ASSIGNMENT/RESULT.md` and the register closure section.

**Next approval B — D06 dry-run succeeded, not deployed:** `manifest/uat-d06-loyalty-read.xml`
validated as `0Afaj00000paNYbCAM` (Succeeded 1/1, zero errors). Live set equals the reviewed
baseline; the only delta is `Loyalty_Transaction__c` Read plus `Points__c`/`Type__c`
Read=true/Edit=false. Deciding whether to deploy still requires explicit approval of that exact
effect on the two current assignees, and functional acceptance additionally needs a member-bearing
contact (neither portal contact has a loyalty member today) plus own/foreign/same-Account/guest
and write-denial checks. No new user, assignment, sharing, membership, Case write or data scope.
D07 has no deployment candidate. See `D06_VALIDATION/RESULT.md`.

**Not deployment-ready:** neither new permission candidate has a server-validation receipt or
required security acceptance. Local candidates are ready for review/targeted-validation approval
only. Overall release remains BLOCKED; no full-project, security or visual acceptance claimed.

## Post-deployment update — 2026-10-29

The preceding D06 “not deployed” and “not deployment-ready” text is historical and superseded.
D16 was closed after owner visual acceptance. D06 was subsequently deployed under separate owner
authorization as `0Afaj00000pafVVCAY`: Succeeded 1/1, zero errors, exact validated hashes, exactly
the three authorized Read-only additions, all prior grants preserved and both assignments
unchanged. Guest access redirected to login; authenticated A/B browser tests were SKIPPED because
no sessions were available. D06 remains open for functional and negative-security acceptance; no
member/transaction fixture was created. See `../D06_DEPLOYMENT/RESULT.md` and the register's
“D06 Loyalty deployment — completed 2026-10-29” section. Overall project acceptance remains
BLOCKED.
