# Manager UAT record correction — 2026-10-20

**Scope:** ng-demo only. Opportunity `006aj00000faIjZAAU`.
**Authorization:** owner-approved correction of two fields only.

## Pre-write verification

Read-only pricing evaluation of original Quote `0Q0aj000003kJNhCAM`:

- listSubtotal: 338162.00
- adjustedSubtotal: 307997.95
- netDiscountPercent: 8.92
- rulesApplied: 2 (`Loyalty_Bronze_Discount` 1%, `Volume_Discount_Over_10` 8%)
- blockerMessage: null

Approval state before write:

- ProcessInstance `04gaj000001yDbJAAU`: Status `Pending`, CreatedDate `2026-10-19T21:56:43Z`, LastActorId null.
- Work item `04iaj000003jMc9AAE`: ActorId `005aj00000gE0b3AAC` (Northgate Persona), CreatedDate `2026-10-19T21:56:43Z`, IsDeleted `false`.
- ProcessInstanceStep: `Started`, ActorId `005aj00000feqbNAAQ` (Arjun), OriginalActorId `005aj00000feqbNAAQ`, CreatedDate `2026-10-19T21:56:43Z`.

## Before values

Opportunity `006aj00000faIjZAAU`:

| Field | Value |
|---|---|
| Discount_Percent__c | 1 |
| Approval_Status__c | Not_Required |
| StageName | Prospecting |
| Amount | 100000 |
| LastModifiedDate | 2026-10-20T02:40:28Z |
| LastModifiedById | 005aj00000feqbNAAQ (Arjun Subramanya) |

Original Quote `0Q0aj000003kJNhCAM`:

| Field | Value |
|---|---|
| Subtotal | 338162 |
| Adjusted_Subtotal__c | 307997.95 |
| Rule_Applied_Count__c | 2 |
| LastModifiedDate | 2026-10-19T21:56:43Z |

## Write performed

```text
sf data update record --target-org ng-demo --sobject Opportunity \
  --record-id 006aj00000faIjZAAU \
  --values "Discount_Percent__c=8.92 Approval_Status__c=Pending"
```

Result: `success: true`, no errors.

## After values

Opportunity `006aj00000faIjZAAU`:

| Field | Value |
|---|---|
| Discount_Percent__c | 8.92 |
| Approval_Status__c | Pending |
| StageName | Prospecting |
| Amount | 100000 |
| LastModifiedDate | 2026-10-20T03:03:04Z |
| LastModifiedById | 005aj00000feqbNAAQ (Arjun Subramanya) |

Original Quote `0Q0aj000003kJNhCAM` unchanged:

- Subtotal 338162
- Adjusted_Subtotal__c 307997.95
- Rule_Applied_Count__c 2
- LastModifiedDate 2026-10-19T21:56:43Z

## Approval state after write

- ProcessInstance `04gaj000001yDbJAAU`: Status `Pending`, CreatedDate `2026-10-19T21:56:43Z`, LastActorId null.
- Work item `04iaj000003jMc9AAE`: unchanged Id, ActorId `005aj00000gE0b3AAC`, CreatedDate `2026-10-19T21:56:43Z`, IsDeleted `false`.
- Actor check: Northgate Persona, IsActive `true`, role `Sales Manager - Airport`.
- ProcessInstanceStep: unchanged.

## Side-effect check

Compared all 63 Opportunity fields before and after. Only these changed:

| Field | Before | After | Cause |
|---|---|---|---|
| Approval_Status__c | Not_Required | Pending | intended |
| Discount_Percent__c | 1 | 8.92 | intended |
| LastReferencedDate | 2026-10-20T02:51:58Z | 2026-10-20T03:03:04Z | platform timestamp |
| LastViewedDate | 2026-10-20T02:51:58Z | 2026-10-20T03:03:04Z | platform timestamp |

Quote, ProcessInstance, ProcessInstanceWorkitem and ProcessInstanceStep comparisons are unchanged.

## Quote inventory

No Quote was created, deleted or modified. Still present:

- `0Q0aj000003kJNhCAM` — original 8.92% Quote.
- `0Q0aj000003kQgwCAE` — accidental 1.00% Quote created at 02:40:27Z, left untouched.

## Work item actionable

Yes. The work item is `Pending`, not deleted, and assigned to an active user with the
`Sales Manager - Airport` role. Direct approval page:

`https://orgfarm-25065ad46a-dev-ed.develop.my.salesforce.com/p/process/ProcessInstanceWorkitemWizardStageManager?id=04iaj000003jMc9AAE`

## Constraints observed

- No code deployed.
- No persona switched.
- No commit or push.
- No Quote created, deleted or modified.
- No approval resubmitted or decided.
- No unrelated records changed.

## Evidence files

- `manager_record_correction_before.json`
- `manager_record_correction_after.json`
