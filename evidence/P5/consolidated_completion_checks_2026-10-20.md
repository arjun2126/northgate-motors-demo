# Phase 5 consolidated completion checks — 2026-10-20

Scope: read-only requests to `ng-demo`, source/evidence inspection, and local planning files.
JSON below contains raw command-response excerpts or selected raw response fields. No dashboard
refresh, deployment, test execution, Salesforce DML, permission change, bypass, or reset ran.
Observations were captured after the scoped release, approximately 23:48–23:56 UTC.

## CONFIRMED — existing deployments, not new deployments

Commands: `sf project deploy report --target-org ng-demo --job-id <id> --json`.

```json
{"id":"0Afaj00000oTmEACA0","checkOnly":false,"status":"Succeeded","success":true,"numberComponentsDeployed":6,"numberComponentsTotal":6,"numberComponentErrors":0,"numberTestsCompleted":173,"numberTestErrors":0}
{"id":"0Afaj00000oUgbJCAS","checkOnly":false,"status":"Succeeded","success":true,"numberComponentsDeployed":1,"numberComponentsTotal":1,"numberComponentErrors":0,"numberTestsCompleted":173,"numberTestErrors":0}
```

## CONFIRMED — live report filters and results

Command for each ID: `sf api request rest /services/data/v68.0/analytics/reports/<id> --method GET --target-org ng-demo --json`.
Selected raw response fields; all ten responses had HTTP 200 and `allData: true`.

```json
{"id":"00Oaj00000UjuL0EAJ","allData":true,"reportFilters":[{"column":"LAST_UPDATE","filterType":"fieldValue","isRunPageEditable":true,"operator":"lessThan","value":"LAST 14 DAYS"},{"column":"STATUS","filterType":"fieldValue","isRunPageEditable":true,"operator":"notEqual","value":"Closed"}],"standardDateFilter":{"column":"CREATED_DATEONLY","durationValue":"CUSTOM","endDate":null,"startDate":null},"scope":"organization","aggregates":[{"label":"3","value":3}],"reportType":{"label":"Cases","type":"CaseList"}}
{"id":"00Oaj00000UpWB4EAN","allData":true,"reportFilters":[{"column":"Case.Days_Since_Last_Update__c","filterType":"fieldValue","isRunPageEditable":true,"operator":"greaterThan","value":"14"},{"column":"STATUS","filterType":"fieldValue","isRunPageEditable":true,"operator":"notEqual","value":"Closed"}],"aggregates":[{"label":"11","value":11}]}
{"id":"00Oaj00000UjuL5EAJ","allData":true,"reportFilters":[{"column":"STAGE_NAME","filterType":"fieldValue","isRunPageEditable":true,"operator":"equals","value":"Quoting"},{"column":"Opportunity.Days_In_Stage__c","filterType":"fieldValue","isRunPageEditable":true,"operator":"greaterThan","value":"45.0"}],"standardDateFilter":{"column":"CLOSE_DATE","durationValue":"THIS_FISCAL_QUARTER","endDate":"2026-12-31","startDate":"2026-10-01"},"aggregates":[{"label":"0","value":0}]}
{"id":"00Oaj00000UpWB5EAN","allData":true,"reportFilters":[{"column":"Contact.Seed_Tag__c","filterType":"fieldValue","isRunPageEditable":true,"operator":"equals","value":"SEED-07-001,SEED-07-002,SEED-07-003,SEED-07-004,SEED-07-005,SEED-07-006"}],"aggregates":[{"label":"6","value":6}]}
{"id":"00Oaj00000UjuKvEAJ","aggregates":[{"label":"120","value":120}]}
{"id":"00Oaj00000UjuKwEAJ","reportFilters":[{"column":"Service_Visit__c.Scheduled_Start__c","filterType":"fieldValue","isRunPageEditable":true,"operator":"lessThan","value":"TODAY"},{"column":"Service_Visit__c.Status__c","filterType":"fieldValue","isRunPageEditable":true,"operator":"equals","value":"Scheduled"}],"aggregates":[{"label":"13","value":13}]}
{"id":"00Oaj00000UoEmTEAV","aggregates":[{"label":"0","value":0},{"label":"0","value":0}]}
{"id":"00Oaj00000UjuL6EAJ","reportFilters":[],"standardDateFilter":{"column":"Loyalty_Member__c.Join_Date__c","durationValue":"CUSTOM","endDate":null,"startDate":null},"aggregates":[{"label":"0","value":0},{"label":"0","value":0},{"label":"72","value":72}]}
{"id":"00Oaj00000UhWmZEAV","reportFilters":[{"column":"STAGE_NAME","filterType":"fieldValue","isRunPageEditable":true,"operator":"notEqual","value":"Closed Lost"}],"aggregates":[{"label":"$10,587,766.00","value":10587766},{"label":"113","value":113}]}
{"id":"00Oaj00000UhWmYEAV","aggregates":[{"label":"$6,250,407.00","value":6250407}]}
```

The final report's displayed aggregate is Amount. Its dashboard component requests `RowCount`;
the value 6,250,407 must not be used as an Opportunity count.

## REFUTED — six updated Opportunities imply a six-row report

Commands: `sf data query --target-org ng-demo --query "SELECT COUNT(Id) n FROM Opportunity WHERE StageName='Quoting' AND Days_In_Stage__c>45" --json`, and the six-ID detail query.

```json
{"n":6}
```

Detail-query raw fields, in `SEED-09-044` through `SEED-09-049` order:

```json
{"Id":"006aj00000fUItQAAW","Seed_Tag__c":"SEED-09-044","StageName":"Quoting","CloseDate":"2026-08-10","Stage_Last_Changed__c":"2026-08-01T00:00:00.000+0000","Days_In_Stage__c":81}
{"Id":"006aj00000fUItRAAW","Seed_Tag__c":"SEED-09-045","StageName":"Quoting","CloseDate":"2026-08-16","Stage_Last_Changed__c":"2026-08-01T00:00:00.000+0000","Days_In_Stage__c":81}
{"Id":"006aj00000fUItSAAW","Seed_Tag__c":"SEED-09-046","StageName":"Quoting","CloseDate":"2026-09-21","Stage_Last_Changed__c":"2026-08-01T00:00:00.000+0000","Days_In_Stage__c":81}
{"Id":"006aj00000fUItTAAW","Seed_Tag__c":"SEED-09-047","StageName":"Quoting","CloseDate":"2026-08-28","Stage_Last_Changed__c":"2026-08-01T00:00:00.000+0000","Days_In_Stage__c":81}
{"Id":"006aj00000fUItUAAW","Seed_Tag__c":"SEED-09-048","StageName":"Quoting","CloseDate":"2026-09-11","Stage_Last_Changed__c":"2026-08-01T00:00:00.000+0000","Days_In_Stage__c":81}
{"Id":"006aj00000fUItVAAW","Seed_Tag__c":"SEED-09-049","StageName":"Quoting","CloseDate":"2026-07-29","Stage_Last_Changed__c":"2026-08-01T00:00:00.000+0000","Days_In_Stage__c":81}
```

## CONFIRMED — Service SLA clock boundary

Command: `sf data query --target-org ng-demo --query "SELECT Id, Seed_Tag__c, Status__c, Scheduled_Start__c FROM Service_Visit__c WHERE Status__c='Scheduled' AND Scheduled_Start__c < TODAY ORDER BY Scheduled_Start__c" --json`.

Raw final record and response count:

```json
{"Id":"a08aj00001Snsk0AAB","Seed_Tag__c":"SEED-18-040","Status__c":"Scheduled","Scheduled_Start__c":"2026-10-19T00:00:00.000+0000"}
{"totalSize":13,"done":true}
```

## CONFIRMED — bounded finding and ledger queries

Each query used `sf data query --target-org ng-demo --query <SOQL> --json`.

```sql
SELECT COUNT(Id) n FROM Lead WHERE Seed_Tag__c LIKE 'SEED-%' AND IsConverted=false AND (LastActivityDate < LAST_N_DAYS:60 OR (LastActivityDate=null AND CreatedDate < LAST_N_DAYS:60))
```
```json
{"n":0}
```
```sql
SELECT COUNT(Id) n FROM Vehicle__c WHERE Inventory_Age_Days__c > 120
```
```json
{"n":120}
```
```sql
SELECT COUNT(Id) n FROM Trade_In__c WHERE Seed_Tag__c LIKE 'SEED-%' AND Trade_Equity__c < 0
```
```json
{"n":8}
```
```sql
SELECT COUNT(Id) n FROM Quote WHERE Seed_Tag__c LIKE 'SEED-%' AND Rule_Applied_Count__c > 1
```
```json
{"n":0}
```
```sql
SELECT COUNT(Id) n FROM Test_Drive__c WHERE Seed_Tag__c LIKE 'SEED-%' AND Status__c='No_Show'
```
```json
{"n":12}
```
This last result is not a no-follow-up count; Task correlation remains unverified.

Both `SELECT COUNT(Id) n FROM Contact WHERE Seed_Tag__c LIKE 'SEED-98-%'` and the equivalent `Trade_In__c` query returned:

```json
{"n":0}
```

```sql
SELECT Object__c, Status__c, COUNT(Id) n, SUM(Inserted_Count__c) inserted, SUM(Failed_Count__c) failed FROM Data_Load_Batch__c GROUP BY Object__c, Status__c
```
```json
{"Object__c":"Mixed","Status__c":"Loaded","n":20,"inserted":0,"failed":0}
```

```sql
SELECT Tier__c, COUNT(Id) n, SUM(Points_Balance__c) balance FROM Loyalty_Member__c WHERE Seed_Tag__c LIKE 'SEED-21-%' GROUP BY Tier__c
```
```json
{"Tier__c":"Gold","n":9,"balance":0}
{"Tier__c":"Silver","n":18,"balance":0}
{"Tier__c":"Bronze","n":39,"balance":0}
{"Tier__c":"Platinum","n":4,"balance":0}
```

An earlier exploratory `SEED-19-%` loyalty selector returned zero; it was the wrong tag range,
not missing loyalty data. The existing resolved CSV and live tags establish `SEED-21-%`.

## CONFIRMED — management and admin access baseline

Queries: User by persona ID; all PermissionSetAssignment rows for persona/admin; GroupMember
rows for persona or the management group; ObjectPermissions for the persona's two existing
sets plus `PS_Management_Reports`; Automation_Settings__c.

Selected raw fields:

```json
{"Id":"005aj00000gE0b3AAC","UserRoleId":"00Eaj00000QCxlLEAT","UserRole":{"DeveloperName":"VP_Sales"},"Profile":{"Name":"NG_Sales"},"ManagerId":null}
{"Id":"0Paaj000016Ty3HCAS","AssigneeId":"005aj00000gE0b3AAC","PermissionSetId":"0PSaj00000gE0RPGA0"}
{"Id":"0Paaj000016dBqzCAE","AssigneeId":"005aj00000gE0b3AAC","PermissionSetId":"0PSaj00000gKc49GAC"}
{"Id":"011aj000006D0ErAAK","GroupId":"00Gaj00000ZYYhUEAX","Group":{"DeveloperName":"PG_All_Sales"},"UserOrGroupId":"005aj00000gE0b3AAC"}
{"Id":"0Paaj000016wctoCAA","AssigneeId":"005aj00000feqbNAAQ","PermissionSetId":"0PSaj00000gV45ZGAS","PermissionSet":{"Name":"PS_Case_Data_Quality_Fields"}}
{"ParentId":"0PSaj00000gE0RPGA0","SobjectType":"Account","PermissionsRead":true,"PermissionsViewAllRecords":false,"PermissionsModifyAllRecords":false}
{"ParentId":"0PSaj00000gE0RPGA0","SobjectType":"Contact","PermissionsRead":true,"PermissionsViewAllRecords":false,"PermissionsModifyAllRecords":false}
{"ParentId":"0PSaj00000gE0RPGA0","SobjectType":"Opportunity","PermissionsRead":true,"PermissionsViewAllRecords":false,"PermissionsModifyAllRecords":false}
{"Id":"a00aj00003oHxQMAA0","SetupOwnerId":"00Daj00001Ae3iWEAR","Bypass_Triggers__c":false,"Bypass_Flows__c":false,"Bypass_Validation__c":false}
```

The object-permission query requested Account, Contact, Opportunity, Staff, Vehicle, Service
Visit, Loyalty Member, Financing and Case. Only the three object rows above were returned.
The assignment/group queries returned no persona management grant or management-group member.

## CONFIRMED — live dashboard types

Command: GET `/services/data/v68.0/analytics/dashboards/<id>` using the same read-only CLI.
Raw metadata fields:

```json
{"id":"01Zaj00000BVDInEAP","developerName":"DM_Finance_Operations","dashboardType":"SpecifiedUser","runningUser":{"id":"005aj00000feqbNAAQ"}}
{"id":"01Zaj00000BVDIoEAP","developerName":"DM_Sales_Operations","dashboardType":"SpecifiedUser","runningUser":{"id":"005aj00000feqbNAAQ"}}
{"id":"01Zaj00000BVDIpEAP","developerName":"DM_Service_OperationsFixed","dashboardType":"SpecifiedUser","runningUser":{"id":"005aj00000feqbNAAQ"}}
{"id":"01Zaj00000BVDIqEAP","developerName":"DM_Exec_OperationsOverview","dashboardType":"LoggedInUser"}
```

These admin GETs do not establish persona rendering or a current browser refresh.

## CONFIRMED — Northgate Persona record access: ownership-dependent, not empty

Command: probe one record per object with `sf data query`, then
`SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE UserId='005aj00000gE0b3AAC' AND RecordId IN (<probe ids>) --json`.

**This supersedes the earlier "no record-level access" conclusion in this file, which probed
only admin-owned records.**

```text
Opportunity SEED-09-001 (persona-owned)  read=True  edit=True
Opportunity SEED-09-044 (persona-owned)  read=True  edit=True
Opportunity 006aj00000eebhlAAA (admin)   read=False edit=False
Account 001aj000045ZScRAAW (admin-owned) read=True
Contact 003aj00002W3EfhAAF (admin-owned) read=False
Vehicle__c a0Daj00001D2FPZEA3            read=False
Loyalty_Member__c a05aj00000gECdpAAG     read=False
Quote 0Q0aj000003jGGbCAM (admin-owned)   read=False
Case 500aj00003icWCHAA2 (admin-owned)    read=False
```

Ownership census (`OwnerId = 005aj00000gE0b3AAC`):

```text
Opportunity 101   (100 canonical SEED-09-* + 1 UAT)
Task 200          Event 50
Account 1         Contact 1        Quote 1
Lead 0   Vehicle__c 0   Service_Visit__c 0   Loyalty_Member__c 0   Financing__c 0
Staff__c 0   Case 0   Trade_In__c 0   Delivery__c 0   Test_Drive__c 0
```

Canonical seed ownership: Opportunity 100/100 persona; Vehicle__c 120 admin;
Service_Visit__c 140 admin; Loyalty_Member__c 70 admin; Financing__c 60 admin; Case 60 admin;
Quote 60 admin; Account 150 admin; Contact 185 admin; Trade_In__c 45 admin.

Account read for the persona comes from 104 `AccountShare` rows, `RowCause=ImplicitParent`:

```json
{"Id":"00raj00000JXCVhAAP","AccountId":"001aj000045ZScRAAW","RowCause":"ImplicitParent"}
```

Persona object-level Read (profile-owned set `0PSaj00000gE0RPGA0`): Account, Contact, Lead,
Opportunity, ContractLineItem, Entitlement, EntitlementContact, QuickText, ServiceContract.
`NG_Lightning_Experience_Access` (`0PSaj00000gKc49GAC`) returns no object rows.

Persona-scoped pipeline values versus admin context:

```json
{"label":"admin not Closed Lost","n":113,"amt":10587766}
{"label":"persona not Closed Lost","n":78,"amt":4328120}
{"label":"admin open","n":82,"amt":6250407}
{"label":"persona open","n":66,"amt":3635761}
```

Persona pipeline by stage (Stage != Closed Lost):

```json
{"StageName":"Prospecting","cnt":11,"amt":598747}
{"StageName":"Qualification","cnt":12,"amt":693703}
{"StageName":"Test_Drive","cnt":12,"amt":656712}
{"StageName":"Appraisal","cnt":9,"amt":492915}
{"StageName":"Quoting","cnt":11,"amt":612706}
{"StageName":"Financing","cnt":11,"amt":580978}
{"StageName":"Closed Won","cnt":12,"amt":692359}
```

```sql
SELECT COUNT(Id) cnt FROM Opportunity WHERE Seed_Tag__c LIKE 'SEED-%' AND Sales_Staff__c=null
```
```json
{"cnt":100}
```
```sql
SELECT COUNT(Id) cnt FROM Opportunity WHERE Seed_Tag__c LIKE 'SEED-%' AND Sales_Staff__c!=null
```
```json
{"cnt":0}
```

## REFUTED — the Open_Opps_by_Sales_Staff filter excludes null Sales_Staff__c

The report filter is `Opportunity.Sales_Staff__c notEqual 'Blank'`, yet the live admin report
returned Amount 6,250,407, identical to the sum of **all** 82 open Opportunities, while all
100 canonical Opportunities have `Sales_Staff__c = null`. The filter therefore does not
exclude null values, and the "Open Opportunities by Sales Staff" tile is not a distinct staff
metric. Record as an open P5-15 acceptance risk. No fix applied.

## CONFIRMED — candidate BAD-01 parent identities

Command: `sf data query --target-org ng-demo --query "SELECT Id, Seed_Tag__c FROM Account WHERE Seed_Tag__c IN ('SEED-06-007','SEED-06-008','SEED-06-009','SEED-06-010','SEED-06-011','SEED-06-012','SEED-06-013','SEED-06-014','SEED-06-015','SEED-06-016','SEED-06-017','SEED-06-018','SEED-06-019','SEED-06-020','SEED-06-021','SEED-06-022') ORDER BY Seed_Tag__c" --json`.

Selected raw fields from all 16 returned records:

```json
{"Id":"001aj000045ZScXAAW","Seed_Tag__c":"SEED-06-007"}
{"Id":"001aj000045ZScYAAW","Seed_Tag__c":"SEED-06-008"}
{"Id":"001aj000045ZScZAAW","Seed_Tag__c":"SEED-06-009"}
{"Id":"001aj000045ZScaAAG","Seed_Tag__c":"SEED-06-010"}
{"Id":"001aj000045ZScbAAG","Seed_Tag__c":"SEED-06-011"}
{"Id":"001aj000045ZSccAAG","Seed_Tag__c":"SEED-06-012"}
{"Id":"001aj000045ZScdAAG","Seed_Tag__c":"SEED-06-013"}
{"Id":"001aj000045ZSceAAG","Seed_Tag__c":"SEED-06-014"}
{"Id":"001aj000045ZScfAAG","Seed_Tag__c":"SEED-06-015"}
{"Id":"001aj000045ZScgAAG","Seed_Tag__c":"SEED-06-016"}
{"Id":"001aj000045ZSchAAG","Seed_Tag__c":"SEED-06-017"}
{"Id":"001aj000045ZSciAAG","Seed_Tag__c":"SEED-06-018"}
{"Id":"001aj000045ZScjAAG","Seed_Tag__c":"SEED-06-019"}
{"Id":"001aj000045ZSckAAG","Seed_Tag__c":"SEED-06-020"}
{"Id":"001aj000045ZSclAAG","Seed_Tag__c":"SEED-06-021"}
{"Id":"001aj000045ZScmAAG","Seed_Tag__c":"SEED-06-022"}
```

## CONFIRMED — rounded limits; exact storage remains unverified

Command: `sf api request rest /services/data/v68.0/limits --method GET --target-org ng-demo --json`.

```json
{"DataStorageMB":{"Max":5,"Remaining":1},"FileStorageMB":{"Max":20,"Remaining":20}}
```

The owner's earlier 4.1 MB reading remains the latest exact reported figure; no new Storage
Usage screenshot was supplied. Whole-MB Remaining is not evidence of compliance with 4.0 MB.

## REFUTED — all source artifacts needed for reload are present

Local directory tool result for `data/`:

```text
.DS_Store
automation-control/
automation-snapshots/
bad02-stage-last-changed.csv
bad03-cases.csv
csv-resolved/
fixtures/
prepared/
scripts/
SEED_VERSION.txt
```

`data/csv/` is absent. `data/csv/22-loyaltymembers.csv` returned `File not found`.
The resolved artifact exists, but is not a verified replacement for the missing canonical
external-ID source. No regeneration, file deletion, or source repair was attempted.

## REFUTED — fresh duplicate-rule and finance aggregate verification completed

Two independent read-only queries failed and their affected checks stopped without retry:

```sql
SELECT Id, Name, DeveloperName, IsActive FROM DuplicateRule WHERE SobjectType='Contact'
```
```text
No such column 'Name' on entity 'DuplicateRule'. If you are attempting to use a custom field, be sure to append the '__c' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.
```

```sql
SELECT Id, Status__c, COUNT(Id) FROM Financing__c GROUP BY Id, Status__c
```
```text
Grouped field should not be aggregated: Id
```

Manual actions: owner opens Setup → Duplicate Rules → Contact and records both active rule
definitions/actions; owner opens the three finance source reports and captures row counts,
date filters and denominator. These failed checks made no Salesforce changes. Existing release
evidence remains the last verified rule deployment/finance UAT state. All changes in this
investigation are the local documents and candidate BAD-01 CSV listed in the completion plan.
