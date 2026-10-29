# Management and Test Drive UAT — controlled window

## Status and scope

Read-only preflight completed on 2026-10-21 in `ng-demo`. The owner then selected **Available; approve management**, authorizing exactly the two planned temporary grants and deletion of their captured IDs. Booking writes and rep activation remain unauthorized. No persona switch, metadata deployment, or regression run is included.

**Final window status:** The owner completed management browser UAT and requested closure. Both session-created grants were deleted successfully, and live baseline queries match the pre-state. Service/Finance drill-through and executive dashboard failures are recorded below. Test Drive writes remain paused at the owner's explicit direction.

Use `docs/planning/P5_BATCH2_ACCESS_RESOLUTION_2026-10-20.md` for management semantics. The older Batch 2 management document is superseded for expected access and values; its captured-ID restoration procedure remains applicable. Historical report totals must not be treated as current totals after the cleanup.

## CONFIRMED — current org and security baseline

Raw excerpts from successful `sf data query --target-org ng-demo --json` responses:

```json
{"Id":"00Daj00001Ae3iWEAR"}
{"Id":"005aj00000gE0b3AAC","UserRoleId":"00Eaj00000QCxlLEAT","UserRole":{"DeveloperName":"VP_Sales"},"ProfileId":"00eaj00000TnZaFAAV","Profile":{"Name":"NG_Sales"},"ManagerId":null,"TimeZoneSidKey":"America/Toronto"}
```

PermissionSetAssignment query returned exactly two records:

```json
{"Id":"0Paaj000016Ty3HCAS","PermissionSetId":"0PSaj00000gE0RPGA0","PermissionSetGroupId":null}
{"Id":"0Paaj000016dBqzCAE","PermissionSetId":"0PSaj00000gKc49GAC","PermissionSetGroupId":null}
```

GroupMember query returned exactly one record:

```json
{"Id":"011aj000006D0ErAAK","GroupId":"00Gaj00000ZYYhUEAX","Group":{"DeveloperName":"PG_All_Sales"},"UserOrGroupId":"005aj00000gE0b3AAC"}
```

Automation settings query returned exactly one record:

```json
{"Id":"a00aj00003oHxQMAA0","SetupOwnerId":"00Daj00001Ae3iWEAR","Bypass_Triggers__c":false,"Bypass_Flows__c":false,"Bypass_Validation__c":false}
```

The baseline was refreshed immediately before creation and after deletion. Both query sets returned the same original assignment IDs, public-group membership, role/profile, null ManagerId, and false automation flags.

## CONFIRMED — management grant scope

PermissionSet query returned:

```json
{"Id":"0PSaj00000gE0RPGA0","PermissionsRunFlow":false,"PermissionsRunReports":false}
{"Id":"0PSaj00000gKc49GAC","PermissionsRunFlow":false,"PermissionsRunReports":false}
{"Id":"0PSaj00000gUOW9GAO","Name":"PS_Management_Reports","PermissionsRunFlow":false,"PermissionsRunReports":true}
```

The owner approved and this window executed:

1. Create GroupMember for group `00Gaj00000ZkluDEAR` and user `005aj00000gE0b3AAC`.
2. Create PermissionSetAssignment for set `0PSaj00000gUOW9GAO` and the same user.
3. After browser UAT, delete only the two IDs returned by this window's successful creates and compare the complete security baseline.

No role, profile, object permissions, record sharing, or booking access was changed. Fixed dashboard values were observed by the owner as the persona and cross-checked against admin report results. Drill-through observations came from the owner's genuine persona session; admin REST requests were not substituted for persona evidence.

## CONFIRMED — deployed booking Flow

Raw excerpts from successful Tooling API queries:

```json
{"Id":"300aj00003p8rt3AAA","DeveloperName":"TestDrive_Book_Screen","ActiveVersionId":"301aj000046ME8UAAW","LatestVersionId":"301aj000046ME8UAAW"}
{"Id":"301aj000046ME8UAAW","Status":"Active","VersionNumber":1,"Metadata":{"label":"Book Test Drive","processType":"Flow","runInMode":null}}
```

The existing approved procedure specifies direct launch at `/flow/TestDrive_Book_Screen`. Local metadata search found no additional launcher reference outside the Flow and its booking permission set. This is not proof that no live launcher exists.

The active Flow metadata contains required Vehicle, Contact, start time, and duration inputs; future-start and 1–180-minute screen validation; Requested/Scheduled overlap lookup; booking creation; confirmation; and conflict/error screens. Its create element sets Contact, Vehicle, start, duration, and Scheduled status; it does not set Opportunity.

## REFUTED — current baseline is already configured as Sales Rep

The live User query above returns `VP_Sales`, and neither current assignment has a permission-set group. A targeted ObjectPermissions query for the two current sets and Contact, Vehicle__c, Test_Drive__c, and Staff__c returned only:

```json
{"ParentId":"0PSaj00000gE0RPGA0","SobjectType":"Contact","PermissionsRead":true,"PermissionsCreate":true,"PermissionsEdit":true}
```

The planned management grants do not provide the missing Vehicle/Test Drive access or RunFlow. Successful Sales Rep booking cannot be verified with this baseline. The existing Phase 2 procedure calls for a separately approved `rep` persona activation and exact restoration; it is not included in the two management grants.

No runtime booking defect has been confirmed. Standard-form enforcement, required-field rejection, conflict handling, relationships, successful saves, follow-up Tasks, counters, and email delivery remain untested in the actual rep session. Source inspection and earlier passing tests do not substitute for those observations.

## Next authorized window

### Management execution journal

The baseline queries were repeated immediately before the grant window and returned the same two permission assignments, one public-group membership, VP_Sales role, NG_Sales profile, null ManagerId, and three false automation flags. Group `00Gaj00000ZkluDEAR` was rechecked as `PG_Northgate_Management`.

Grant creation responses were recorded below before browser interaction. Both grant tuples were queried successfully before the owner began. Cleanup used only the IDs from those successful create responses.

GroupMember create response:

```json
{"status":0,"result":{"id":"011aj000006F50jAAC","success":true,"errors":[]},"warnings":[]}
```

Recovery command for this grant only:

```bash
sf data delete record --target-org ng-demo --sobject GroupMember --record-id 011aj000006F50jAAC --json
```

PermissionSetAssignment create response:

```json
{"status":0,"result":{"id":"0Paaj0000173QlICAU","success":true,"errors":[]},"warnings":[]}
```

Recovery command for this grant only:

```bash
sf data delete record --target-org ng-demo --sobject PermissionSetAssignment --record-id 0Paaj0000173QlICAU --json
```

### CONFIRMED — exact-ID restoration

Raw delete responses:

```json
{"status":0,"result":{"id":"011aj000006F50jAAC","success":true,"errors":[]},"warnings":[]}
{"status":0,"result":{"id":"0Paaj0000173QlICAU","success":true,"errors":[]},"warnings":[]}
```

Raw post-cleanup query excerpts (complete returned row sets, attributes omitted):

```json
{"PermissionSetAssignment":{"totalSize":2,"records":[{"Id":"0Paaj000016Ty3HCAS","PermissionSetId":"0PSaj00000gE0RPGA0","PermissionSetGroupId":null},{"Id":"0Paaj000016dBqzCAE","PermissionSetId":"0PSaj00000gKc49GAC","PermissionSetGroupId":null}]}}
{"GroupMember":{"totalSize":1,"records":[{"Id":"011aj000006D0ErAAK","GroupId":"00Gaj00000ZYYhUEAX","UserOrGroupId":"005aj00000gE0b3AAC"}]}}
{"User":{"Id":"005aj00000gE0b3AAC","UserRoleId":"00Eaj00000QCxlLEAT","ProfileId":"00eaj00000TnZaFAAV","ManagerId":null}}
{"Automation_Settings__c":{"totalSize":1,"records":[{"Id":"a00aj00003oHxQMAA0","SetupOwnerId":"00Daj00001Ae3iWEAR","Bypass_Triggers__c":false,"Bypass_Flows__c":false,"Bypass_Validation__c":false}]}}
```

## CONFIRMED — owner-reported management browser results

Evidence is the owner's session observations in this conversation. No screenshots were supplied. The actor was Northgate Persona at the captured VP_Sales baseline, not a newly activated Sales_Rep configuration.

> Sales: PASS. Pipeline $4,827,766; Open Opportunities by Sales Staff 65. Both source reports opened successfully.
>
> Service: Dashboard renders. Overdue Service Visits 13; CSI Proxy 0. Both source-report links return "You can't view report" access errors.
>
> Finance: Dashboard renders. Exception Candidates 0; Decline Rate 0%; Average Days to Fund 0. Tested finance report drill-through returns "You can't view report."
>
> Executive: FAIL. Dashboard runs as Northgate Persona, but components show inaccessible report-type errors and a field-availability error. Metrics do not render.

The owner explicitly requested ending the window, exact-ID grant removal, read-only diagnosis, no broader access or deployment, and no booking writes yet. Sales rendering and opening its two reports passed; persona report totals were not supplied, so a numerical admin-versus-persona scope comparison is still unverified. Service and Finance rendering passed, but their drill-through failed. Executive rendering failed. P5-14/P5-15 are not fully accepted.

## CONFIRMED — current live running-user configuration and source values

Read-only `sf api request rest` GETs of the four dashboards returned these metadata excerpts:

```json
{"id":"01Zaj00000BVDIoEAP","developerName":"DM_Sales_Operations","dashboardType":"SpecifiedUser","runningUser":{"id":"005aj00000feqbNAAQ"}}
{"id":"01Zaj00000BVDIpEAP","developerName":"DM_Service_OperationsFixed","dashboardType":"SpecifiedUser","runningUser":{"id":"005aj00000feqbNAAQ"}}
{"id":"01Zaj00000BVDInEAP","developerName":"DM_Finance_Operations","dashboardType":"SpecifiedUser","runningUser":{"id":"005aj00000feqbNAAQ"}}
{"id":"01Zaj00000BVDIqEAP","developerName":"DM_Exec_OperationsOverview","dashboardType":"LoggedInUser"}
```

The `runningUser` value in an admin GET of the dynamic dashboard is not evidence of the persona's execution context. Its `LoggedInUser` type and the owner's browser observation establish the intended context.

Admin-context report GETs with `includeDetails=false` returned these raw aggregate excerpts:

```json
{"reportId":"00Oaj00000UhWmZEAV","aggregates":["s!AMOUNT","RowCount"],"grandTotal":[{"label":"$4,827,766.00","value":4827766},{"label":"82","value":82}],"allData":true}
{"reportId":"00Oaj00000UhWmYEAV","aggregates":["s!AMOUNT"],"grandTotal":[{"label":"$3,585,146.00","value":3585146}],"allData":true}
{"reportId":"00Oaj00000UjuKwEAJ","aggregates":["RowCount"],"grandTotal":[{"label":"13","value":13}],"allData":true}
{"reportId":"00Oaj00000UoEmTEAV","aggregates":["a!Service_Visit__c.CSI_Score__c","RowCount"],"grandTotal":[{"label":"0","value":0},{"label":"0","value":0}],"allData":true}
{"reportId":"00Oaj00000UhW1lEAF","aggregates":["RowCount"],"grandTotal":[{"label":"0","value":0}],"allData":true}
{"reportId":"00Oaj00000UhW1nEAF","aggregates":["s!CDF1","FORMULA1","RowCount"],"grandTotal":[{"label":"0","value":0},{"label":"-","value":null},{"label":"0","value":0}],"allData":true}
{"reportId":"00Oaj00000UhW1mEAF","aggregates":["a!Financing__c.Days_To_Fund__c","RowCount"],"grandTotal":[{"label":"0","value":0},{"label":"0","value":0}],"allData":true}
```

The fixed Sales dashboard's staff component uses RowCount in live dashboard metadata; the owner observed 65. The report GET above exposes its Amount aggregate rather than a RowCount, so that response independently confirms Amount, not the 65 tile count. CSI and funded populations are empty. The decline-rate summary formula is null with zero rows; the displayed 0% is not evidence of a true zero business decline rate. Fixed dashboard values do not confer access to underlying records.

## CONFIRMED — specific access gaps behind the failures

All following checks were read-only after grant restoration. The two temporary grants changed only folder membership and RunReports, so their removal did not change the object/FLS gaps being diagnosed.

### Report folders are already shared to the persona's existing group

GET `/services/data/v68.0/folders/<id>/shares` returned these raw share excerpts:

```json
{"folderId":"00laj00000QOMtGAAX","shareId":"0AFaj000008LNrWGAW","accessType":"view","shareType":"group","sharedWithId":"00Gaj00000ZYYhUEAX"}
{"folderId":"00laj00000QMgBJAA1","shareId":"0AFaj000008LNrYGAW","accessType":"view","shareType":"group","sharedWithId":"00Gaj00000ZYYhUEAX"}
{"folderId":"00laj00000QOMtFAAX","shareId":"0AFaj000008LNrVGAW","accessType":"view","shareType":"group","sharedWithId":"00Gaj00000ZYYhUEAX"}
{"folderId":"00laj00000QOMtHAAX","shareId":"0AFaj000008LNrZGAW","accessType":"view","shareType":"group","sharedWithId":"00Gaj00000ZYYhUEAX"}
{"folderId":"00laj00000QMgknAAD","shareId":"0AFaj000008LNrSGAW","accessType":"view","shareType":"group","sharedWithId":"00Gaj00000ZYYhUEAX"}
```

These are Service, Data Quality/Finance, Inventory, Loyalty, and Pipeline report folders respectively. The user remains in `PG_All_Sales` (`00Gaj00000ZYYhUEAX`). Adding more report-folder shares would not address the demonstrated missing object permissions.

### Base-object and lookup-field permissions are missing

ObjectPermissions query across the profile set, Lightning access set, and temporary reporting set, restricted to the ten report-related objects, returned only these three records:

```json
{"ParentId":"0PSaj00000gE0RPGA0","SobjectType":"Account","PermissionsRead":true}
{"ParentId":"0PSaj00000gE0RPGA0","SobjectType":"Contact","PermissionsRead":true}
{"ParentId":"0PSaj00000gE0RPGA0","SobjectType":"Opportunity","PermissionsRead":true}
```

There is no Read grant in those sets for Vehicle__c, Vehicle_Model__c, Service_Visit__c, Loyalty_Member__c, Financing__c, Rooftop__c, or Staff__c. FieldPermissions for Opportunity, Vehicle__c, Service_Visit__c, Loyalty_Member__c, and Financing__c across those same sets returned only:

```json
{"ParentId":"0PSaj00000gE0RPGA0","SobjectType":"Opportunity","Field":"Opportunity.CampaignId","PermissionsRead":true}
```

The live source report definitions identify:

- Service SLA and CSI: `ServiceVisitList__c` on Service_Visit__c. Missing base-object Read blocks the report type. CSI also groups by `Service_Visit__c.Rooftop__c.Name`, requiring the lookup field and target access.
- Finance sources: `FinancingList__c` on Financing__c. Missing base-object Read blocks the report type. The reports also use Opportunity and Applicant/Contact lookups and finance fields.
- Executive Inventory: `VehicleList__c`, missing Vehicle__c Read and report fields; grouping uses `Vehicle__c.Rooftop__c.Name`.
- Executive Loyalty: `LoyaltyMemberList__c`, missing Loyalty_Member__c Read and tier/status/balance fields.
- Executive Pipeline: the same standard Opportunity source that opened from Sales, but live matrix metadata groups across `Opportunity.Sales_Staff__c`; this field has no Read grant and Staff__c has no Read grant. This is a concrete field/lookup access gap consistent with the field-availability failure.

The owner's executive error did not include the exact field name or component text. Attribution of that specific error to Sales_Staff__c remains a diagnosis supported by metadata, not a reproduced per-field runtime result. Do not claim the precise component error is resolved or that the opened Sales report exposed every grouping field.

## Proposed narrow fixes — not applied

1. Prepare a separate, reviewed read-only management reporting permission set. Grant only base-object Read and the fields used by the failing reports, including required lookup targets. Do not reuse a sales/finance write permission set as a reporting workaround.
2. For Pipeline, include Read on Staff__c and `Opportunity.Sales_Staff__c`. For Inventory and CSI, include Read on Rooftop__c and their Rooftop lookup fields. Include only other fields actually used in columns, filters, dates, groupings, and formulas.
3. For Service, include Service_Visit__c Read and Service_Type__c, Status__c, Scheduled_Start__c, CSI_Score__c, and Rooftop__c. For Inventory, include Vehicle__c Read and VIN__c, Acquisition_Date__c, Inventory_Age_Days__c, and Rooftop__c. For Loyalty, include Loyalty_Member__c Read and Tier__c, Status__c, Points_Balance__c, Lifetime_Points_Earned__c, Member_Number__c, and Join_Date__c.
4. Finance needs Financing__c Read and the exact existing report fields: Opportunity__c, Applicant__c, Status__c, Credit_Tier__c, Rate_Source__c, Annual_Rate__c, Term_Months__c, Amount_Financed__c, Monthly_Payment__c, Lender__c, Exception_Reason__c, Finance_Exception_Approved__c, Application_Date__c, Decision_Date__c, Funded_Date__c, and Days_To_Fund__c. Review this finance exposure explicitly before any assignment. Do not grant Create/Edit/Delete, View All, Modify All, bypass, or approval-administration permissions.
5. Preserve current record sharing. Object/FLS repairs can make a report runnable without making private records visible. If genuine management access to private Service/Finance rows is required, obtain a separate exact record-scope decision; no broad sharing is recommended here.
6. Capture the exact executive field error on the next approved window, then retest only the failed components and drill-through. Do not change reports to suppress missing fields, change the dynamic running user, or manufacture data to hide empty metrics.

No proposed permission set, field grant, share, report change, or metadata deployment was created.

Management window is complete and restored. A future repair/retest window requires separate approval for the reviewed exact fix and temporary assignments. No browser-control tool is available in this session; browser evidence comes from the owner.

Booking requires a separate exact-write agreement after resolving rep activation: disposable Contact/Vehicle scope, future local-time slots, two successful booking attempts, overlap/invalid attempts, expected automation side effects, and restoration. No disposable UAT records are approved by this document.

## Remaining acceptance and Phase 6

Management browser execution is complete: Sales passed the observed rendering/open-report checks, Service/Finance failed drill-through, and Executive failed component rendering. Repairs and targeted retest remain pending. Booking UAT remains paused and unauthorized. Existing Phase 5 gaps also include exact storage evidence, canonical source/idempotency, complete integrity/gates/findings/drift evidence, ledger history, inventory/SLA count deviations, report-builder evidence, and reset/burst acceptance. Earlier cleanup reporting does not waive these criteria or establish exact storage from a whole-MB limit.

Phase 5 is not signed off. Phase 6 planning can proceed independently; live Phase 6 implementation should wait for owner-approved transition and the outstanding functional UAT results. No completed functionality was changed in this preflight.
