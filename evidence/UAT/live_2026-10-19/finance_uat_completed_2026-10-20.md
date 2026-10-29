# Finance UAT completed — 2026-10-20

**Result: PASS.** Owner approved in the Salesforce UI as Northgate Persona. Finance exception
approval routed through `Q_Finance_Approvals`, the exception flag and decision date were written,
the Quote was unchanged, the persona baseline was restored, and the UAT records and shares were
retained.

## Owner browser approval

The owner approved the pending Finance work item in the Salesforce UI as `ngpersona`
(`Northgate Persona`). No approval or rejection was performed through CLI, Apex, or an
administrative session.

## Approval verification

```json
{"Id":"04gaj000001yGqvAAE","Status":"Approved","ProcessDefinition":{"DeveloperName":"Financing_Exception_Approval"},"TargetObjectId":"a04aj0000089SN3AAM","SubmittedById":"005aj00000feqbNAAQ","LastActorId":"005aj00000gE0b3AAC","CreatedDate":"2026-10-20T04:09:25.000+0000","LastModifiedDate":"2026-10-20T04:25:01.000+0000","CompletedDate":"2026-10-20T04:25:01.000+0000"}
{"Id":"04haj000000sJgnAAE","ActorId":"005aj00000gE0b3AAC","Actor":{"Name":"Northgate Persona"},"StepStatus":"Approved","CreatedDate":"2026-10-20T04:25:01.000+0000"}
{"Id":"04iaj000003jdTJAAY"}
```

- `ProcessInstance` `04gaj000001yGqvAAE` = `Approved` — CONFIRMED.
- Completed `2026-10-20T04:25:01Z` — CONFIRMED.
- Approval step actor = `ngpersona` / `Northgate Persona`, status `Approved` — CONFIRMED.
- Work item `04iaj000003jdTJAAY` query returned 0 rows — CONFIRMED resolved.
- Work items for the process instance returned 0 rows — CONFIRMED.

## Record verification

```json
{"Id":"a04aj0000089SN3AAM","Name":"63","Status__c":"Draft","Amount_Financed__c":30742,"Annual_Rate__c":7.25,"Term_Months__c":60,"Monthly_Payment__c":612.36,"Total_Interest__c":5999.6,"Rate_Source__c":"Manual_Exception","Finance_Exception_Approved__c":true,"Decision_Date__c":"2026-10-20","LastModifiedDate":"2026-10-20T04:25:01.000+0000"}
{"Id":"0Q0aj000003kU7pCAE","Name":"UAT-2026-10-19 FIN Exception - Quote","Subtotal":30742,"Adjusted_Subtotal__c":30742,"Rule_Applied_Count__c":0,"Status":"Draft","LastModifiedDate":"2026-10-20T04:09:24.000+0000"}
{"Id":"0QLaj000004eyzFGAQ","Product2":{"Name":"Aurelia LX 2020"},"Quantity":1,"UnitPrice":30742,"Subtotal":30742}
{"Id":"006aj00000fb6wUAAQ","Name":"UAT-2026-10-19 FIN Exception","StageName":"Financing","Amount":30742,"Discount_Percent__c":0,"Approval_Status__c":"Not_Required","LastModifiedDate":"2026-10-20T04:09:24.000+0000"}
```

- Financing math unchanged: `30742`, `7.25%`, `60` months, `612.36` payment, `5999.60` interest —
  CONFIRMED.
- `Rate_Source__c = Manual_Exception` — CONFIRMED.
- `Finance_Exception_Approved__c = true` — CONFIRMED.
- `Decision_Date__c = 2026-10-20` — CONFIRMED. The seed label uses `2026-10-19`; the org date
  rolled before execution. The process writes the current org date, not the seed label.
- `Status__c = Draft` — CONFIRMED. This matches the established process behavior: approval sets
  the exception flag and date but does not change `Status__c`.
- Quote subtotal `30742`, adjusted subtotal `30742`, rules applied `0`, status `Draft` —
  CONFIRMED.
- Quote `LastModifiedDate` unchanged at `2026-10-20T04:09:24Z` — CONFIRMED; no Quote overwrite.
- Opportunity amount `30742`, discount `0`, approval status `Not_Required` — CONFIRMED.

## Pending approvals

```text
FIN_PRE_RESTORE_GUARD={"status":"PASS","pendingFinanceQueueWorkItems":0,"pendingFinanceApprovals":0}
```

Read-only guard command: `sf apex run --target-org ng-demo --file
scripts/uat/finance_pre_restore_guard.apex`.

- Pending `Financing_Exception_Approval` instances = `0` — CONFIRMED.
- Pending `Q_Finance_Approvals` work items = `0` — CONFIRMED.
- Guard status = `PASS` — CONFIRMED.

## Persona restoration

Command: `scripts/persona.sh restore`

```text
2026-10-20T04:26:29Z	action=restore	role=VP_Sales	psgs=	baseline=evidence/UAT/persona_baseline.json
```

Final verification:

```json
{"Id":"005aj00000gE0b3AAC","Username":"ngpersona.ngdemo@northgate.demo","UserRole":{"DeveloperName":"VP_Sales"},"ManagerId":null,"Profile":{"Name":"NG_Sales"},"IsActive":true}
{"activeFinanceManagers":0}
{"activeVPs":1}
```

- Role = `VP_Sales` — CONFIRMED.
- `ManagerId` = null — CONFIRMED.
- Profile = `NG_Sales` — CONFIRMED.
- Persona permission set group assignments = none — CONFIRMED.
- Exactly zero active `Finance_Manager` users — CONFIRMED.
- Exactly one active `VP_Sales` user (`ngpersona`) — CONFIRMED.
- Persona history records `restore` at `2026-10-20T04:26:29Z` — CONFIRMED.

## Records and shares retained

```json
{"Id":"02caj00001Ik8arAAB","UserOrGroupId":"005aj00000gE0b3AAC","AccessLevel":"Read","RowCause":"Manual"}
{"Id":"00taj00000MxVmKAAV","UserOrGroupId":"005aj00000gE0b3AAC","OpportunityAccessLevel":"Read","RowCause":"Manual"}
{"Id":"03saj000000DAw2AAG","UserOrGroupId":"005aj00000gE0b3AAC","ContactAccessLevel":"Read","RowCause":"Manual"}
```

- `Financing__Share`, `OpportunityShare`, and `ContactShare` remain present, all Read/Manual, all
  scoped to `ngpersona` — CONFIRMED.
- Finance UAT Account, Contact, Opportunity, Quote, QuoteLineItem, and Financing records retained —
  CONFIRMED.
- No UAT record or share was deleted.

## Scope and remaining risk

- No deployment, commit, push, historical cleanup, or `ng-dev` access.
- `P3-DEF-01` remains unresolved; do not save another Quote on an Opportunity with an existing
  quote or pending approval.
- Future Finance UAT must run `scripts/uat/finance_pre_restore_guard.apex` before restore.
  `scripts/persona.sh restore` does not detect queue-assigned Finance approvals.
