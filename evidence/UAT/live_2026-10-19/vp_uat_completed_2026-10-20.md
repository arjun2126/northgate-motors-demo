# VP UAT completed — 2026-10-20

**Result: PASS.** Owner approved in the Salesforce UI as Northgate Persona. Persona baseline
restored. VP and Manager UAT records and shares retained.

## Owner browser approval

The owner confirmed the UI showed:

- Opportunity: `UAT-2026-10-20 VP 12PCT`
- Approval step: `Approved`
- Actual approver: `Northgate Persona`
- Discount Percent: `12.60`

No approval or rejection was performed through CLI, Apex, or an administrative session.

## Approval verification

```json
{"Id":"04gaj000001yGanAAE","Status":"Approved","ProcessDefinition":{"DeveloperName":"VP_Discount_Approval"},"TargetObjectId":"006aj00000fb453AAA","SubmittedById":"005aj00000feqbNAAQ","LastActorId":"005aj00000gE0b3AAC","CreatedDate":"2026-10-20T03:27:27.000+0000","LastModifiedDate":"2026-10-20T03:36:35.000+0000","CompletedDate":"2026-10-20T03:36:35.000+0000"}
{"Id":"04haj000000sJNRAA2","ActorId":"005aj00000feqbNAAQ","Actor":{"Name":"Arjun Subramanya"},"StepStatus":"Started","CreatedDate":"2026-10-20T03:27:27.000+0000"}
{"Id":"04haj000000sJTtAAM","ActorId":"005aj00000gE0b3AAC","Actor":{"Name":"Northgate Persona"},"StepStatus":"Approved","CreatedDate":"2026-10-20T03:36:36.000+0000"}
```

- `ProcessInstance` `04gaj000001yGanAAE` = `Approved` — CONFIRMED.
- Completed `2026-10-20T03:36:35Z` — CONFIRMED.
- Approval step actor = `ngpersona` / `Northgate Persona` — CONFIRMED.
- Step status = `Approved` — CONFIRMED.
- Work item `04iaj000003jdBZAAY` query count = `0` — CONFIRMED resolved.
- Work items for instance `04gaj000001yGanAAE` = `0` — CONFIRMED.

## Record verification

```json
{"Id":"006aj00000fb453AAA","Name":"UAT-2026-10-20 VP 12PCT","Discount_Percent__c":12.6,"Approval_Status__c":"Approved","Amount":368904,"StageName":"Prospecting","LastModifiedDate":"2026-10-20T03:36:36.000+0000"}
{"Id":"0Q0aj000003kSijCAE","Subtotal":368904,"Adjusted_Subtotal__c":322422.1,"Rule_Applied_Count__c":2,"Status":"Draft","LastModifiedDate":"2026-10-20T03:27:26.000+0000"}
{"Id":"0QLaj000004exS5GAI","Product2":{"Name":"Aurelia LX 2020"},"Quantity":12,"UnitPrice":30742,"Subtotal":368904}
```

- Opportunity `Approval_Status__c=Approved` — CONFIRMED.
- Opportunity `Discount_Percent__c=12.60` — CONFIRMED.
- Quote list `368904.00`, adjusted `322422.10`, rules `2` — CONFIRMED.
- Quote `LastModifiedDate` unchanged at `2026-10-20T03:27:26Z`; no Quote Builder overwrite —
  CONFIRMED.
- Pricing arithmetic: `368904 * 0.95 * 0.92 = 322422.096 -> 322422.10`; net `12.60%` —
  CONFIRMED.
- CP2 rules: Platinum loyalty 5% and Volume >10 8% — CONFIRMED.

## Pending approvals

```json
{"pending":0,"records":[]}
{"workitems":0,"records":[]}
```

Zero pending `ProcessInstance` and zero `ProcessInstanceWorkitem` org-wide — CONFIRMED.

## Persona restoration

Command: `scripts/persona.sh restore`

```text
Restored baseline: role=VP_Sales (00Eaj00000QCxlLEAT), ManagerId=null, PSGs=<none>.
```

Final verification:

```json
{"Id":"005aj00000gE0b3AAC","Username":"ngpersona.ngdemo@northgate.demo","UserRoleId":"00Eaj00000QCxlLEAT","UserRole":{"DeveloperName":"VP_Sales"},"ManagerId":null,"ProfileId":"00eaj00000TnZaFAAV","Profile":{"Name":"NG_Sales"},"IsActive":true}
{"count":1,"users":[{"Id":"005aj00000gE0b3AAC","Username":"ngpersona.ngdemo@northgate.demo","active":true}]}
{"count":0,"psgs":[]}
{"count":2,"assignments":[{"ps":"X00eaj00000TnZaFAAV"},{"ps":"NG_Lightning_Experience_Access"}]}
```

- Role = `VP_Sales` — CONFIRMED.
- ManagerId = null — CONFIRMED.
- Profile = `NG_Sales` — CONFIRMED.
- Managed persona PSGs = none; `PSG_Manager` removed — CONFIRMED.
- Exactly one active VP_Sales user = `ngpersona` — CONFIRMED.
- Unrelated direct permission sets retained: `X00eaj00000TnZaFAAV`,
  `NG_Lightning_Experience_Access` — CONFIRMED.
- Persona history records `restore` at `2026-10-20T03:37:53Z` — CONFIRMED.

## Records and shares retained

```json
{"Id":"00taj00000MxTvmAAF","UserOrGroupId":"005aj00000gE0b3AAC","OpportunityAccessLevel":"Read","RowCause":"Manual"}
{"Id":"00taj00000MxTvlAAF","UserOrGroupId":"005aj00000feqbNAAQ","OpportunityAccessLevel":"All","RowCause":"Owner"}
```

- VP UAT Opportunity and Quote retained — CONFIRMED.
- Manual Read share retained — CONFIRMED.
- Owner share retained — CONFIRMED.
- No UAT record or share deleted — CONFIRMED.

Historical Manager UAT remains:

```json
{"Id":"006aj00000faIjZAAU","Discount_Percent__c":8.92,"Approval_Status__c":"Approved","LastModifiedDate":"2026-10-20T03:11:02.000+0000"}
{"Id":"0Q0aj000003kJNhCAM","LastModifiedDate":"2026-10-19T21:56:43.000+0000"}
{"Id":"0Q0aj000003kQgwCAE","LastModifiedDate":"2026-10-20T02:40:27.000+0000"}
```

## Finance UAT readiness

```text
Org: ng-demo (00Daj00001Ae3iWEAR) CONFIRMED
User: ngpersona.ngdemo@northgate.demo (005aj00000gE0b3AAC) CONFIRMED
Current role: VP_Sales (00Eaj00000QCxlLEAT)
Current persona PSGs: <none>
Target persona: finance -> role Finance_Manager (00Eaj00000QC9uzEAD), PSG PSG_Finance (0PGaj000005miOrGAI, status Updated)
Would ADD PSG: PSG_Finance (0PGaj000005miOrGAI)
Would UPDATE ROLE: VP_Sales -> Finance_Manager (00Eaj00000QC9uzEAD)
Would PRESERVE: ManagerId=null, profile=00eaj00000TnZaFAAV, PSG_Service, unrelated permission sets.
DRY RUN: no Salesforce DML performed.
```

- `Finance_Manager` role exists — CONFIRMED.
- `PSG_Finance` exists and is `Updated` — CONFIRMED.
- No active Finance_Manager user currently — CONFIRMED.
- Finance dry-run guard passes — CONFIRMED.
- No Finance persona switch, records, shares, or approvals were created.

## Scope and remaining risk

- No deployment, commit, push, historical cleanup, or `ng-dev` access.
- `P3-DEF-01` remains unresolved; do not save another Quote on a pending Opportunity.
- Finance UAT scenario and approval routing are not yet prepared or authorized.
