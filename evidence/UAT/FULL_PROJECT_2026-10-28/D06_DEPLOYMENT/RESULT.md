# D06 Loyalty permission correction — deployed; functional acceptance outstanding

## Authorization and scope

Owner-authorized deployment of the previously validated one-PermissionSet manifest to
`ng-demo` only. Target organization verified as `00Daj00001Ae3iWEAR`
(`orgfarm-25065ad46a-dev-ed.develop.my.salesforce.com`). No `ng-dev` access.

No Apex/LWC/Experience Builder change, permission assignment, business-data modification,
full regression rerun, dry-run repeat or Git operation was performed.

## Preflight — matched validated baseline

CONFIRMED — candidate and manifest hashes:

```text
PS_Owner_Portal_Dashboard_Runtime.permissionset-meta.xml
2258a1441310eb5d3bdfc8c6361e0a7e28a926424b7111d4968400e8df446b29

manifest/uat-d06-loyalty-read.xml
d12c800cc6096ccf40561c95243e53fc5f0760bbf100248ab548b8d9c4a47140
```

Both equal the successful validation `0Afaj00000paNYbCAM` baseline. The source manifest was
converted locally and contained exactly one `PermissionSet` component. Existing live state:
9 field grants, 3 object grants, one Apex class access, and exactly two assignments.

CONFIRMED — assignments before deployment:

```text
0Paaj000018ByQMCA0  005aj00000guQE9AAM  Customer A
0Paaj000018ByQNCA0  005aj00000guQEAAA2  Customer B
```

## Deployment

Executed once:

```sh
sf project deploy start --target-org ng-demo \
  --manifest manifest/uat-d06-loyalty-read.xml \
  --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw `deployment.json`:

```json
"id": "0Afaj00000pafVVCAY",
"checkOnly": false,
"status": "Succeeded",
"success": true,
"numberComponentsTotal": 1,
"numberComponentsDeployed": 1,
"numberComponentErrors": 0,
"numberTestsCompleted": 0
```

Component result: `PermissionSet / PS_Owner_Portal_Dashboard_Runtime / success=true`.
No component failures or warnings. No assignment operation.

## Post-deployment permission verification

CONFIRMED — exactly the authorized additions:

| Item | Read | Create/Edit/Delete | View All | Modify All |
|---|---:|---:|---:|---:|
| `Loyalty_Transaction__c` | true | false | false | false |
| `Loyalty_Transaction__c.Points__c` | true | Edit=false | — | — |
| `Loyalty_Transaction__c.Type__c` | true | Edit=false | — | — |

- Field grants: 9 before → 11 after; only `Points__c` and `Type__c` added, both
  `Read=true/Edit=false`.
- Object grants: 3 before → 4 after; only `Loyalty_Transaction__c` added, Read-only.
- No field or object grant removed or changed.
- Apex class access remains `OwnerPortalBatchBController` (`01paj00000c9U5pAAE`) only.
- Assignments remain exactly `0Paaj000018ByQMCA0` and `0Paaj000018ByQNCA0`; unchanged.

CONFIRMED — `postcheck.json` records `assignmentsUnchanged=true`,
`setupEntitiesUnchanged=true`, `unexpectedGrants=false`.

## Available read-only access verification

- Guest: opening `/owners/s/` redirected to
  `/owners/s/login/?ec=302&startURL=%2Fowners%2Fs%2F`, title `Login`. Snapshot contained only the
  login shell and no customer data. **PASS**.
- Customer A authenticated browser: **SKIPPED** — no authenticated A tab/session available.
- Customer B authenticated browser: **SKIPPED** — no authenticated B tab/session available.
- A/B loyalty membership after deployment: 0 rows (unchanged).
- A/B loyalty transactions via member contact: 0 rows.
- `Loyalty_Member__Share`: 0 rows.
- Actual A/B direct-record access and write denial: **NOT TESTED** without authenticated sessions
  or a separately approved test fixture. `UserRecordAccess` cannot be queried for another user
  through the CLI (`Can select only RecordId, a Has*Access field, and MaxAccessLevel`).

No metadata-level unexpected record access was introduced: the transaction object is
`ControlledByParent`, member external sharing remains Private with zero share rows, and the set
grants no View All/Modify All. This is a permission-model check, not an actual-persona record test.

## Remaining acceptance

D06 is **not fully closed**. Remaining security/functional tests:

1. A/B Rewards legitimate empty state after deployment.
2. Own-member positive read and transaction/tile rendering.
3. Foreign direct-ID denial (existing internal member `a05aj00000gECdzAAG` and its transactions).
4. Same-Account sibling-contact denial (no current same-Account portal pair).
5. Guest denial (guest redirect PASS; no customer data).
6. Pagination and `beforeId` substitution.
7. Create/edit/delete denial for member and transaction.
8. No native Case/Visit write expansion.

Positive browser/tile acceptance still requires a member-bearing contact or an approved test-only
fixture. No member or transaction was created or modified.

Overall project UAT remains **BLOCKED**. No full project, security or portal acceptance is claimed.
