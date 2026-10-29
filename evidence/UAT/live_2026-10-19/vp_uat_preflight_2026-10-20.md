# VP UAT preflight — 2026-10-20

**Status:** Read-only. No persona switch, record creation, share insert, approval submission,
deployment, commit, or push.

## Org and pending approvals

- Org: ng-demo, `00Daj00001Ae3iWEAR`.
- Pending `ProcessInstance`: 0.
- Pending `ProcessInstanceWorkitem`: 0.

## Persona state

- `ngpersona` (`005aj00000gE0b3AAC`) currently: role `Sales_Manager_Airport`,
  `PSG_Manager`, ManagerId null, profile `NG_Sales`.
- Baseline `evidence/UAT/persona_baseline.json`, captured `2026-10-19T19:01:25Z`:
  role `VP_Sales`, no persona PSGs, ManagerId null, profile `NG_Sales`.
- No active user currently has the `VP_Sales` role.
- `VP_Discount_Approval` is active: `04aaj000003QUX1AAO`.
- `Opportunity` sharing model: Private (internal and external).

## Persona dry-runs

`scripts/persona.sh --dry-run vp`:

```text
Org: ng-demo (00Daj00001Ae3iWEAR) CONFIRMED
User: ngpersona.ngdemo@northgate.demo (005aj00000gE0b3AAC) CONFIRMED
Current role: Sales_Manager_Airport (00Eaj00000QCxlNEAT)
Current persona PSGs: PSG_Manager
Target persona: vp -> role VP_Sales (00Eaj00000QCxlLEAT), PSG PSG_Manager (0PGaj000005miOsGAI, status Updated)
Would UPDATE ROLE: Sales_Manager_Airport -> VP_Sales (00Eaj00000QCxlLEAT)
Would PRESERVE: ManagerId=null, profile=00eaj00000TnZaFAAV, PSG_Service, unrelated permission sets.
DRY RUN: no Salesforce DML performed.
```

`scripts/persona.sh --dry-run restore`:

```text
Baseline: evidence/UAT/persona_baseline.json
Would RESTORE ROLE: Sales_Manager_Airport -> VP_Sales (00Eaj00000QCxlLEAT)
Would ENSURE baseline PSGs: <none>
Would DELETE non-baseline PSGs: PSG_Manager
Would PRESERVE: ManagerId=null, profile=00eaj00000TnZaFAAV, PSG_Service.
DRY RUN: no Salesforce DML performed.
```

## Proposed scenario values

- Product: `Aurelia LX 2020` (`01taj00000YGzDhAAL`), unit price 30742.
- Quantity: 12.
- List subtotal: 368904.00.
- Expected rules: Platinum loyalty 5%, Volume >10 8%.
- Expected adjusted subtotal: 322422.10.
- Expected net discount: 12.60%.
- Expected rules applied: 2.
- Expected approval route: `VP_Discount_Approval`.
- Expected approver: `ngpersona`, after temporary VP_Sales switch.

## Proposed records and access

One new Account, Contact, Platinum Loyalty_Member, Opportunity, Quote/QuoteLineItem,
scoped `OpportunityShare` (ngpersona, Read, Manual), and one approval submission.
No historical record is modified. The existing Manager UAT share is untouched.

## Files prepared

- `scripts/uat/vp_setup.apex` (not executed).
- `docs/planning/VP_UAT_PLAN_2026-10-20.md`.
