# VP Approval UAT plan — 2026-10-20

**Status:** Prepared for owner review. No live persona switch, no record creation, no
approval submission, no share creation, no deployment, no commit, no push.

## Readiness

- Org: ng-demo only, `00Daj00001Ae3iWEAR`.
- Pending `ProcessInstance`: 0.
- Pending `ProcessInstanceWorkitem`: 0.
- `VP_Discount_Approval` is active in the org: `04aaj000003QUX1AAO`.
- `Opportunity_Discount_Approval` caps at `<= 10`; `VP_Discount_Approval` is `> 10`.
- No active user currently has the `VP_Sales` role. After the temporary switch,
  `ngpersona` is the sole VP_Sales user.
- Private Opportunity OWD confirmed: `InternalSharingModel = Private`,
  `ExternalSharingModel = Private`. A manual share is required for the VP to open the record.

## Persona baseline and restore

Baseline file: `evidence/UAT/persona_baseline.json`, captured `2026-10-19T19:01:25Z`.

| Field | Baseline |
|---|---|
| User | `ngpersona.ngdemo@northgate.demo` (`005aj00000gE0b3AAC`) |
| Role | `VP_Sales` (`00Eaj00000QCxlLEAT`) |
| ManagerId | null |
| Profile | `NG_Sales` (`00eaj00000TnZaFAAV`) |
| Persona PSGs | none |

Current state before VP UAT:

| Field | Current |
|---|---|
| Role | `Sales_Manager_Airport` (`00Eaj00000QCxlNEAT`) |
| ManagerId | null |
| Profile | `NG_Sales` |
| Persona PSG | `PSG_Manager` |

Dry-run `scripts/persona.sh --dry-run vp`:

```text
Current role: Sales_Manager_Airport
Current persona PSGs: PSG_Manager
Target persona: vp -> role VP_Sales, PSG PSG_Manager
Would UPDATE ROLE: Sales_Manager_Airport -> VP_Sales
Would PRESERVE: ManagerId=null, profile=00eaj00000TnZaFAAV, PSG_Service, unrelated permission sets.
DRY RUN: no Salesforce DML performed.
```

Dry-run `scripts/persona.sh --dry-run restore`:

```text
Baseline: evidence/UAT/persona_baseline.json
Would RESTORE ROLE: Sales_Manager_Airport -> VP_Sales
Would ENSURE baseline PSGs: <none>
Would DELETE non-baseline PSGs: PSG_Manager
Would PRESERVE: ManagerId=null, profile=00eaj00000TnZaFAAV, PSG_Service.
DRY RUN: no Salesforce DML performed.
```

**Conclusion:** the VP switch preserves the captured baseline, and `restore` returns
`ngpersona` to the baseline role `VP_Sales` with no managed PSGs. It does not restore the
Manager persona, because the captured baseline predates the Manager UAT. The temporary
`PSG_Manager` is removed on restore.

## Proposed UAT scenario

New records only. No historical Opportunity or Quote is touched.

| Entity | Proposed value |
|---|---|
| Account | `UAT-2026-10-20 VP 12PCT Household`, Type Household, `Seed_Tag__c = UAT-2026-10-20-VP-12PCT` |
| Contact | `VP UAT Buyer` under the new Account |
| Loyalty | `Platinum`, `Active` for the new Contact |
| Opportunity | `UAT-2026-10-20 VP 12PCT`, Stage Prospecting, CloseDate +30 days, Amount 368904 |
| Quote product | `Aurelia LX 2020` (`01taj00000YGzDhAAL`), unit price 30742, quantity 12 |
| Quote lines | 1 Vehicle_Trim line |
| OpportunityShare | `ngpersona` Read, Manual, scoped to the new Opportunity only |

### Expected pricing, from existing CP2 rules

- List subtotal: `12 × 30742 = 368904.00`
- `Loyalty_Platinum_Discount`: 5%
- `Volume_Discount_Over_10`: 8% (higher-priority volume rule; Fleet 5% loses the category)
- No vehicle basis, so Trim/Age rules do not qualify
- Adjusted subtotal: `322422.10`
- Net discount: `12.60%`
- Rules applied: `2`
- `QuoteBuilderController.createQuote` stamps `Discount_Percent__c = 12.60` and
  `Approval_Status__c = Pending`; the approval fields are not edited manually.

### Expected approval

- Process selected: `VP_Discount_Approval` (entry `Discount_Percent__c > 10`).
- Work item actor: `ngpersona` (`005aj00000gE0b3AAC`), sole active VP_Sales user.
- Approval page fields: Name, Discount Percent, Amount, Stage, Sales Staff (and Owner if
  present in the live page layout).
- After Approve: ProcessInstance `Approved`; Opportunity `Approval_Status__c = Approved`;
  Discount remains `12.60`; work item resolved.

## Exact proposed live sequence

1. Preflight immediately before any write:
   - `SELECT Id FROM ProcessInstance WHERE Status = 'Pending'` returns 0.
   - `SELECT Id FROM ProcessInstanceWorkitem` returns 0.
   - `scripts/persona.sh --dry-run vp` and `--dry-run restore` still succeed.
2. Switch the persona:
   - `scripts/persona.sh vp`
   - Expected: role `Sales_Manager_Airport` -> `VP_Sales`; `PSG_Manager` stays; ManagerId,
     profile, and `PSG_Service` unchanged.
   - Verify exactly one active `VP_Sales` user and that it is `ngpersona`.
3. Create the scenario and submit the approval in one transaction:
   - `sf apex run --target-org ng-demo --file scripts/uat/vp_setup.apex`
   - The script creates Account, Contact, Loyalty, Opportunity, Quote, QuoteLineItem,
     OpportunityShare, and the approval submission.
   - It asserts 12.60%, 368904 / 322422.10 / 2 rules, `Pending`, the VP route, the sole
     `ngpersona` work item, and a Manual/Read share.
   - It prints `VP_UAT_RESULT={...}` with all new IDs and the approval URL.
   - On any assertion failure, the anonymous Apex transaction rolls back. Do not retry
     blindly; verify for partial records and report.
4. Verify the new record before browser approval:
   - Opportunity: `Discount_Percent__c = 12.60`, `Approval_Status__c = Pending`.
   - Quote: `Subtotal = 368904`, `Adjusted_Subtotal__c = 322422.10`,
     `Rule_Applied_Count__c = 2`.
   - ProcessInstance: `VP_Discount_Approval`, `Pending`.
   - Work item: actor `ngpersona`, `IsDeleted = false`.
   - Share: `OpportunityAccessLevel = Read`, `RowCause = Manual`, only on the new Opportunity.
5. Browser approval:
   - Log in as `ngpersona` in the VP persona.
   - Open the approval URL printed by the script:
     `https://orgfarm-25065ad46a-dev-ed.develop.my.salesforce.com/p/process/ProcessInstanceWorkitemWizardStageManager?id=<workItemId>`
   - Confirm Name `UAT-2026-10-20 VP 12PCT`, Discount `12.60`, Amount `368904`,
     Stage `Prospecting`. Click Approve.
   - Do not open Quote Builder and do not edit the Opportunity.
6. Post-approval verification:
   - ProcessInstance `Approved`, `CompletedDate` set, `LastActor = Northgate Persona`.
   - Approval step `Approved`, actor `ngpersona`.
   - Work item: 0 rows.
   - Opportunity: `Approval_Status__c = Approved`, `Discount_Percent__c = 12.60`.
   - Pending approvals and work items org-wide: 0.
7. Restore persona:
   - `scripts/persona.sh restore`
   - Expected: role back to `VP_Sales`, baseline PSGs none, `PSG_Manager` removed,
     ManagerId null, profile `NG_Sales`, `PSG_Service` preserved.
   - Verify role and PSG assignments after restore.
8. Keep all UAT records. Do not delete the new Account, Contact, Loyalty, Opportunity,
   Quote, share, or approval history unless separately authorized.

## Private OWD and VP access

`Opportunity` is Private internally and externally. The VP persona is not the record owner,
so record access is not inherited. The approval work item alone does not create a record
share.

Required manual share, scoped only to the new Opportunity:

```apex
OpportunityShare share = new OpportunityShare(
    OpportunityId = newOpportunity.Id,
    UserOrGroupId = '005aj00000gE0b3AAC',
    OpportunityAccessLevel = 'Read'
);
insert share;
```

The setup script creates and verifies this share. The historical Manager UAT share
`00taj00000MwzpdAAB` is not reused, modified, or removed.

## P3-DEF-01 guard

`QuoteBuilderController.createQuote` still overwrites Opportunity `Discount_Percent__c` and
`Approval_Status__c` on every Quote Builder save. The permanent fix is in the backlog and is
not deployed.

For this UAT:

- Create the Quote and submit the approval in one scripted transaction.
- After submission, do not open Quote Builder, click Save, or run any quote recalculation on
  the new Opportunity.
- Use only the approval page for the VP decision.
- If the scenario needs correction before approval, recall or abandon it and create a fresh
  Opportunity; do not repair a pending record through Quote Builder.
- If any overwrite is observed, stop and report; do not patch the record.

## Failure and rollback

- Setup failure: expect transaction rollback; verify no partial records; stop and report.
- Approval failure: do not edit the pending record; owner decides recall/abandon.
- Restore failure: stop; do not run another switch; follow `persona.sh` runbook and report.
- No deletion of historical or new UAT records is part of this plan.

## Consolidated approval request

Approve these live changes in ng-demo only:

1. Temporarily switch `ngpersona` from `Sales_Manager_Airport` to `VP_Sales` with
   `scripts/persona.sh vp`.
2. Run `scripts/uat/vp_setup.apex` once to create the new UAT Account, Contact, Platinum
   loyalty, Opportunity, Quote/line, scoped Read share, and submit the >10% approval.
3. Owner logs in as `ngpersona` and approves the new work item in the browser.
4. Run `scripts/persona.sh restore` after the approval is resolved and zero approvals remain.

No deploy, no commit, no push, no ng-dev access, no historical record modification.
