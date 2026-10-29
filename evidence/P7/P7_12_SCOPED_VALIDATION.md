# P7-12 — authorized six-component check-only validation

Owner authorized only the existing `manifest/p7-12-territories.xml` check-only against ng-demo
`00Daj00001Ae3iWEAR`. Organization query confirmed that ID and Developer Edition. Local exact-scope
check passed before submission: six components, four siblings, explicit Account Read / Contact
None / Opportunity None / Case None, no rules/settings/memberships and twenty prior Batch 2
source hashes unchanged. No territory metadata or manifest was edited to obtain a passing result.

Command executed:

```sh
sf project deploy start --dry-run --target-org ng-demo --manifest manifest/p7-12-territories.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw command result excerpts:

```json
{
  "id":"0Afaj00000p7zkYCAQ",
  "status":"Succeeded",
  "success":true,
  "checkOnly":true,
  "completedDate":"2026-10-26T03:24:10.000Z",
  "numberComponentsDeployed":6,
  "numberComponentsTotal":6,
  "numberComponentErrors":0,
  "numberTestsCompleted":0,
  "numberTestsTotal":0,
  "numberTestErrors":0,
  "componentFailures":[],
  "warnings":[]
}
```

Selected raw CLI fields are preserved in `P7_12_SCOPED_VALIDATION.json`; private creator display
name/machine paths and unrelated result fields are omitted. The package.xml container success
is not a seventh metadata component.

CONFIRMED — raw component success projection:

```json
[
  {"componentType":"Territory2Type","fullName":"NG_Rooftop","success":true},
  {"componentType":"Territory2Model","fullName":"NG_Rooftops","success":true},
  {"componentType":"Territory2","fullName":"NG_Rooftops.Airport","success":true},
  {"componentType":"Territory2","fullName":"NG_Rooftops.Downtown","success":true},
  {"componentType":"Territory2","fullName":"NG_Rooftops.North","success":true},
  {"componentType":"Territory2","fullName":"NG_Rooftops.Service_Centre","success":true}
]
```

All six expected metadata members succeeded; no unrelated metadata component appears. All four
submitted territory files explicitly contain Contact None, Account Read, Opportunity None and
Case None. Salesforce accepted that input without errors under the existing settings. This
clears the metadata-value/structure validation gate; it does not prove persisted/effective access
or actual-persona sharing, which still need readback after an approved actual deployment.

NoTestRun is supported for this Developer Edition target and was accepted. Zero Apex methods ran;
the successful 235-test Batch 2 baseline was not repeated. No corrective edit or retry was needed.

Post-validation read-only queries:

```sql
SELECT Id, DeveloperName, State FROM Territory2Model WHERE DeveloperName = 'NG_Rooftops'
SELECT Id, DeveloperName FROM Territory2Type WHERE DeveloperName = 'NG_Rooftop'
SELECT Id, DeveloperName FROM Territory2 WHERE Territory2Model.DeveloperName = 'NG_Rooftops'
```

CONFIRMED — each query's raw result:

```json
{"records":[],"totalSize":0,"done":true}
```

The model/type/four territories therefore did not persist. Any component IDs in the check-only
response are not deployment/assignment IDs to reuse. No actual deployment, activation, Account
association, User assignment, sharing setting, other Salesforce data mutation, Git staging/
commit/push or ng-dev access occurred.

No validation blocker remains. Actual six-component deployment still needs separate approval,
followed by Planning-state/access readback; Account/User assignment and activation require
their own approvals. Existing identity/responsibility decisions remain open. Preserve five
unmapped Accounts. Batch 1 browser/gallery/event acceptance, operational access/page placement
and VIN credentials remain deferred; Batch 1 is not owner-accepted.
