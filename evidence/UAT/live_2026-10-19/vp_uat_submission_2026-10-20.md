# VP UAT submission — 2026-10-20

**Status:** Approved by owner in browser and restored. Final results:
`evidence/UAT/live_2026-10-19/vp_uat_completed_2026-10-20.md`. No approval or rejection was
performed through CLI, Apex, or an administrative session.

## Preflight

- Org: `ng-demo`, `00Daj00001Ae3iWEAR` — CONFIRMED.
- `ngpersona`: `005aj00000gE0b3AAC` — CONFIRMED.
- Baseline: `VP_Sales`, ManagerId null, profile `NG_Sales`, no managed persona PSGs —
  CONFIRMED.
- Pending `ProcessInstance`: 0 — CONFIRMED.
- Pending `ProcessInstanceWorkitem`: 0 — CONFIRMED.
- Existing VP_Sales users before switch: 0 — CONFIRMED.

## Persona switch

Command: `scripts/persona.sh vp`

```text
Baseline already exists: evidence/UAT/persona_baseline.json (not overwritten).
Active persona: vp (role VP_Sales, PSG PSG_Manager)
Preserved: ManagerId=null, profile=00eaj00000TnZaFAAV, PSG_Service.
```

Post-switch verification:

```json
{"Id":"005aj00000gE0b3AAC","Username":"ngpersona.ngdemo@northgate.demo","UserRoleId":"00Eaj00000QCxlLEAT","UserRole":{"DeveloperName":"VP_Sales"},"ManagerId":null,"ProfileId":"00eaj00000TnZaFAAV","Profile":{"Name":"NG_Sales"},"IsActive":true}
{"users":[{"Id":"005aj00000gE0b3AAC","Username":"ngpersona.ngdemo@northgate.demo","role":"VP_Sales","active":true}],"count":1}
{"psgs":[{"id":"0Paaj000016mN4nCAE","psgId":"0PGaj000005miOsGAI","name":"PSG_Manager"}]}
```

- Role `VP_Sales` — CONFIRMED.
- Exactly one active VP_Sales user, `ngpersona` — CONFIRMED.
- ManagerId null — CONFIRMED.
- Profile `NG_Sales` — CONFIRMED.
- `PSG_Manager` retained; `PSG_Service` preserved — CONFIRMED.

## Setup result

Command: `sf apex run --target-org ng-demo --file scripts/uat/vp_setup.apex`

```text
VP_UAT_RESULT={"approvalUrl":"/p/process/ProcessInstanceWorkitemWizardStageManager?id=04iaj000003jdBZAAY","workItemActorId":"005aj00000gE0b3AAC","workItemId":"04iaj000003jdBZAAY","instanceId":"04gaj000001yGanAAE","approvalStatus":"Pending","netDiscountPercent":12.60,"rulesApplied":2,"adjustedSubtotal":322422.10,"listSubtotal":368904.00,"shareId":"00taj00000MxTvmAAF","quoteId":"0Q0aj000003kSijCAE","opportunityId":"006aj00000fb453AAA","contactId":"003aj00002WSnGrAAL","accountId":"001aj000046FWJpAAO","seed":"UAT-2026-10-20-VP-12PCT"}
```

## Opportunity

```json
{"Id":"006aj00000fb453AAA","Name":"UAT-2026-10-20 VP 12PCT","AccountId":"001aj000046FWJpAAO","StageName":"Prospecting","Amount":368904,"Discount_Percent__c":12.6,"Approval_Status__c":"Pending","OwnerId":"005aj00000feqbNAAQ","CreatedDate":"2026-10-20T03:27:25.000+0000","LastModifiedDate":"2026-10-20T03:27:26.000+0000"}
```

- Discount `12.60` — CONFIRMED.
- Approval status `Pending` — CONFIRMED.
- Owner is Arjun, not `ngpersona` — CONFIRMED.
- Stage `Prospecting`; Amount `368904` — CONFIRMED.

## Quote and CP2 pricing

```json
{"Id":"0Q0aj000003kSijCAE","Name":"UAT-2026-10-20 VP 12PCT - Quote","OpportunityId":"006aj00000fb453AAA","Subtotal":368904,"Adjusted_Subtotal__c":322422.1,"Rule_Applied_Count__c":2,"Status":"Draft","CreatedDate":"2026-10-20T03:27:26.000+0000"}
{"Id":"0QLaj000004exS5GAI","Product2":{"Name":"Aurelia LX 2020","ProductCode":"TRIM-001"},"Quantity":12,"UnitPrice":30742,"Subtotal":368904}
```

- List subtotal `368904.00` — CONFIRMED.
- Adjusted subtotal `322422.10` — CONFIRMED.
- Rules applied `2` — CONFIRMED.
- One Quote and one QuoteLineItem — CONFIRMED.

Pricing arithmetic:

```text
368904.00 * (1 - 0.05) = 350458.80
350458.80 * (1 - 0.08) = 322422.096 -> 322422.10
Net discount = 12.60%
```

Source rules:
`Price_Rule__mdt.Loyalty_Platinum_Discount` = 5%, `Loyalty_Tier=Platinum`.
`Price_Rule__mdt.Volume_Discount_Over_10` = 8%, `Volume > 10`, `Vehicle_Trim`.

- CP2 rule set matches the expected Platinum 5% and Volume 8% — CONFIRMED by pricing,
  rule count, and source metadata.

## Approval routing

```json
{"Id":"04gaj000001yGanAAE","Status":"Pending","ProcessDefinition":{"DeveloperName":"VP_Discount_Approval"},"TargetObjectId":"006aj00000fb453AAA","SubmittedById":"005aj00000feqbNAAQ","CreatedDate":"2026-10-20T03:27:27.000+0000"}
{"Id":"04iaj000003jdBZAAY","ActorId":"005aj00000gE0b3AAC","ProcessInstanceId":"04gaj000001yGanAAE","ProcessInstance":{"Status":"Pending","ProcessDefinition":{"DeveloperName":"VP_Discount_Approval"}}}
{"Id":"04haj000000sJNRAA2","ActorId":"005aj00000feqbNAAQ","StepStatus":"Started","CreatedDate":"2026-10-20T03:27:27.000+0000"}
```

- `VP_Discount_Approval` — CONFIRMED.
- Instance Pending — CONFIRMED.
- Work item actor `ngpersona` — CONFIRMED.
- Current step Started by submitter; no approval action taken — CONFIRMED.

## Sharing

```json
{"Id":"00taj00000MxTvmAAF","OpportunityId":"006aj00000fb453AAA","UserOrGroupId":"005aj00000gE0b3AAC","OpportunityAccessLevel":"Read","RowCause":"Manual"}
{"Id":"00taj00000MxTvlAAF","OpportunityId":"006aj00000fb453AAA","UserOrGroupId":"005aj00000feqbNAAQ","OpportunityAccessLevel":"All","RowCause":"Owner"}
```

- Exactly one manual share, `ngpersona` Read — CONFIRMED.
- Owner share is automatic — CONFIRMED.

## No unrelated modifications

Latest Opportunities by `LastModifiedDate`:

```text
006aj00000fb453AAA UAT-2026-10-20 VP 12PCT        2026-10-20T03:27:26Z
006aj00000faIjZAAU UAT-2026-10-19 MANAGER 8PCT    2026-10-20T03:11:02Z
006aj00000fZqFSAA0 UAT-2026-10-19 QUOTE           2026-10-19T19:30:20Z
```

Historical Manager Opportunity remains `8.92` / `Approved`; both historical Quotes remain at
their prior `LastModifiedDate` values. No unrelated Opportunity or Quote was modified after the
VP run.

## Owner action required

- Opportunity: https://orgfarm-25065ad46a-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006aj00000fb453AAA/view
- Approval work item: https://orgfarm-25065ad46a-dev-ed.develop.my.salesforce.com/p/process/ProcessInstanceWorkitemWizardStageManager?id=04iaj000003jdBZAAY
- Expected displayed discount: `12.60%`.
- Current Login As session must be **Northgate Persona**, not Arjun.
- Action: click **Approve** once.

No approval, rejection, restoration, deployment, commit, push, or historical cleanup has been
performed.
