# Phase 8 minimal dashboard runtime permission fix — local preparation only

**Deployment update (§76, 2026-10-28 UTC):** exact candidate validated 0Afaj00000pTPCACA4
(1/1, 22/22 tests), Quick Deployed 0Afaj00000pT3OYCA0 (1/1), and assigned only to A/B via
0Paaj000018ByQMCA0 / 0Paaj000018ByQNCA0. Live native CRUD/sample isolation checks confirmed;
effective-field API hit UNKNOWN_EXCEPTION and stopped. Browser UAT NOT RUN; Phase 8 not complete.
Current receipts/limitations: `evidence/P8/DASHBOARD_RUNTIME_DEPLOYMENT/RESULT.md`.
The preparation-only/approval-pending state below is historical; assignments.plan.json remains
the original reviewed plan, not an execution receipt.

Target ng-demo 00Daj00001Ae3iWEAR. No deployment/check-only deployment, assignment, Salesforce
record/share/membership/security change, Git operation or browser/runtime mutation. No sender or
password work. Completed pre-restart live readbacks were reused, not repeated.

## Decision and exact changed files

The unchanged controller is suitable for a **guarded portal runtime** grant based on source review:
all 12 exposed methods preserve the real caller's Foundation context or delegate to a broker
that obtains it. No unguarded customer-identity selector or arbitrary system-mode CRUD endpoint
was identified. A separate read-only facade is not necessary for the stated isolation controls.

This is NOT a claim of a read-only portal: granting Apex class access grants all its exposed
methods, including approved controlled booking and potentially own-Case comments. No per-method
Apex class permission exists. Owner approval must explicitly cover this capability before assignment.
If the desired policy is instead **no writes through any endpoint**, do not deploy/assign this
candidate; a separately scoped read-only facade/LWC route would then be required. No such policy
or implementation is silently substituted here.

New maintained files:
```text
force-app/main/default/permissionsets/PS_Owner_Portal_Dashboard_Runtime.permissionset-meta.xml
manifest/p8-dashboard-runtime-permission.xml
scripts/tests/validate_p8_dashboard_runtime_permission.py
evidence/P8/PORTAL_PERMISSION_FIX/assignments.plan.json
evidence/P8/PORTAL_PERMISSION_FIX/RESULT.md
```
Additional generated raw evidence/readback/converted-package paths are enumerated exactly in
file_inventory.json. No pre-existing Apex, LWC, profile, permission set, fixture or existing manifest
was edited. All 55 saved development-deployment source/manifest hashes still match. The three
reviewed Apex bodies match the fresh scoped live retrieve under deployed_guard_readback/.

## Scoped metadata diff

One new PermissionSet, PS_Owner_Portal_Dashboard_Runtime; manifest contains only that component,
API 68.0. No modifications to Foundation, the hardened profile, full Batch B or any existing
rights. A and B keep their current Foundation/profile assignments and site membership.

Exact added grants:
```text
Apex class: OwnerPortalBatchBController
Object Read only: Case, Service_Visit__c, Loyalty_Member__c
Field Read only:
  Case.ContactId
  Service_Visit__c.Status__c
  Service_Visit__c.Service_Type__c
  Loyalty_Member__c.Points_Balance__c
  Loyalty_Member__c.Tier__c
  Loyalty_Member__c.Status__c
```
All three object allowCreate/allowEdit/allowDelete/viewAllRecords/modifyAllRecords=false. All six
FLS editable=false. No user/system/custom permissions, record-type visibility, tabs, groups,
sharing reasons or shares. No Vehicle/Vehicle_Model/ledger/Rooftop/financial object grant;
no direct OwnerPortalVehicleBroker class grant (not the exposed LWC facade). No native Case or
Visit writes; no full Batch B assignment.

Minimality is derived from the **dashboard's** three USER_MODE queries and fresh live describes,
including selected AND filtered fields. Case.IsClosed/Id and required Visit.Contact__c,
Visit.Scheduled_Start__c, Member.Contact__c are permissionable=false; their read access comes
with parent-object Read, not invented FLS entries. Existing Foundation already supplies required
own Contact/Account Read and Contact.AccountId FLS. No duplication of those existing grants.

This does not claim to repair every child panel: history adds Mileage_At_Checkin__c/Case__c FLS,
Case details require further Case FLS, and loyalty transactions require another object/FLS set.
Those unrelated grants are deliberately excluded from this three-object dashboard correction.
Existing implementations/permissions are preserved, not broadened to disguise unavailable states.

## All exposed methods reviewed

The following are the complete 12 @AuraEnabled **methods**, not the @AuraEnabled DTO properties.
Source line references are unchanged by this work.

| Method | Authorization and read/write boundary | Review result |
|---|---|---|
| getDashboard (:33) | Foundation actual active Plus/custom permission/Live Network/own Contact+Account; requireCaller matches Contact to actual User; Case/Visit/Member queries filtered to caller Contact WITH USER_MODE; duplicate Member fails closed | Suitable; exact native Read/FLS supplied by candidate |
| getHistory (:58) | Foundation + requireCaller; USER_MODE Visit.Contact filter; linked Cases additionally Contact-filtered; foreign linked Case IDs masked; bounded cursor | Suitable; extra history FLS not added here |
| getCases (:62) | Foundation + requireCaller; USER_MODE Case.ContactId filter and bounded cursor | Suitable; no Case write capability granted by object metadata |
| getLoyalty (:66) | Foundation + requireCaller; own Member; duplicates denied; transactions must match Member and Contact; stored balance only; bounded reads | Suitable; Transaction object/FLS deliberately not included |
| getVehicles (:70) | Delegates to broker.vehicles; broker obtains Foundation context itself, verifies actual User/license/Contact and own Account; current evidence-reviewed Ownership DTO only | Suitable; no native Vehicle/Model/ledger Read needed |
| getVehiclePage (:74) | Same broker path plus Vehicle-typed cursor validation and bounded page | Suitable; no caller Contact argument |
| getAppointmentOptions (:78) | Broker obtains Foundation/actual caller; exact Vehicle requires one current Ownership AND one separately reviewed service consent; only active eligible rooftop/catalog choices | Suitable; no native Rooftop/Vehicle grant |
| bookAppointment (:82) | Broker obtains Foundation/actual caller; typed IDs, active catalogue, future time, token validation; Vehicle row lock; ownership+consent rechecked before/after system insert; bypass flag denied; contact-derived request key/fingerprint/replay binding; duplicate/capacity/intake paths reused with rollback | Guarded write remains reachable; requires current authority, not native Visit or Case Create |
| requestAppointment (:86) | Foundation then unconditional unavailable exception; legacy no-token write path remains disabled | No write permitted |
| createCase (:92) | Foundation + requireCaller; server derives Contact/Account/queue/record type/status/origin/priority; bounded text; insert AS USER | New set adds no Case Create; existing USER_MODE denial retained. Do not add write FLS or claim this method bypasses native CRUD |
| addComment (:97) | Foundation + requireCaller; USER_MODE readable Case with ContactId=actual caller; bounded nonblank text; server forces published=true; insert AS USER | Conditional own-Case comment write, not foreign Case/internal-note editing; do not promise object Read makes this endpoint read-only |
| getComments (:101) | Foundation + requireCaller/own readable Case; USER_MODE query restricted to IsPublished=true and bounded list | Suitable; internal notes remain filtered |

Common Foundation gates remain unchanged: UserType=PowerCustomerSuccess, exact Plus licence,
IsActive, Contact link, portal custom permission, nonblank actual Network, exact Northgate name,
owners prefix, Live status, own Contact/Account USER_MODE reads. Neither org/admin context nor
caller-supplied identity is a bypass. Class permission checks and object/FLS checks remain additive
to these gates, not replacements for them.

Broker SYSTEM_MODE is deliberate capability infrastructure, not native external Vehicle CRUD.
Ownership and Service_Authorization remain independent, evidence/reviewer/time/revocation checked;
conflicting ownership/duplicate consent fails closed. Server DTO excludes inventory, cost, finance,
reservation, evidence and other-customer history fields. No data, authorization interval or sharing
change is part of this correction.

Native visibility caveat: USER_MODE plus Contact predicates protects portal outputs; granting object
Read still requires review of other native sharing sources. A permission set cannot subtract access
another assignment supplies. Verify effective denial for Case/Visit writes/Vehicle CRUD and
foreign native records before accepting assignment. Do not claim all native surfaces are proven by
this static review. The existing native Case-write guard gate is not waived or implemented here.

## Assignment plan — not executed

assignments.plan.json names exactly:
```text
A 005aj00000guQE9AAM Contact=003aj00002Xl4IfAAJ
  ng.portal.a.00daj00001ae3iw.aadb68c436@northgate.demo
B 005aj00000guQEAAA2 Contact=003aj00002Xl4IgAAJ
  ng.portal.b.00daj00001ae3iw.aadb68c436@northgate.demo
```
Resolve the new PermissionSet ID only after separately approved deployment; no ID invented now.
Insert only missing (UserId, new PermissionSetId) pairs under separate assignment authorization,
retaining Foundation/profile and existing membership. No Batch B or Reviewer assignment to A/B.

## Local validation performed

Command output: python3 scripts/tests/validate_p8_dashboard_runtime_permission.py
```text
Ran 10 tests
OK
```
Selected raw local_validation.json:
```json
{"claim":"CONFIRMED","localTestsRun":10,"failures":0,"errors":0,"metadataComponents":1,"apexClassGrants":1,"fieldEditGrants":0,"nativeWriteGrants":0,"guardSourcesChanged":false,"orgWritesPerformed":0}
```
Checks cover exact manifest/class/object/FLS scope, field permissionability from live schema,
absence of extra capabilities, complete method inventory, deployed guard-source parity, all 55
prior deployed source hashes and exact non-executed A/B assignment plan. These are local static
metadata/source checks, not Apex execution or a proof of the new effective permission combination.

Command: sf project convert source --manifest manifest/p8-dashboard-runtime-permission.xml
--output-dir evidence/P8/PORTAL_PERMISSION_FIX/mdapi --json
```json
{"status":0,"result":{"location":"evidence/P8/PORTAL_PERMISSION_FIX/mdapi"}}
```
Conversion succeeded locally. conversion_verification.json checks its package contains exactly
the proposed PermissionSet and equivalent XML. It is not Salesforce schema/licence validation.

SKIPPED: no check-only deployment/dry-run against Salesforce (not authorized); no new actual-Plus
System.runAs tests with this new set; no A/B authenticated runtime/native-isolation/write test;
no deployment or assignment. Prior successful tests are historical coverage of unchanged guards
with previous fixture permissions, not a new permission-combination pass. Current tests create
Plus actors with Foundation+full Batch B; do not represent them as tests of this new set.

## Owner approvals needed before any org write

1. Approve the precise capability delta, including existing guarded booking and own-comment
   methods, and authorize scoped Salesforce validation/new-combination actual-license security
   tests. Include direct Case/Visit mutation denial and foreign Contact/Case/Vehicle/ledger/native
   read tests, not admin-only positives. Any fixture/write tests need their own explicit scope.
2. Approve deploying only manifest/p8-dashboard-runtime-permission.xml after validation. No Apex,
   LWC, profile, existing permission-set or sharing metadata deployment. Candidate deploy command:
   `sf project deploy start --target-org ng-demo --manifest manifest/p8-dashboard-runtime-permission.xml --wait 10 --json`
   NOT RUN. Reverify source hashes and org identity first; no speculative scope expansion.
3. Separately approve exactly the two assignments above, after effective permission/native-access
   checks; use an idempotent missing-pair operation. No membership or record share operation.
4. Verify A/B real-session dashboard zero/own states, vehicle DTOs and options, foreign-ID denial,
   no direct Vehicle access and no native Case/Visit writes. Do not book or create a Case merely to
   test read readiness. Scope any guarded write-UAT separately. No Phase 8/M4 acceptance implied.
