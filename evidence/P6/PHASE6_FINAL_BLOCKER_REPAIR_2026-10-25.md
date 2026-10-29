# Phase 6 — final blocker repair

## Owner disposition: accepted with documented exceptions — October 24, 2026

The owner subsequently answered YES and formally accepted Phase 6. Decision and outstanding
exception index: `PHASE6_OWNER_ACCEPTANCE_2026-10-24.md`. Original execution timestamps below
are unchanged; acceptance does not turn deferred requirements into passed checks.

The three verified closure blockers are resolved in ng-demo `00Daj00001Ae3iWEAR`:
ten internal Draft articles and ten category selections exist and verify; repeat-purchase
report matches the source query at 31; managed nurture audit matches its source count at zero;
and loyalty liability is visible and matches the source at CAD 0.00 across 72 members.

Publication/search/Case attachment, actual Service/dual-role browser checks, deferred page/action
placement, live contention/timers, loyalty processing and schedules remain documented exceptions.
No new critical implementation defect was found in the approved repairs. Phase 7 feature
implementation remains unauthorized/unstarted; follow-on preparation is planning/read-only only.

## Authorization boundaries and separate report approval

Initial authorization permits the minimum Knowledge body access for the existing administrator,
the already-approved ten internal Draft articles/selections, local reporting fixes and scoped
check-only validation. It does not authorize report or other metadata deployment automatically.

The report package was held after successful validation. The owner then explicitly selected
**“Approve scoped deployment”** for the exact four components in
`manifest/p6-report-blocker-check.xml` and assignment of the six-field Read-only set only to
administrator `005aj00000feqbNAAQ`. Only then were those report changes deployed and access
assigned. No unrelated profiles/users/permission sets or record-sharing rules changed.

CONFIRMED — raw authenticated identity check:

```json
{"organization_id":"00Daj00001Ae3iWEAR","user_id":"005aj00000feqbNAAQ"}
```

## Exact changes

### Knowledge author access and records

- Added/deployed `PS_Knowledge_Draft_Author`: only Knowledge__kav.Body__c Read/Edit. No object
  CRUD, publication, external-channel, category-visibility, user administration or sharing grants.
- Assigned only to the existing connected administrator; no identity/profile modification.
- Used existing `scripts/knowledge/prepare_p6_15_import.py` unchanged to submit the reviewed
  all-or-none REST Composite request once: ten Knowledge__kav creates and ten category-selection
  creates, no updates/deletes/publication/Case attachments.
- Added a read-only live verification script and immutable response/readback evidence. Do not
  replay the import: the ten URL names now exist.

### Reports and minimum reporting access

- Added/deployed `PS_Phase6_Report_Field_Read`, with exactly six Read-only field grants:
  Quote.Repeat_Purchase_Open__c; Campaign.Consent_Purpose__c; Campaign.Consent_Channel__c;
  CampaignMember.Consent_Managed__c; CampaignMember.Nurture_Eligible__c;
  Loyalty_Member__c.Estimated_Liability_CAD__c.
- No object CRUD, View All/Modify All, audience-preview custom permission/class access, write,
  profile, identity or sharing grants. Assigned only to the same approved administrator, who is
  the existing fixed Loyalty dashboard running user and report verification context.
- Reasserted the existing desired report definitions from source in the exact scoped package:
  Repeat_Purchase_Contacts, Managed_Nurture_Membership_Audit, Tier_Mix_and_Liability. No unrelated
  reports/dashboards or formulas were rewritten. The deployment changed the two PostSale reports;
  Loyalty report definition was unchanged and its missing aggregate was resolved by field access.
- Repeat report retains Completed-service plus explicit Quote buyer and open Opportunity logic.
  Audit retains Consent_Managed__c=true, including suppressed historical managed memberships.
  It does not incorrectly require a currently active/managed Campaign or eligible-only members.

## Validation and deployment ledger

| Scope | Validation | Deployment | Components |
|---|---|---|---:|
| Knowledge Body-only permission set | 0Afaj00000p2Gg1CAE | 0Afaj00000p2EfqCAE | 1/1 |
| Exact report/access repair package | 0Afaj00000p2HtpCAE | 0Afaj00000p1htbCAA | 4/4 |

All four requests succeeded, zero component errors. NoTestRun was used because both packages
contain only permission/report metadata; no Apex implementation changed. The previously
successful 181-method coordinated suite and 34-method focused coverage run were not repeated.

Commands:

```sh
sf project deploy start --target-org ng-demo --dry-run --manifest manifest/p6-15-knowledge-author-access.xml --test-level NoTestRun --wait 10 --json
sf project deploy start --target-org ng-demo --manifest manifest/p6-15-knowledge-author-access.xml --test-level NoTestRun --wait 10 --json
sf org assign permset --target-org ng-demo --name PS_Knowledge_Draft_Author --json
sf project deploy start --target-org ng-demo --dry-run --manifest manifest/p6-report-blocker-check.xml --test-level NoTestRun --wait 10 --json
# Executed only after separate owner approval:
sf project deploy start --target-org ng-demo --manifest manifest/p6-report-blocker-check.xml --test-level NoTestRun --wait 10 --json
sf org assign permset --target-org ng-demo --name PS_Phase6_Report_Field_Read --json
```

CONFIRMED — raw deployment output excerpts:

```json
{"id":"0Afaj00000p2EfqCAE","status":"Succeeded","success":true,"checkOnly":false,"completedDate":"2026-10-25T01:39:52.000Z","numberComponentErrors":0,"numberComponentsDeployed":1,"numberComponentsTotal":1}
{"id":"0Afaj00000p1htbCAA","status":"Succeeded","success":true,"checkOnly":false,"completedDate":"2026-10-25T01:51:26.000Z","numberComponentErrors":0,"numberComponentsDeployed":4,"numberComponentsTotal":4}
```

CONFIRMED — report deployment component projection:

```json
[
  {"componentType":"Report","fullName":"NG_Loyalty_Operations/Tier_Mix_and_Liability","changed":false,"created":false,"success":true},
  {"componentType":"Report","fullName":"NG_PostSale/Managed_Nurture_Membership_Audit","changed":true,"created":false,"success":true},
  {"componentType":"Report","fullName":"NG_PostSale/Repeat_Purchase_Contacts","changed":true,"created":false,"success":true},
  {"componentType":"PermissionSet","fullName":"PS_Phase6_Report_Field_Read","changed":true,"created":true,"success":true}
]
```

## Knowledge import and readback

Before writing, direct REST describe exposed Body__c as createable/updateable with length 32768.
All ten prepared URLs had zero matches in en_US Draft, Online and Archived. The generated request
was the previously reviewed ten-plus-ten payload, with external-channel flags false and no
PublishStatus/IsVisibleInApp write or publication endpoint.

Command:

```sh
set -o pipefail && python3 scripts/knowledge/prepare_p6_15_import.py | sf api request rest "/services/data/v68.0/composite" --target-org ng-demo --method POST --header "Content-Type:application/json" --body -
```

All twenty subresponses returned HTTP 201, success=true and errors=[]. Raw response projection:
`P6_15_IMPORT_RECEIPT_2026-10-25.json`. Article version IDs are ka0aj000003F63NAAS through
ka0aj000003F63WAAS; selection IDs are 02oaj000002mp2HAAQ through 02oaj000002mp2QAAQ.
Exact IDs, rather than inferred ranges, are stored in the receipt. There is no asynchronous
import job ID because this was a synchronous Composite request.

Command:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 scripts/knowledge/verify_p6_15_import.py
```

CONFIRMED — raw verification output summary:

```json
"status": "PASS",
"verifiedArticles": 10,
"verifiedCategorySelections": 10,
"exactTitleSummaryLanguageMatches": 10,
"htmlContentMatches": 10,
"draftInternalOnly": 10,
"onlineOrArchivedMatchingVersions": 0
```

All ten have PublishStatus=Draft, Language=en_US, IsVisibleInApp=true, IsVisibleInPkb=false,
IsVisibleInCsp=false and IsVisibleInPrm=false. Each version has exactly one expected category in
Northgate_Knowledge; all version/selection IDs match the creation receipt. Full readback including
master IDs is in `P6_15_IMPORT_VERIFICATION_2026-10-25.json`. Category ParentId uses version Id;
CaseArticle integration, if approved later, must use the separately captured master ID.

One routine verifier correction was required: Salesforce stores apostrophe references as
`&#39;`, while Python html.escape produces `&#x27;`. The initial byte comparison failed on this
equivalent encoding. The verifier now compares decoded HTML while retaining full text/markup
and exact Title/Summary/Language comparisons. No record content was changed to make a check pass.

## Corrected report totals and effective filter evidence

Native report GETs use includeDetails=false. All report results returned allData=true, so these
totals are not truncated detail samples. Source comparisons were queried read-only under the
approved administrator's actual access, not an elevated workaround.

### Repeat purchase

CONFIRMED — native effective cross-filter excerpt and total:

```json
{"relatedEntity":"Service_Visit__c","relatedEntityJoinField":"Contact__c","criteria":[{"column":"Status__c","operator":"equals","value":"Completed"}]}
{"relatedEntity":"Quote","relatedEntityJoinField":"Buyer_Contact__c","criteria":[{"column":"Repeat_Purchase_Open__c","operator":"equals","value":"True"}]}
"totals": [{"label":"31","value":31}]
```

Reference query:

```sql
SELECT COUNT() FROM Contact
WHERE Id IN (SELECT Contact__c FROM Service_Visit__c WHERE Status__c = 'Completed')
AND Id IN (SELECT Buyer_Contact__c FROM Quote WHERE Opportunity.IsClosed = false)
```

CONFIRMED — raw query output: `"totalSize": 31`.
Report=31 and source=31, with no unexplained difference. The old 33 was not a legitimate cohort
difference; its required open-Opportunity condition was ineffective. No Contacts, Quotes,
Opportunities or visits were edited to force matching totals.

### Managed nurture audit

CONFIRMED — native effective filter and total:

```json
"reportFilters": [{"column":"CampaignMember_ContactOrLead.Consent_Managed__c","filterType":"fieldValue","isRunPageEditable":false,"operator":"equals","value":"True"}],
"totals": [{"label":"0","value":0}]
```

Reference query: `SELECT COUNT() FROM CampaignMember WHERE Consent_Managed__c = true`.
CONFIRMED — raw query output: `"totalSize": 0`.

The additional read-only grouping returned:

```json
{"Consent_Managed__c":false,"expr0":60}
```

All sixty existing memberships remain unmanaged; none was deleted, opted in or reclassified.
The corrected zero is expected. The former sixty-row unfiltered report was not managed-audience
evidence. This verifies filter correctness on the current population, not a new live revocation
scenario; existing consent/revocation/pagination tests remain the behavioral evidence.

### Loyalty liability

CONFIRMED — native aggregates:

```json
"aggregateColumns": ["s!Loyalty_Member__c.Points_Balance__c","s!Loyalty_Member__c.Estimated_Liability_CAD__c","RowCount"],
"totals": [{"label":"0","value":0},{"label":"$0.00","value":0},{"label":"72","value":72}]
```

Reference query:

```sql
SELECT COUNT(Id),SUM(Points_Balance__c),SUM(Estimated_Liability_CAD__c) FROM Loyalty_Member__c
```

CONFIRMED — raw aggregate: `{"expr0":72,"expr1":0,"expr2":0}`.
The visible CAD 0.00 liability matches both the stored formula aggregate and zero stored points
times configured CAD 0.01/point. It is not historical ledger reconciliation or activation.
Current program Is_Active__c remains false; no loyalty records or configuration were changed.

## Focused checks and security receipt

`python3 scripts/tests/check_p6_report_blockers.py` validates the exact six Read-only fields,
absence of object/audience/write grants, both repeat cross-filter conditions, managed-only audit
filter, liability Sum and four-component package boundary.

CONFIRMED — raw output:

```json
{"status":"PASS","readOnlyFieldGrants":6,"objectOrAudienceGrants":0,"reportDefinitions":3,"requiredFiltersAndLiabilitySum":true,"scopedMetadataMembers":4,"networkRequests":0}
```

Live FieldPermissions readback confirms exactly seven rows across the two new sets: Body__c
Read/Edit in the Knowledge set, six Read-only fields in the report set. Assignment readback:

```json
{"AssigneeId":"005aj00000feqbNAAQ","PermissionSet":{"Name":"PS_Knowledge_Draft_Author"}}
{"AssigneeId":"005aj00000feqbNAAQ","PermissionSet":{"Name":"PS_Phase6_Report_Field_Read"}}
"totalSize": 2
```

No other user received these grants. No profile, parent-object access, record sharing, audience
preview permission, finance/sales identity, approval or other Phase 1–6 runtime source changed.
No broad Apex suite rerun was justified: changes were non-Apex metadata and the twenty approved
records; relevant offline contracts and actual live import/report parity were checked instead.

## Remaining exceptions and owner disposition

No verified closure blocker remains from this repair scope. Remaining gates are intentionally
unexecuted: article publication/native Service search/Case attachment; operational persona and
dual-role browser screenshots; history/SLA page/action placement and related permission decisions;
live capacity contention, four-hour escalation/notification/history and SLA clock/breach evidence;
loyalty activation/jobs/redemption/expiry/reconciliation; nonempty CSI accuracy and dashboard
rendering/refresh. Zero managed memberships cannot exercise a positive live suppression example.

The existing historical loyalty discrepancy is preserved, not repaired. No additional test
records, business-data mutations, publication, external visibility expansion, page activation,
scheduling, destructive operations or Git staging/commit/push occurred. No ng-dev access or
Phase 7 implementation. The only explicit business-data writes were the ten Draft article creates
(with their native masters created automatically) and ten category selections; the only security
changes are the two explicitly authorized admin-only sets.

The owner has now explicitly accepted **WITH DOCUMENTED EXCEPTIONS**, dated October 24, 2026.
All operational/browser obligations above carry forward unchanged. Previous BLOCKED findings
remain historical evidence, superseded by the successful live repair/readback and owner decision.
