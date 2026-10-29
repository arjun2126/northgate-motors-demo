# P7-12 — read-only verification after owner enabled Sales Territories

## Authorization and result

The owner reported enabling Sales Territories through Setup in ng-demo and authorized read-only
verification only. The verifier queried the Organization ID before further calls. No model/type/
territory creation, activation, Account/User assignment, metadata deployment or record/configuration
mutation was issued. No ng-dev access. Observation: `2026-10-26T01:24:13.114948+00:00`.

The earlier unavailable-capability gate is now cleared. P7-12 remains unimplemented and unaccepted:
feature enablement alone does not create the required four-territory tree or assignments.

Run: `python3 scripts/tests/verify_p7_12_territories.py`.
Raw output: `P7_12_TERRITORY_REVERIFICATION.json`. Earlier Batch 2 audit is retained as a historical
pre-enablement snapshot, not overwritten or rerun.

CONFIRMED — raw verifier excerpts:

```json
{
  "organization": [{"Id":"00Daj00001Ae3iWEAR","OrganizationType":"Developer Edition","IsSandbox":false}],
  "settingsRetrieve": {"id":"09Saj00000mlFcfEAE","status":"Succeeded"},
  "salesTerritoryEnabled": true,
  "allFourRequiredObjectsQueryable": true
}
```

The settings readback uses Metadata API retrieve, not deployment, into the evidence directory:

```sh
sf project retrieve start --metadata Settings:Territory2 --target-metadata-dir evidence/P7/P7_12_TERRITORY_SETTINGS_READBACK --unzip --wait 10 --target-org ng-demo --json
```

CONFIRMED — actual retrieved XML excerpts:

```xml
<defaultAccountAccessLevel>Read</defaultAccountAccessLevel>
<defaultCaseAccessLevel>None</defaultCaseAccessLevel>
<defaultContactAccessLevel>Edit</defaultContactAccessLevel>
<defaultOpportunityAccessLevel>None</defaultOpportunityAccessLevel>
<enableTerritoryManagement2>true</enableTerritoryManagement2>
```

Full settings are in
`P7_12_TERRITORY_SETTINGS_READBACK/unpackaged/unpackaged/settings/Territory2.settings`.
The nested opportunity filter has enableFilter=false, runOnCreate=false and no Apex class.
Nothing was retrieved into or changed under force-app.

## Object accessibility and existing configuration

Global describe exposes all four required objects. Each corresponding SOQL query succeeded in
the authenticated administrative context:

```sql
SELECT Id, DeveloperName, State FROM Territory2Model
SELECT Id, DeveloperName, Priority FROM Territory2Type
SELECT Id, DeveloperName, ParentTerritory2Id, Territory2ModelId, Territory2TypeId FROM Territory2
SELECT COUNT(Id) total FROM ObjectTerritory2Association
SELECT COUNT(Id) total FROM UserTerritory2Association
```

CONFIRMED — raw object-access projection:

```json
{
  "Territory2Model":{"exposed":true,"querySucceeded":true,"records":[]},
  "Territory2Type":{"exposed":true,"querySucceeded":true,"records":[]},
  "Territory2":{"exposed":true,"querySucceeded":true,"records":[]},
  "ObjectTerritory2Association":{"exposed":true,"querySucceeded":true,"records":[{"total":0}]}
}
```

CONFIRMED — raw UserTerritory2Association count:

```json
[{"total":0}]
```

There are no visible models, types or territories, including no active model; both association
inventories are empty. This is administrative API evidence, not operational-persona or tree UI
acceptance. No native assignment-rule implementation is inferred from an enabled feature.

## Existing rooftop/Account mapping candidate

Source Account.Preferred_Rooftop__c is an existing lookup to Rooftop__c. Live read-only grouping:

```sql
SELECT Id, Name FROM Rooftop__c ORDER BY Name
SELECT Preferred_Rooftop__c, COUNT(Id) total FROM Account GROUP BY Preferred_Rooftop__c
```

CONFIRMED — raw Account grouping:

```json
[
  {"Preferred_Rooftop__c":null,"total":5},
  {"Preferred_Rooftop__c":"a07aj00001MCKYvAAP","total":37},
  {"Preferred_Rooftop__c":"a07aj00001MCKYuAAP","total":38},
  {"Preferred_Rooftop__c":"a07aj00001MCKYtAAP","total":38},
  {"Preferred_Rooftop__c":"a07aj00001MCKYwAAP","total":37}
]
```

The live Rooftop rows resolve these buckets to Airport 37, North 38, Downtown 38 and Service
Centre 37. Thus 150 Accounts have a candidate rooftop mapping; five have no preferred rooftop.
This is not an approved Account selection or assignment instruction. Do not repair, infer or
assign the five unmapped Accounts. No personal Account/User names were collected.

## Requirements still to implement

Backlog P7-12 still requires four rooftop-aligned native territories, Account assignment and a
rendered tree. The consolidated plan additionally requires no unintended access widening.

1. Agree the exact native model/type names, type priority and four-territory hierarchy. Minimal
   candidate: one model, one shared type and four sibling territories for the existing rooftops;
   no extra umbrella Territory record is needed to represent the model root.
2. Approve explicit Account inclusion/exclusion rules. Preferred_Rooftop__c is the candidate
   anchor, not an automatic decision. Verify native rule-builder support for this lookup field
   before committing to automatic rules. If unsupported, seek an owner-approved manual mapping;
   do not add helper fields, Apex, Flows or geography inference without approval.
3. Agree territory access levels and intended existing users. Confirm license/permission
   eligibility and territory membership separately. Preserve separate Sales/Finance identities;
   do not infer assignments from shared role names or create/reclaim users.
4. After separate local metadata/check-only authorization, prepare the exact native type/model/
   territory/rule scope and validate it in isolation. No Territory settings or existing Batch 2
   trigger/Queueable scope should be silently added to that package.
5. Obtain separate approval before creating/deploying a Planning model/type/territories, applying
   assignment rules or assigning Accounts/Users. Planning metadata alone is not acceptance.
6. Obtain explicit activation/sharing approval, then verify the rendered four-territory tree,
   intended Account mappings and actual positive/negative persona access. Activation can initiate
   sharing recalculation. Capture `evidence/P7/territories.png` only from the actual native UI.

## Configuration dependencies and risks

- Retrieved defaults are Account Read, Contact Edit, Opportunity None and Case None. Contact Edit
  requires an explicit least-privilege decision before any user/Account assignment or activation.
  Territory sharing is additive; a lower territory setting does not remove access already granted
  through profiles, permission sets, ownership, roles or other sharing.
  These are record-sharing levels; object CRUD and field-level permissions still apply.
- Hierarchy/membership choices can widen access beyond one rooftop. Administrative query success
  does not prove intended persona access or cross-rooftop denial.
- No active model exists to reuse. Model creation, native criteria support, Account selection,
  membership, access settings and activation are distinct outstanding decisions/actions.
- Do not enable automatic Opportunity assignment or alter pricing, finance or CP2 behavior.
  The retrieved Opportunity filter is currently disabled; no change is proposed here.
- Five unmapped Accounts must remain untouched until the owner supplies a disposition. Native
  rules and future automatic alignment need an approved scope, not blanket assignment.

## Preserved Batch 2 and Batch 1 state

No Apex tests/check-only deployment were repeated. Existing Batch 2 success
`0Afaj00000p7GCLCA2` (235/235, ten replacement components plus four removals in check-only) remains
the historical code baseline, not validation of territory metadata that has not been built.
Its exact deployment scope remains unchanged and still requires separate approval.
P7-11 native/browser reader acceptance remains open. Phase 6 acceptance/exceptions are unchanged.
Batch 1 browser/gallery/event acceptance, operational access/page placement and VIN credentials
remain deferred; Batch 1 is not owner-accepted.
