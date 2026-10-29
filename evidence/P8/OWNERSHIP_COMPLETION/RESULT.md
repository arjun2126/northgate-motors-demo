# Ownership correction and remove-only reconciliation — partial, not deploy-ready

## CONFIRMED — metadata corrections accepted by actual Salesforce check-only

Changed exactly:
- `Contact_Vehicle_Relationship__c/fields/Verified_By__c.field-meta.xml`: User lookup
  deleteConstraint Restrict → SetNull. Lookup remains optional, history retained. A null reviewer
  is not a valid active entitlement; deletion of a reviewer must not become implicit authority.
- Both `Portal_Entitlement__c.sharingReason-meta.xml` files (new ledger and existing Vehicle):
  explicit `<fullName>Portal_Entitlement__c</fullName>` added.

`ledger_report.json` componentSuccesses have success=true for the actual Verified_By field and
both sharing reasons. IDs returned are CHECK-ONLY artifacts, not evidence of a live deployment.
All previous dependent compilation errors cleared. No source correction was made after test failure.

## REFUTED — ledger validation/tests pass

Command:
```sh
sf project deploy validate --target-org ng-demo --manifest manifest/p8-ownership-ledger-local.xml --test-level RunSpecifiedTests --tests OwnerPortalOwnershipTest --wait 10 --json
```
Raw fields (`ledger_report.json`):
```json
{"id":"0Afaj00000pPMPlCAO","status":"Failed","checkOnly":true,"numberComponentErrors":0,"numberTestsTotal":6,"numberTestsCompleted":1,"numberTestErrors":5}
```
Exact shared failure:
```text
System.DmlException: Operation failed due to fields being inaccessible on Sobject Vehicle__c, check errors on Exception or Result!
Class.OwnerPortalOwnershipTest.fixture: line 26, column 1
```
Affected methods (all in OwnerPortalOwnershipTest):
```text
bulkPendingDoesNotGrantOwnershipAndUnapprovedInternalCannotReview
evidenceAndServerStampsAreRequired
explicitRevocationRemovesOnlyApplicationSharesAndConsent
sameAccountAndReservationCannotSubstituteOwnership
terminationRequiresReasonAndNeverExtendsVerifiedInterval
```
The half-open interval helper test is the sole success; it is not a native share-lifecycle pass.
Raw validation warnings: Trigger 0%, OwnershipService 0%, OwnershipGuard 8.411%; all below 75%.
No LWC changes/tests. Full stacks, coverage locations and messages are in `ledger_report.json`.
Failed source/test line stopped under AGENTS.md; no permission broadening, symptom patch,
test weakening or speculative retry. Existing old metadata errors are NOT still blockers.

## Independent local reconciliation implementation (NOT validated)

Added `OwnerPortalShareReconciler.cls` and metadata, `OwnerPortalShareReconcilerTest.cls` and
metadata, and `manifest/p8-ownership-reconciliation-local.xml`. These do not alter the failed
fixture or existing deployed feature paths and were prepared independently after test escalation.
Only local XML parsing/source conversion performed for this added candidate; no Apex pass claimed.

- Remove-only Batchable/Schedulable implementation; no grant writer, ownership DML, automatic
  scheduling, retry loop or public/Aura endpoint. Standard internal reviewer custom permission
  required for the public maintenance/start/schedule entry points. No external permission extension.
- Each batch scope locks affected Vehicles before reading all ledger owners, then removes only
  Vehicle/ledger share rows whose RowCause is `Portal_Entitlement__c` and whose recipient does not
  match the unique active verified owner. Missing/future/expired/revoked/missing-evidence/missing-
  reviewer/conflicting owners and inactive/non-Plus/wrong-Contact recipients fail closed for these
  app-owned grants. Service_Authorization alone never supports a Vehicle grant.
- Same-Account equality/reservation is never consulted. Group recipients cannot qualify as the
  exact customer and app-reason group grants are removed. Unrelated Manual/Owner/other-reason
  shares are preserved; the routine never tries to subtract rights granted by a different source.
- Expiration compares From inclusive / To exclusive and Revoked_At using the execution instant;
  no record edit is required for the next reconciliation to detect expiry. Batch covers Vehicles
  even when a stale Vehicle grant no longer has any ledger, and preserves current valid grants.
- Scope deletes are all-or-none; an exception rolls back that batch scope. Batch job errors must
  be monitored, not silently treated as successful reconciliation. Source tests added for clock
  boundaries and unauthorized maintenance, but not executed or claimed lifecycle/native-API proof.
- Existing ledger trigger drafts synchronous app-share removal and associated consent revocation
  on explicit immediate ownership termination. Those paths are NOT proven: the tests failed at
  fixture creation before reaching them. Native expiry/own/foreign/recalculation/delete lifecycle
  tests remain required once the fixture-access diagnosis is approved.

## Managed sharing reasons and recalculation — evaluated limits

Custom sharing reasons provide stable application provenance and preserve unrelated grants;
Salesforce does not automatically expire those shares at an arbitrary ledger datetime. A managed
sharing recalculation can invoke an appropriate batch to rebuild/prune app grants when configured
or explicitly run. It is not a clock event and does not eliminate the need for persistent timed
maintenance. The new batch can perform the remove-only pruning, but no sharing-recalculation
registration/owner change, cron activation or live manual run was performed. No parent Vehicle
metadata/OWD/settings were rewritten to register speculative metadata.

## Timing guarantees and exact activation dependencies

**Explicit termination:** intended same-transaction deletion via ledger trigger, failing the
transaction if managed-share revocation fails. Not validated yet. Unrelated access cannot be
revoked while simultaneously preserving its source; other-source access must be audited separately.

**Clock expiration:** scheduler/recalculation is EVENTUAL, NOT immediate native API enforcement.
No clock-driven process runs in this implementation unless activated. Even after activation,
Salesforce scheduling/async queue delays have no demonstrated hard deadline here. For an hourly
schedule the nominal detection interval is up to one hour PLUS queue/batch execution delay;
neither the batch nor a managed sharing reason can honestly promise zero stale native-access window.
The current portal continues to grant no Vehicle access, so no new exposure was enabled.

After successful full lifecycle/native API tests and separate deployment/activation approval:
1. Use a named internal maintenance user with the reviewer custom permission and required runtime
   privileges; never customer/admin-context acceptance as a substitute for customer native tests.
2. Run one approved initial `Database.executeBatch(new OwnerPortalShareReconciler(), 50)` and verify
   app-grant deltas only; this is a sharing write and is NOT authorized/executed now.
3. If the owner separately approves the nominal hourly cadence, the proposed activation is:
   `System.schedule('NG_P8_Share_Reconcile', '0 0 * * * ?', new OwnerPortalShareReconciler());`
   Do not run it now. Verify actual CronTrigger/AsyncApexJob execution, error counts and monitored
   completion. No self-scheduling or claim of a scheduler SLA. No schedule was created or tested.
4. Approve an operational owner/monitor and a stop-access procedure for missed/failed maintenance.
   Object rights and grants must not be enabled until the required stale-access timing policy is
   resolved. Merely starting this job is NOT proof of the original strict native-expiry requirement.
5. If the requirement is unconditional denial at the exact expiry instant, this source alone is
   insufficient: a separately approved native-access architecture/enforcement decision is still
   needed. No unverified restriction-rule capability or broad object-access change is assumed.

## Completed versus blocked / exact candidate scope

Metadata syntax correction: accepted in actual check-only. Ledger implementation: compiles, tests
fail; not accepted. Reconciler: independent local source only, uncompiled/unvalidated in Salesforce.
P8-05 owned details/photos and P8-07 appointment wizard/create: NOT completed or newly enabled.
Their existing controller/LWC safe disabled states, booking/capacity/intake, CP2, service, loyalty
and reservations remain untouched. No competing Flow or booking process introduced.

Full candidate manifest `manifest/p8-ownership-reconciliation-local.xml`: the original ledger
object/fields/reason, Vehicle app reason, internal custom permission/reviewer set, ownership
service/guard/test, new reconciler/test, and ledger trigger. No LWC/controller/ServiceVisit changes,
external rights, assignments, data, scheduled jobs, Builder or publication components. Exact paths
and hashes are in `candidate_source_hashes.json`. This is NOT a deploy-ready or successfully
validated package; the earlier ledger validation excludes the new reconciler classes.

## Escalation / last verified state / owner action

Last known-good result: metadata compiles with zero component errors in `0Afaj00000pPMPlCAO`;
only one helper test passed. Existing deployed A/B/C are not replaced by this check-only. Exact
failure is at fixture Vehicle insert line 26; underlying inaccessible fields/trigger path have not
been diagnosed. No asserted production defect, security correction or permission workaround.

Owner action: review the exact failure using
`sf project deploy report --target-org ng-demo --job-id 0Afaj00000pPMPlCAO --json`, then authorize
the bounded fixture-access diagnosis/correction and focused rerun, retaining actual reviewer and
Plus personas and all security assertions. Do not grant broad permissions to make it pass.
Separately decide the required native-access expiry policy before enabling rights; do not treat
eventual pruning as an immediate guarantee. Existing source errors, failed tests and snapshots are
preserved. No deployment/live records/ownership/external users/shares/job activation/publication,
staging/commit/push/cleanup or ng-dev access in this execution.
