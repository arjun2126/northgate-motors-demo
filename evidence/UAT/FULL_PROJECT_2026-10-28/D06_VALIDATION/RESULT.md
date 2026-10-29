# D06 Loyalty permission validation — dry-run only, no deployment

## Authorization and target

Owner request: validate `PS_Owner_Portal_Dashboard_Runtime` via
`manifest/uat-d06-loyalty-read.xml`, no deployment, no assignment, no data/apex/LWC changes.
Org SELECT returned `00Daj00001Ae3iWEAR` (Developer Edition); API identity body confirms
`organization_id: 00Daj00001Ae3iWEAR`. No ng-dev access.

Pre-state captured in `git_status_before.txt`; candidate and manifest SHA256 in
`candidate_before.json`, re-checked after the dry-run (`verification.json`). No concurrent
Expansion/Harness file was edited or reverted.

## Exact permission-set diff

Live Metadata API retrieval (`live-set/`) is **identical** to the recorded local baseline
(`REGRESSION_CLOSURE/before/...`): zero field/object/class/other differences. Candidate vs live:

```json
"objectsAdded": {
  "Loyalty_Transaction__c": {
    "allowRead": "true", "allowCreate": "false", "allowEdit": "false",
    "allowDelete": "false", "viewAllRecords": "false", "modifyAllRecords": "false"
  }
}
"fieldsAdded": {
  "Loyalty_Transaction__c.Points__c": {"read": "true", "edit": "false"},
  "Loyalty_Transaction__c.Type__c":   {"read": "true", "edit": "false"}
}
"fieldsRemoved": {}, "objectsRemoved": {}, "fieldsChanged": {}, "objectsChanged": {},
"classesAdded": {}, "classesRemoved": {}, "otherChanged": {}
```

That is exactly the intended delta: transaction object Read, plus Read-only `Points__c` and
`Type__c`. All nine pre-existing field grants (Case/Service_Visit/Loyalty_Member), all three
pre-existing object grants, the `OwnerPortalBatchBController` class access, description,
`hasActivationRequired=false` and label are preserved byte-for-byte in semantics.

`Loyalty_Transaction__c.Transaction_Date__c` and `Loyalty_Member__c.Contact__c` report
`permissionable: false` in the live describe, so no speculative FLS is added for them. The
controller's `Id`/date selects therefore need no extra grant.

No Create, Edit, Delete, View All Records, Modify All Records, View All Fields, class/system,
sharing, role, group, licence or assignment entry is introduced.

## Controller review — record filtering and sharing

`force-app/main/default/classes/OwnerPortalBatchBController.cls`:

- Declared `public with sharing`, so record-level sharing applies to its SOQL.
- Aura entry `getLoyalty(beforeId)` takes no customer selector; it calls
  `OwnerPortalFoundationController.getContext().contactId`.
- `getContext()` derives identity from `UserInfo.getUserId()` / `User.ContactId`, requires
  `PowerCustomerSuccess`, the `Access_Northgate_Owner_Portal` custom permission, exactly one allowed
  site and an active user with a Contact and Account. No public entry point accepts a site or
  customer id.
- `loyalty()` calls `requireCaller(contactId)`, which re-checks user type, the custom permission and
  `actor.ContactId == contactId`; a mismatched or null contact throws the generic denial.
- Membership read is `WHERE Contact__c = :contactId ... WITH USER_MODE LIMIT 2`; more than one member
  is treated as ambiguous and denied.
- Transaction read is constrained twice:
  `WHERE Loyalty_Member__c IN :memberIds AND Loyalty_Member__r.Contact__c = :contactId WITH USER_MODE`.
  `beforeId` only pages within that already-filtered set.
- `WITH USER_MODE` enforces object and field permissions for the real community user; the
  `with sharing` class enforces record access. The candidate's Read grants are therefore a
  precondition for the query, not a bypass of either check.

## Isolation analysis — could this expose another customer's transactions?

Live facts (`verification.json`, `retrieve_objects.json`, `ab_*` receipts):

```json
"transactionSharingModel": "ControlledByParent",
"transactionParent": "Loyalty_Member__c (MasterDetail)",
"memberExternalOwd": "Private",
"memberShareRows": 0,
"sharingSetsRetrieved": 0,
"portalUsersHaveViewAllData": false,
"portalUsersHaveModifyAllData": false
```

- `Loyalty_Transaction__c` has no `OwnerId` and no share table; it is a master-detail child of
  `Loyalty_Member__c`, so its record access is exactly the parent member's access.
- `Loyalty_Member__c` is internal `ReadWrite` but **external `Private`**. No member share rows exist
  and no SharingSet metadata was retrieved. Members are owned by an internal admin, not portal users.
- Both portal users hold only `PS_Owner_Portal_Foundation` + profile `NG_Owner_Portal_User` +
  this runtime set. Their sets/profile grant no View All Data, Modify All Data, Manage Users or
  Author Apex.
- Customer A (`003aj00002Xl4IfAAJ`, Account `001aj000049ZoXNAA0`) and Customer B
  (`003aj00002Xl4IgAAJ`, Account `001aj000049ZoXOAA0`) are on **different Accounts**.
- Neither portal contact currently has a `Loyalty_Member__c` record (0 rows), so neither has any
  transaction to expose or display.

Conclusion: adding object Read on a ControlledByParent object does not itself grant any record.
Cross-customer exposure would require the caller to obtain access to another contact's member
record; the controller's contact-scoped filter would still exclude it, and direct record access is
currently blocked by external-Private member sharing plus no View All.

**Same-Account caveat:** because member visibility is Private and contact-scoped, two customers
under one Account would not share transactions through this controller. There is no live
same-Account portal pair to test, and any future Account-based sharing set/rule on
`Loyalty_Member__c` would change record-level exposure — that must be re-reviewed before it is
introduced.

## Scoped Salesforce validation

Executed once:

```sh
sf project deploy start --dry-run --target-org ng-demo --manifest manifest/uat-d06-loyalty-read.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw `validation.json`:
```json
"id": "0Afaj00000paNYbCAM",
"checkOnly": true,
"status": "Succeeded",
"success": true,
"numberComponentsTotal": 1,
"numberComponentsDeployed": 1,
"numberComponentErrors": 0,
"numberTestsCompleted": 0
```
Component result: `PermissionSet / PS_Owner_Portal_Dashboard_Runtime / success=true`.
`componentFailures: []`. No warnings. `NoTestRun` for a one-PermissionSet, non-Apex-delta package;
no Apex suite, coverage run or deployment.

Candidate and manifest hashes are unchanged after the dry-run (`candidateUnchanged: true`).

## Readiness and remaining checks

**Metadata is ready for a narrowly scoped deployment approval.** The diff is exactly the three
intended Read grants, live equals the reviewed baseline, and the dry-run succeeded with zero errors.

**Functional acceptance is not yet established, and the current data limits it:**

1. Deployment would immediately affect the two existing assignees (A and B); it should be explicitly
   approved as a permission effect, not as a silent fix.
2. Neither A nor B has a loyalty member, and member external OWD is Private. After deployment the
   loyalty query stops throwing (object/field access exists) but returns **empty** membership for
   them. The original "transactions visible" outcome cannot be demonstrated with current A/B data.
   A member-bearing contact (or an approved test-only fixture) is required for a positive test.
3. Remaining isolation checks: own-member positive read; foreign-contact transaction queried by
   direct record ID returns zero/denied; same-Account sibling-contact negative (no such live pair
   today); guest/unauthenticated denial; no write access through the object or the Apex facade.
4. No browser/session was available; no UI or native-API test was performed. Do not claim D06
   fixed or customer-visible until deployed and tested as the actual portal persona.

No deployment, assignment, permission/profile/sharing change, Salesforce data change, Apex/LWC or
Experience Builder change, test rerun, staging, commit or push was performed.

## Post-validation deployment — 2026-10-29

Separate owner authorization subsequently approved deployment of this exact unchanged candidate.
The source and manifest hashes still matched `0Afaj00000paNYbCAM`; deployment
`0Afaj00000pafVVCAY` succeeded 1/1 with zero errors. Postcheck confirmed exactly the three
authorized Read-only additions, all prior grants preserved, and the same two A/B assignments.
Guest access redirected to login. Authenticated A/B browser tests were SKIPPED because no sessions
were available; no member or transaction fixture was created, and D06 remains open for functional
and negative-security acceptance. Receipts and limits: `../D06_DEPLOYMENT/RESULT.md`.
