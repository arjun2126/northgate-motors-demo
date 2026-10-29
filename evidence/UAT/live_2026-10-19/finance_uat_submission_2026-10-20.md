# Finance UAT submission — 2026-10-20

**Status:** Pending owner browser approval. No approval or rejection was performed through
CLI, Apex, or an administrative session. Persona remains `Finance_Manager`; baseline is not
restored until the approval is complete and the pre-restore guard passes.

## Preflight

- Org: `ng-demo`, `00Daj00001Ae3iWEAR` — CONFIRMED.
- `ngpersona`: `005aj00000gE0b3AAC` — CONFIRMED.
- Baseline: `VP_Sales`, ManagerId null, profile `NG_Sales`, no managed persona PSGs —
  CONFIRMED.
- Pending `Financing_Exception_Approval`: 0 — CONFIRMED.
- Pending `Q_Finance_Approvals` work items: 0 — CONFIRMED.
- Existing seed Account, Opportunity, Financing: 0 each — CONFIRMED.
- `Financing_Exception_Approval` active: `04aaj000003QUWzAAO` — CONFIRMED.
- `Q_Finance_Approvals` active, `DoesIncludeBosses=true` — CONFIRMED.
- `PSG_Finance` status `Updated` — CONFIRMED.
- Org time at execution: `2026-10-20 00:08:48`, time zone `America/Toronto` — CONFIRMED.
- The seed label uses `2026-10-19`; the org date rolled before execution, so the expected
  decision date is `2026-10-20`.

## Persona switch

Command: `scripts/persona.sh finance`

```text
Baseline already exists: evidence/UAT/persona_baseline.json (not overwritten).
Active persona: finance (role Finance_Manager, PSG PSG_Finance)
Preserved: ManagerId=null, profile=00eaj00000TnZaFAAV, PSG_Service.
```

Post-switch verification:

```json
{"Id":"005aj00000gE0b3AAC","Username":"ngpersona.ngdemo@northgate.demo","UserRoleId":"00Eaj00000QC9uzEAD","UserRole":{"DeveloperName":"Finance_Manager"},"ManagerId":null,"ProfileId":"00eaj00000TnZaFAAV","Profile":{"Name":"NG_Sales"},"IsActive":true}
{"count":1,"users":[{"Id":"005aj00000gE0b3AAC","Username":"ngpersona.ngdemo@northgate.demo","role":"Finance_Manager"}]}
{"psgId":"0PGaj000005miOrGAI","name":"PSG_Finance"}
```

- Role `Finance_Manager` — CONFIRMED.
- Exactly one active Finance_Manager user, `ngpersona` — CONFIRMED.
- ManagerId null, profile `NG_Sales` — CONFIRMED.
- `PSG_Finance` assigned — CONFIRMED.
- No pending ngpersona approvals or work items — CONFIRMED.

## Setup result

Command: `sf apex run --target-org ng-demo --file scripts/uat/finance_setup.apex`

```text
FIN_UAT_RESULT={"approvalUrl":"/p/process/ProcessInstanceWorkitemWizardStageManager?id=04iaj000003jdTJAAY","financingUrl":"/lightning/r/Financing__c/a04aj0000089SN3AAM/view","shares":{"contact":"03saj000000DAw2AAG","opportunity":"00taj00000MxVmKAAV","financing":"02caj00001Ik8arAAB"},"queueId":"00Gaj00000ZYezlEAD","workItemActorId":"00Gaj00000ZYezlEAD","workItemId":"04iaj000003jdTJAAY","processInstanceId":"04gaj000001yGqvAAE","quoteRulesApplied":0,"quoteAdjustedSubtotal":30742.00,"quoteSubtotal":30742.00,"totalInterest":5999.60,"monthlyPayment":612.36,"termMonths":60,"annualRate":7.250,"amountFinanced":30742.00,"financingName":"63","financingId":"a04aj0000089SN3AAM","quoteName":"UAT-2026-10-19 FIN Exception - Quote","quoteId":"0Q0aj000003kU7pCAE","opportunityName":"UAT-2026-10-19 FIN Exception","opportunityId":"006aj00000fb6wUAAQ","contactId":"003aj00002WStpKAAT","accountId":"001aj000046FiCxAAK","seed":"UAT-2026-10-19-FIN-EXCEPTION"}
```

## Records and access

```json
{"Id":"a04aj0000089SN3AAM","Name":"63","Seed_Tag__c":"UAT-2026-10-19-FIN-EXCEPTION","Status__c":"Draft","Amount_Financed__c":30742,"Down_Payment__c":0,"Annual_Rate__c":7.25,"Term_Months__c":60,"Monthly_Payment__c":612.36,"Total_Interest__c":5999.6,"Rate_Source__c":"Manual_Exception","Credit_Tier__c":"A","Finance_Exception_Approved__c":false,"Decision_Date__c":null,"Opportunity__c":"006aj00000fb6wUAAQ","Quote__c":"0Q0aj000003kU7pCAE","Applicant__c":"003aj00002WStpKAAT","OwnerId":"005aj00000feqbNAAQ"}
{"Id":"0Q0aj000003kU7pCAE","Name":"UAT-2026-10-19 FIN Exception - Quote","OpportunityId":"006aj00000fb6wUAAQ","Subtotal":30742,"Adjusted_Subtotal__c":30742,"Rule_Applied_Count__c":0,"Status":"Draft","Buyer_Contact__c":"003aj00002WStpKAAT"}
{"Id":"0QLaj000004eyzFGAQ","Product2":{"Name":"Aurelia LX 2020"},"Quantity":1,"UnitPrice":30742,"Subtotal":30742}
{"Id":"006aj00000fb6wUAAQ","Name":"UAT-2026-10-19 FIN Exception","StageName":"Financing","Amount":30742,"AccountId":"001aj000046FiCxAAK","Discount_Percent__c":0,"Approval_Status__c":"Not_Required","OwnerId":"005aj00000feqbNAAQ"}
```

- Financing math: `30742`, `7.25%`, `60` months, `612.36` payment, `5999.60` interest —
  CONFIRMED.
- Quote `30742`, adjusted `30742`, zero rules, zero discount — CONFIRMED.
- Opportunity stamp `0` discount, `Not_Required` — CONFIRMED.
- Financing remains `Draft`, exception flag false, decision date null — CONFIRMED.

```json
{"Id":"02caj00001Ik8arAAB","ParentId":"a04aj0000089SN3AAM","UserOrGroupId":"005aj00000gE0b3AAC","AccessLevel":"Read","RowCause":"Manual"}
{"Id":"00taj00000MxVmKAAV","OpportunityId":"006aj00000fb6wUAAQ","UserOrGroupId":"005aj00000gE0b3AAC","OpportunityAccessLevel":"Read","RowCause":"Manual"}
{"Id":"03saj000000DAw2AAG","ContactId":"003aj00002WStpKAAT","UserOrGroupId":"005aj00000gE0b3AAC","ContactAccessLevel":"Read","RowCause":"Manual"}
```

- Three scoped manual Read shares to `ngpersona` — CONFIRMED.
- No historical record or share changed — CONFIRMED.

## Pending approval

```json
{"Id":"04gaj000001yGqvAAE","Status":"Pending","ProcessDefinition":{"DeveloperName":"Financing_Exception_Approval"},"TargetObjectId":"a04aj0000089SN3AAM","SubmittedById":"005aj00000feqbNAAQ","LastActorId":null}
{"Id":"04haj000000sJdZAAU","ActorId":"005aj00000feqbNAAQ","StepStatus":"Started"}
{"Id":"04iaj000003jdTJAAY","ActorId":"00Gaj00000ZYezlEAD","ProcessInstanceId":"04gaj000001yGqvAAE"}
```

- Process `04gaj000001yGqvAAE` = `Pending` — CONFIRMED.
- Submitted by Arjun, work item actor `Q_Finance_Approvals` — CONFIRMED.
- Exactly one pending Finance queue work item — CONFIRMED.
- Financing still `Draft`, flag false, decision null — CONFIRMED.

## Browser handoff

Approval URL:

`https://orgfarm-25065ad46a-dev-ed.develop.my.salesforce.com/p/process/ProcessInstanceWorkitemWizardStageManager?id=04iaj000003jdTJAAY`

Financing record:

`https://orgfarm-25065ad46a-dev-ed.develop.my.salesforce.com/lightning/r/Financing__c/a04aj0000089SN3AAM/view`

The owner must log in as `ngpersona` (Northgate Persona), open the approval URL, confirm the
displayed Financing values, and click Approve once. Do not edit, reject, reassign, or approve
as an administrator. After approval, run the pre-restore guard and restore the baseline.
