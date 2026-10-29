# P7-12 — implementation design and local metadata receipt

**Subsequent status:** the six-component territory scope is now deployed under separate owner
authorization as `0Afaj00000p8GtRCAU`. Readback confirms Planning, four siblings/shared type,
Read/None/None/None persisted and zero Account/User associations. This design-time receipt remains
historical; current deployment evidence is `BATCH2_DEPLOYMENT.md` and handoff §43.

## Outcome

Prepared one native model, one shared type and four sibling territories locally. No actual
deployment, live model/type creation, activation, Account/User assignments, OWD/configuration
changes, Git staging/commit/push or ng-dev access. The six-component territory slice is separate
from the previously validated Batch 2 trigger/Queueable package.

Design and approval sequence: `docs/planning/P7_12_TERRITORY_DESIGN.md`.
Raw read-only inspection: `P7_12_DESIGN_INSPECTION.json`, observed
`2026-10-26T02:59:21.449623+00:00`.

## Native assignment/access findings

CONFIRMED — raw describe projection:

```json
{
  "ObjectTerritory2Association":{"createable":true,"updateable":false,"deletable":true,"queryable":true},
  "UserTerritory2Association":{"createable":true,"updateable":true,"deletable":true,"queryable":true}
}
```

ObjectTerritory2Association.AssociationCause includes native values Territory2Manual and
Territory2AssignmentRule; ObjectId and Territory2Id are createable. The field contract supports
the proposed one-time native manual Account associations, without a new engine or lookup rule.
No insertion was executed to validate planning-mode behavior. No Lead association is in scope.
Account.Preferred_Rooftop__c is a reference to Rooftop__c, not proven eligible for native rule
criteria. Eligibility remains unverified; no automatic rules or helper fields are prepared.

CONFIRMED — raw Territory2 picklist value excerpts:

```json
{"AccountAccessLevel":["Read","Edit","All"],"ContactAccessLevel":["None","Read","Edit"],"OpportunityAccessLevel":["None","Read","Edit"],"CaseAccessLevel":["None","Read","Edit"]}
```

Live EntityDefinition reports Private internal/external sharing for all four objects. Local
recommendation is Account Read, Contact None, Opportunity None, Case None. Existing native
Contact Edit default is not copied or changed. A six-component scoped server check-only must
resolve default/minimum/override behavior before deployment; failure must not be worked around
by silently granting Edit or changing settings. No effective-persona sharing claim is made.

## Existing users cannot be assigned by inference

Fourteen Staff records have User__c=null. All four Rooftop.General_Manager__c values are null.
The relevant operational roles exist, but active-user inspection and a separate query including
inactive matching role/profile users identify only the NG_Sales user with VP_Sales. The owner's
existing metrics-only VP boundary is preserved. Three active Salesforce users are administrators,
not substitute rooftop sales/service identities. No currently configured business-role user can
be recommended for Downtown, North, Airport or Service Centre membership.

CONFIRMED — raw relevant-role/profile query projection:

```json
{"Id":"005aj00000gE0b3AAC","IsActive":true,"Profile":{"Name":"NG_Sales"},"UserRole":{"DeveloperName":"VP_Sales"}}
```

CONFIRMED — raw live license row projection:

```json
{"Name":"Salesforce","TotalLicenses":4,"UsedLicenses":4}
```

Recommended User association delta is zero for all four territories until the owner supplies an
explicit existing-identity/responsibility decision. No admin reclamation, user creation, finance
role swap or license expansion is proposed. Persona acceptance remains a genuine dependency.

## Local validation

Commands executed:

```sh
python3 scripts/tests/check_p7_12_metadata.py
sf project convert source --manifest manifest/p7-12-territories.xml --output-dir evidence/P7/P7_12_METADATA_CONVERSION --json
```

The final local check also compares converted/source XML and exact package inventory.

CONFIRMED — raw final local check projection:

```json
{
  "status":"PASS",
  "localComponents":6,
  "model":"NG_Rooftops",
  "sharedType":"NG_Rooftop",
  "siblingTerritories":["Airport","Downtown","North","Service_Centre"],
  "explicitAccess":{"accountAccessLevel":"Read","contactAccessLevel":"None","opportunityAccessLevel":"None","caseAccessLevel":"None"},
  "assignmentRules":0,
  "userMemberships":0,
  "settingsComponents":0,
  "unchangedBatch2SourceFiles":20,
  "convertedComponentsChecked":6,
  "serverValidation":"NOT RUN: local-only preparation; default/override behavior requires scoped check-only approval",
  "apexTestsRerun":0
}
```

The native source converter returned status=0 and warnings=[]; output is under
`P7_12_METADATA_CONVERSION`. This validates source packaging, not server semantics. Local hashes
and results: `P7_12_LOCAL_METADATA_CHECK.json`. Native metadata shape/folder/member naming was
checked against the WSDL-derived schema and Salesforce source-deploy-retrieve territory fixtures:

- `https://github.com/jsforce/jsforce/blob/main/src/api/metadata/schema.ts`
- `https://github.com/forcedotcom/source-deploy-retrieve/blob/main/src/registry/metadataRegistry.json`
- `https://github.com/forcedotcom/source-deploy-retrieve/tree/main/test/snapshot/sampleProjects/territory/originalMdapi`

The first Python HTTPS reference fetch failed with CERTIFICATE_VERIFY_FAILED. Work stopped and
the owner approved system curl with normal certificate verification. That fetch succeeded; no
TLS bypass or certificate/configuration change was performed. Salesforce queries remained read-only.

## Exact approval boundary

1. Authorize the dedicated six-component check-only, not actual deployment. No Apex is included;
   no reason exists to repeat the successful 235 Apex tests.
2. After server/access validation and explicit approval, deploy only `manifest/p7-12-territories.xml`:
   type NG_Rooftop, model NG_Rooftops and four named territories. Verify Planning state and exact
   access settings. Model state is not invented as an unsupported metadata tag.
3. Separately approve a reviewed Account allowlist: at most the current 150 non-null mapped
   candidates (Downtown 38, North 38, Airport 37, Service Centre 37). Preserve five null-rooftop
   Accounts. Insert only owner-approved native manual associations; capture inserted IDs and
   stop on unexpected existing pairs/conflicts. Do not modify Account fields/owners or run rules.
4. Resolve/approve operational identity membership explicitly. No memberships are recommended
   yet. Then separately approve activation/sharing recalculation and actual native tree plus
   positive/negative access evidence with approved identities.

P7-07–P7-10 source and exact ten-replacement/four-removal manifest sets are unchanged. Existing
235/235 test success is reused, not rerun. CP2 and accepted Phase 1–6 behavior are untouched.
P7-12 is not server-validated, deployed or accepted. Batch 1 browser/gallery/event acceptance,
operational access/page placement and VIN credentials remain deferred; Batch 1 is not owner-accepted.
