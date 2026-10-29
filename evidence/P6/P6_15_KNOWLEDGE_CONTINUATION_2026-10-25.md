# P6-15 — current Knowledge verification and local preparation

## Authorization

Owner confirmed Enable Lightning Knowledge in the browser and authorized focused read-only
verification plus preparation of remaining configuration/import/Case integration steps. No live
article creation, publication, permission changes or Git operations were authorized. Batch 4
implementation/tests were not repeated. No Salesforce deploy/check-only or data-write command
was run during this continuation.

## Target and feature state

Command: `sf data query --target-org ng-demo --query "SELECT Id FROM Organization" --json`.

CONFIRMED — raw target output:

```json
"Id": "00Daj00001Ae3iWEAR"
```

Read-only metadata retrieval:

```sh
sf project retrieve start --target-org ng-demo --metadata "Settings:Knowledge" --metadata "CustomObject:Knowledge__kav" --output-dir "retrieved/p6_15_knowledge_current" --json
```

CONFIRMED — raw retrieval output excerpts:

```json
"id": "09Saj00000mhMEYEA2",
"status": "Succeeded",
"success": true
```

CONFIRMED — retrieved current settings:

```xml
<defaultLanguage>en_US</defaultLanguage>
<enableKbStandardSharing>true</enableKbStandardSharing>
<enableKnowledge>true</enableKnowledge>
<enableKnowledgeCaseRL>false</enableKnowledgeCaseRL>
<enableLightningKnowledge>true</enableLightningKnowledge>
```

REFUTED — Knowledge remains disabled now. The current true values supersede the historical
false result in Batch 4 evidence. No additional feature enablement is needed or was attempted.

## Available objects and current fields

EntityDefinition query:

```sql
SELECT QualifiedApiName FROM EntityDefinition
WHERE QualifiedApiName IN ('Knowledge__kav','KnowledgeArticle','KnowledgeArticleVersion',
                          'Knowledge__DataCategorySelection','CaseArticle')
```

CONFIRMED — raw result field excerpts:

```json
"QualifiedApiName": "CaseArticle"
"QualifiedApiName": "KnowledgeArticle"
"QualifiedApiName": "KnowledgeArticleVersion"
"QualifiedApiName": "Knowledge__DataCategorySelection"
"QualifiedApiName": "Knowledge__kav"
"totalSize": 5
```

Commands: `sf sobject describe --target-org ng-demo --sobject Knowledge__kav --json`, and
equivalent describes for Knowledge__DataCategorySelection and CaseArticle.

CONFIRMED — selected schema output for the connected user:

```json
{"name":"Knowledge__kav","createable":true,"updateable":true,"queryable":true}
{"name":"Title","length":255,"createable":true}
{"name":"UrlName","length":255,"createable":true}
{"name":"Summary","length":1000,"createable":true}
{"name":"Language","createable":true,"updateable":false}
{"name":"PublishStatus","createable":false,"updateable":false,"defaultValue":"Draft","defaultedOnCreate":true}
{"name":"IsVisibleInApp","createable":false,"updateable":false,"defaultValue":null,"defaultedOnCreate":true}
{"name":"IsVisibleInPkb","createable":true,"updateable":true}
{"name":"IsVisibleInCsp","createable":true,"updateable":true}
{"name":"IsVisibleInPrm","createable":true,"updateable":true}
```

Do not write PublishStatus or IsVisibleInApp. Describe does not establish the actual internal
visibility value of a newly created record; verify it after a future separately authorized import.

CONFIRMED — FieldDefinition projection for Knowledge__kav:

```json
{"status":0,"customFields":[],"fieldCount":42,"message":null}
```

There is no existing custom body field to reuse. Creating a new Body__c is staged configuration,
not a claim that a current field exists.

CONFIRMED — category-selection schema excerpts:

```json
{"name":"Knowledge__DataCategorySelection","createable":true}
{"name":"ParentId","createable":true,"referenceTo":["Knowledge__kav"]}
{"name":"DataCategoryGroupName","createable":true}
{"name":"DataCategoryName","createable":true}
"relationshipName": "DataCategorySelections"
```

CONFIRMED — CaseArticle schema excerpts:

```json
{"name":"CaseArticle","createable":true}
{"name":"CaseId","createable":true,"referenceTo":["Case"]}
{"name":"KnowledgeArticleId","createable":true,"referenceTo":["Knowledge__ka"]}
{"name":"ArticleLanguage","createable":true}
{"name":"ArticleVersionNumber","createable":true}
```

Category ParentId requires the article **version** Id; CaseArticle requires the **master**
KnowledgeArticleId. No Case IDs or customer data were collected or embedded into import artifacts.
Connected-user CRUD is not evidence of actual Service persona access.

## Categories, layout and URL collision preflight

CONFIRMED — raw DataCategoryGroup metadata list result:

```json
"result": []
```

The current Knowledge Layout was retrieved as `09Saj00000mhQlBEAU` and contains only Title and
UrlName. No existing layout is overwritten by the local proposal.

Three read-only COUNT queries checked all ten prepared en_US UrlName values separately for
PublishStatus='Draft', 'Online' and 'Archived'. CONFIRMED — each raw result:

```json
"records": [],
"totalSize": 0,
"done": true
```

These are point-in-time no-collision checks, not an authorization or guarantee for a later
import. Repeat immediately before any approved creation. Existing matches must stop import.

A readiness query attempted to group UserPermissionsKnowledgeUser; Salesforce rejected that
non-groupable field (`field 'UserPermissionsKnowledgeUser' can not be grouped in a query call`).
The corrected non-aggregate read returned zero active NG_Service-profile users. No identity,
profile or Knowledge User flag was modified. Persona readiness remains separate acceptance,
not another Knowledge feature blocker or evidence that an existing user should be repurposed.

## Local configuration and import artifacts

Prepared only, not deployed or org-validated:

- `force-app/main/default/objects/Knowledge__kav/fields/Body__c.field-meta.xml` — Html, length
  32768, 20 visible lines; no FLS grants.
- `force-app/main/default/datacategorygroups/Northgate_Knowledge.datacategorygroup-meta.xml` —
  native KnowledgeArticleVersion usage; All root and Service/Buying/Financing/Ownership/Safety
  children; no category visibility grants.
- `force-app/main/default/layouts/Knowledge__kav-NG Internal Article Layout.layout-meta.xml` —
  new unassigned layout; Title, UrlName, Summary and Body__c.
- `manifest/p6-15-knowledge-prepare.xml` — exactly those three components; no Settings, Profile,
  PermissionSet, app/page assignment or existing layout replacement.
- `scripts/knowledge/prepare_p6_15_import.py` — local-only request builder reading the existing
  ten drafts. It prints ten article creates plus ten category-selection creates, allOrNone=true;
  escapes body HTML, omits non-createable fields, and sets all three external visibility flags
  false. No network, file writes, publication, Case attachment or Salesforce execution code.
- `scripts/tests/check_p6_15_preparation.py` — offline payload/metadata checks, including duplicate
  URL rejection, HTML escaping, reference integrity and no publication/external exposure requests.
- `docs/knowledge/README.md` — exact schema-backed mapping, collision/readback checks, separate
  approval boundaries and native Case integration steps.

No prepared REST request was submitted. Composite runtime compatibility/defaults/rollback have
not been smoke-tested against Knowledge because live creation is not authorized.

## Focused offline validation

Command:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 scripts/tests/check_p6_15_preparation.py
```

CONFIRMED — raw output:

```json
{
  "status": "PASS",
  "articleCreatesPrepared": 10,
  "categorySelectionsPrepared": 10,
  "metadataMembers": 3,
  "allOrNone": true,
  "externalVisibility": false,
  "publicationRequests": 0,
  "networkRequests": 0
}
```

`xmllint --noout` passed on all three new metadata files and the preparation manifest.
Batch 4 tests and deployment were not repeated. No Git operations were run.

## Remaining work and preservation

The disabled-feature blocker is resolved. No new architectural blocker was found. Remaining
work requires the corresponding separate approvals: validate/deploy exactly the three proposed
metadata components; verify author/reader access and license readiness; create ten Drafts plus
ten category selections; review/publish; configure native Case UI and attach approved published
articles to approved Cases. Detailed steps are in `docs/knowledge/README.md`.

Knowledge Case related-list presentation is currently disabled. Do not assume object availability
activates the Case UI; any approved settings change must preserve the fresh settings baseline.
No existing Salesforce setting, article, user, permission, Case link, app or page was changed.
Earlier functionality and dirty work are preserved. No ng-dev access, live article creation,
publication, data/permission changes, scheduling or Git operations. Phase 6 remains unaccepted;
article search, Case integration and persona/browser acceptance remain pending.
