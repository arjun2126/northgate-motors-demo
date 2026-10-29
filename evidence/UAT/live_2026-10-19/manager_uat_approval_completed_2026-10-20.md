# Manager UAT approval completed — 2026-10-20

**Org:** ng-demo only (`00Daj00001Ae3iWEAR`).
**Opportunity:** `006aj00000faIjZAAU` — UAT-2026-10-19 MANAGER 8PCT.
**Approval instance:** `04gaj000001yDbJAAU`.

## Verification results

### ProcessInstance

| Field | Value |
|---|---|
| Status | Approved |
| TargetObjectId | 006aj00000faIjZAAU |
| CreatedDate | 2026-10-19T21:56:43Z |
| CompletedDate | 2026-10-20T03:11:02Z |
| LastActorId | 005aj00000gE0b3AAC |
| LastActor | Northgate Persona |
| SubmittedBy | Arjun Subramanya |

### Approval steps

| Step | Actor | CreatedDate | Comments |
|---|---|---|---|
| Started | Arjun Subramanya (`005aj00000feqbNAAQ`) | 2026-10-19T21:56:43Z | Discount requires approval. |
| Approved | Northgate Persona (`005aj00000gE0b3AAC`) | 2026-10-20T03:11:02Z | — |

### Work item

- `04iaj000003jMc9AAE`: no rows returned by Id.
- Work items for `04gaj000001yDbJAAU`: 0 rows.
- Work items org-wide: 0 rows.
- Result: resolved.

### Opportunity

| Field | Value |
|---|---|
| Discount_Percent__c | 8.92 |
| Approval_Status__c | Approved |
| StageName | Prospecting |
| Amount | 100000 |
| LastModifiedDate | 2026-10-20T03:11:02Z |
| LastModifiedBy | Northgate Persona |

### Quotes preserved

| Quote | CreatedDate | Subtotal | Adjusted_Subtotal__c | Rule_Applied_Count__c |
|---|---|---|---|---|
| `0Q0aj000003kJNhCAM` (original) | 2026-10-19T21:56:42Z | 338162 | 307997.95 | 2 |
| `0Q0aj000003kQgwCAE` (accidental second) | 2026-10-20T02:40:27Z | 33607 | 33270.93 | 1 |

Both Quotes remain. None deleted or modified.

### Pending approvals

- `ProcessInstance` with `Status = 'Pending'`: 0.
- `ProcessInstanceWorkitem`: 0.
- Result: zero pending approvals and zero pending work items before any subsequent persona switch.

### Temporary ManagerId

- Before restore: `arjun` (`005aj00000feqbNAAQ`) `ManagerId = 005aj00000gE0b3AAC` (Northgate Persona).
- Restore performed with Apex: `User.ManagerId = null`.
- After restore: `ManagerId = null`, verified by query.
- No persona switch was performed.

### OpportunityShare

Retained:

- `00taj00000MwzpdAAB`: Northgate Persona, Read, Manual.
- Owner share: Arjun Subramanya, All, Owner.

## Remaining discrepancies

1. Accidental Quote `0Q0aj000003kQgwCAE` still exists at 1.00%, preserved by instruction.
2. `QuoteBuilderController` overwrite defect remains in the backlog as `P3-DEF-01`. Proposed fix is documented but not deployed.
3. Temporary `OpportunityShare` `00taj00000MwzpdAAB` remains in place pending the owner's decision.
4. `arjun.ManagerId` is restored to null. Any future Manager-route UAT must temporarily set it again; it is not currently configured.

## Readiness

Manager UAT path is complete: 8.92% discount, approval by Northgate Persona, `Approval_Status__c = Approved`, zero pending approvals/work items. Ready for the next UAT persona once the owner authorizes the persona switch and decides whether to keep the temporary OpportunityShare.

## Constraints observed

- No persona switch.
- No code deploy, commit, or push.
- No Quote deletion or modification.
- No access to ng-dev.
- No unrelated record changes.
