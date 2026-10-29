# P6-15 — authorized deployment and blocked Draft import

**Historical pre-repair evidence.** The author-access blocker was subsequently resolved under
explicit authorization; ten Draft articles and ten category selections are now created and
verified. See `PHASE6_FINAL_BLOCKER_REPAIR_2026-10-25.md` and the import receipt/readback JSON.
Do not repeat the import or grant additional access based on the historical instructions below.

## Scope and result

Owner authorized scoped deployment of `manifest/p6-15-knowledge-prepare.xml` and creation of
exactly ten planned internal Draft articles plus ten category selections. Publication, permission
changes, assignments, page activation and other data changes remain prohibited.

Metadata deployment succeeded, three/three components. Import stopped at author-access preflight:
the new Body__c exists in metadata but is not exposed to the connected System Administrator
author, and FieldPermissions contains no grants for it. No POST, partial import, bodyless article,
permission change or SYSTEM_MODE workaround was attempted. Created: **zero articles, zero selections**.

## Target and exact metadata deployment

CONFIRMED — raw target query output:

```json
"Id": "00Daj00001Ae3iWEAR"
```

Commands:

```sh
sf project deploy start --target-org ng-demo --dry-run --manifest manifest/p6-15-knowledge-prepare.xml --test-level NoTestRun --wait 10 --json
sf project deploy start --target-org ng-demo --manifest manifest/p6-15-knowledge-prepare.xml --test-level NoTestRun --wait 10 --json
```

NoTestRun is appropriate for these three non-Apex metadata components; the successful Phase 6
Apex suites were not rerun. Source scope did not change between validation and deployment.

CONFIRMED — raw validation output excerpts:

```json
"id": "0Afaj00000p27o1CAA",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-25T00:59:04.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 3,
"numberComponentsTotal": 3,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"componentFailures": []
```

CONFIRMED — raw deployment output excerpts:

```json
"id": "0Afaj00000p27rFCAQ",
"status": "Succeeded",
"success": true,
"checkOnly": false,
"completedDate": "2026-10-25T00:59:27.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 3,
"numberComponentsTotal": 3,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"componentFailures": []
```

CONFIRMED — component results:

```json
[
  {"componentType":"CustomField","fullName":"Knowledge__kav.Body__c","created":true,"changed":true,"success":true},
  {"componentType":"Layout","fullName":"Knowledge__kav-NG Internal Article Layout","created":true,"changed":true,"success":true},
  {"componentType":"DataCategoryGroup","fullName":"Northgate_Knowledge","created":true,"changed":true,"success":true}
]
```

Read-only metadata retrieval `09Saj00000mhSNBEA2` confirms Body__c Html/32768/20 lines and the
active Northgate_Knowledge group with All root and Service/Buying/Financing/Ownership/Safety
children. Existing layout assignments and security were not changed.

## Duplicate checks and prepared payload

After deployment, three COUNT queries checked all ten prepared UrlName values in en_US,
separately for PublishStatus='Draft', 'Online' and 'Archived'. CONFIRMED — each raw output:

```json
"records": [],
"totalSize": 0,
"done": true
```

Command (local preparation only):

```sh
python3 scripts/knowledge/prepare_p6_15_import.py
```

CONFIRMED — request inspection output:

```json
{
  "payloadSha256": "63305e62d5cad1382bfdffcefbd1b4a78f5323d42e2f7e1ed72d0ab4fe33eae9",
  "allOrNone": true,
  "preparedCreates": {
    "Knowledge__kav": 10,
    "Knowledge__DataCategorySelection": 10
  },
  "submitted": false,
  "reason": "Body__c is not exposed to the connected author; permission changes are outside authorization."
}
```

This is a generated payload, not evidence of creation. There is no Composite response/import
ID and no new article/version/category-selection ID to report. Content/category/Draft/internal-
visibility readback cannot be claimed without successful creation.

## Exact blocking evidence

Both CLI sobject describe and a direct uncached REST describe omit Body__c:

```sh
sf api request rest "/services/data/v68.0/sobjects/Knowledge__kav/describe" --target-org ng-demo
```

CONFIRMED — filtered raw output:

```json
{"createable":true,"bodyField":[]}
```

Tooling query:

```sql
SELECT Id,DeveloperName,TableEnumOrId FROM CustomField WHERE DeveloperName = 'Body'
```

CONFIRMED — raw result field excerpts:

```json
"Id": "00Naj000068IkpWEAS",
"DeveloperName": "Body",
"TableEnumOrId": "01Iaj00000G1BeXEAV",
"totalSize": 1
```

FieldPermissions query:

```sql
SELECT Field,PermissionsRead,PermissionsEdit,Parent.IsOwnedByProfile,Parent.Profile.Name
FROM FieldPermissions
WHERE SobjectType = 'Knowledge__kav' AND Field = 'Knowledge__kav.Body__c'
```

CONFIRMED — raw result:

```json
"records": [],
"totalSize": 0,
"done": true
```

CONFIRMED — connected author profile/Knowledge User query excerpts:

```json
"Name": "System Administrator",
"UserPermissionsKnowledgeUser": true
```

This is a field-access blocker, not disabled Knowledge or a missing deployed field. Granting
field access changes security and is outside the authorization. Attempting the known-inaccessible
payload, omitting article bodies or bypassing FLS would not complete the approved requirement.

## Owner action needed

Approve the narrow author field-access correction, or perform it manually:
Setup > Object Manager > Knowledge > Fields & Relationships > Article Body > Set Field-Level
Security, granting the existing authorized author's profile Read/Edit for this field only.
Do not assign unrelated permission sets or change publication/customer/partner access.

After that separate decision, re-describe Body__c and repeat all three URL collision checks.
Then submit the existing reviewed ten-plus-ten all-or-none request once, verify every response,
and read back exact content, one category per version, Draft status, internal visibility true
and all three external flags false. Do not publish or attach articles to Cases without their
separate approvals. Any additional failure needs diagnosis before another write attempt.

## Preservation and closure

Only the three authorized metadata components were deployed. Existing articles and all business
records were preserved; no new Case/visit/loyalty/test records were created. No permission changes,
assignments, publication, scheduling, reconciliation, page activation, Git staging/commit/push
or ng-dev access occurred. Independent Phase 6 read-only review continued and is recorded in
`PHASE6_CLOSURE_REVIEW_2026-10-25.md`. P6-15 creation is blocked, not completed or accepted.
