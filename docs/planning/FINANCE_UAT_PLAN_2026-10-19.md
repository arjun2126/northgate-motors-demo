# Finance UAT Plan — 2026-10-19

## Purpose

Validate the one Finance approval decision that remains untested in `ng-demo`: a
`Manual_Exception` financing record submitted to `Q_Finance_Approvals` and approved by
`ngpersona` in the `Finance_Manager` persona.

Manager and VP approval decisions are already complete. This UAT does not repeat them,
does not re-test pricing, and does not change approval thresholds or process configuration.

## Current Authorized State

- Org: `ng-demo` only, `00Daj00001Ae3iWEAR`.
- User: `ngpersona.ngdemo@northgate.demo`, `005aj00000gE0b3AAC`.
- Current persona baseline: role `VP_Sales`, no persona permission set groups, `ManagerId`
  null, profile `NG_Sales`.
- Read-only inspection is complete. No Finance records, shares, approvals, or persona
  changes have been made.
- This plan and the local scripts are prepared but not executed.
- Live Finance actions require one consolidated owner approval before execution.
- No deployment, commit, push, or `ng-dev` access is authorized.

## What Is Already Proven

| Area | Evidence | Status |
|---|---|---|
| Manager discount approval | `evidence/UAT/live_2026-10-19/` | Complete |
| VP discount approval | `vp_uat_completed_2026-10-20.md` | Complete |
| Finance exception routing | `finance_probe.apex`, rolled back | PASS |
| Finance approval decision | none | Untested |
| Finance record access under Private OWD | source and existing records | Needs live verification |

The 2026-10-19 Finance probe proved the record routes to `Q_Finance_Approvals`. It was
rolled back, so it did not prove that a Finance Manager can open and approve the work item.

## Verified Configuration

- Approval process: `Financing_Exception_Approval`, `04aaj000003QUWzAAO`, Active.
- Queue: `Q_Finance_Approvals`, `00Gaj00000ZYezlEAD`, role member `Finance_Manager`,
  `DoesIncludeBosses=true`.
- Queue role membership is the Role group `00Gaj00000ZYezoEAD`, linked to the
  `Finance_Manager` role. Querying `GroupMember` by the role ID directly returns no row.
- Finance role: `Finance_Manager`, `00Eaj00000QC9uzEAD`.
- Finance permission set group: `PSG_Finance`, `0PGaj000005miOrGAI`, status `Updated`.
- `PSG_Finance` includes `PS_Finance_Officer`, which grants `Financing__c` create/read/
  edit/delete, Opportunity/Quote/Contact read, and the Finance Apex class access.
- No active `Finance_Manager` users currently exist. After switching `ngpersona`,
  `ngpersona` must be the only active Finance Manager.
- `Financing__c` sharing model is Private. The share object is `Financing__Share`
  (`ParentId`, `UserOrGroupId`, `AccessLevel`, `RowCause`).
- Account, Contact, and Opportunity sharing models are also Private. The scoped
  `OpportunityShare` and `ContactShare` are valid manual shares.
- Existing recent Financing records have only owner shares. Queue membership alone does
  not grant Financing record access.
- Standard Price Book is active: `01saj00000NvczOAAR`.
- Product entry: `Aurelia LX 2020`, `01taj00000YGzDhAAL`, `01uaj00000AVvlpAAD`.
- Org date at preparation: 2026-10-19. Time zone: `America/Toronto`. The org date may
  roll before execution; the approval decision date is dynamic (`TODAY()`).

## Finance Scenario

### Seed

`UAT-2026-10-19-FIN-EXCEPTION`

### Records

| Record | Value |
|---|---|
| Account | `UAT-2026-10-19 FIN Exception Household`, Type Household |
| Contact | `FIN UAT Buyer` |
| Opportunity | `UAT-2026-10-19 FIN Exception`, Stage `Financing`, Amount `30742` |
| Quote | 1 × Aurelia LX 2020, unit price `30742` |
| Financing | down `0`, tier `A`, term `60`, source `Manual_Exception`, rate `7.25%` |

### Expected Finance Values

- Amount financed: `30742.00`
- Annual rate: `7.25`
- Term: `60`
- Monthly payment: `612.36`
- Total interest: `5999.60`
- Rate source: `Manual_Exception`
- Status: `Draft`
- `Finance_Exception_Approved__c`: `false`
- `Decision_Date__c`: null
- Quote subtotal: `30742.00`
- Quote adjusted subtotal: `30742.00`
- Quote rules applied: `0`
- Quote net discount: `0.00`

### Access

Create exactly one manual Read share per record to `ngpersona`:

- `Financing__Share` on the Financing record.
- `OpportunityShare` on the Opportunity.
- `ContactShare` on the Contact.

No Account share, no queue configuration change, and no share on historical records.
The three shares are deliberately scoped to the new UAT records only. Queue membership
routes the approval; the shares make the record readable under Private OWD.

### Submission

Submit through `FinanceApplicationController.submitForExceptionApproval`, the existing
application path used by the Finance record quick action. Expected result:

- Process: `Financing_Exception_Approval`
- Status: `Pending`
- Exactly one work item
- Work item actor: `Q_Finance_Approvals`
- Financing remains `Draft`
- `Finance_Exception_Approved__c` remains `false`
- `Decision_Date__c` remains null

### Approval

The owner approves in the browser as `ngpersona` after `scripts/persona.sh finance`.
This is the actual untested step. Expected result:

- Process instance: `Approved`
- Approval step actor: Northgate Persona
- Work items: zero
- `Finance_Exception_Approved__c`: `true`
- `Decision_Date__c`: the org date at approval time (`TODAY()` in `America/Toronto`).
  At preparation this was `2026-10-19`; if the org date has rolled, expect the current
  org date. Do not use the seed label as the expected date.
- `Status__c`: remains `Draft`
- Quote and CP2 pricing unchanged
- Pending Finance approvals: zero

The existing process does not change `Status__c`. That is established behavior. This UAT
verifies the exception flag and decision date, not a Financing status transition. If the
desired business outcome is `Status__c = Approved`, that is a separate change and is not
authorized here.

## Required Local Scripts

### `scripts/uat/finance_setup.apex`

Creates and validates the scenario, applies the three scoped shares, submits the approval,
and prints `FIN_UAT_RESULT` with all IDs and URLs.

The script stops before DML if any of these are true:

- Seed already exists.
- A pending Finance approval or Finance queue work item exists.
- `ngpersona` is not the only active Finance Manager.
- `PSG_Finance` is not assigned.
- Queue role membership is missing.
- The approval process is not active.
- Standard Price Book or product entry is missing or mispriced.

The script stops after creation if any expected quote, financing, share, process, or work
item value differs.

### `scripts/uat/finance_pre_restore_guard.apex`

Read-only pre-restore guard. It fails if any pending `Financing_Exception_Approval`
process instance or any pending work item on `Q_Finance_Approvals` remains.

This guard is required because `scripts/persona.sh restore` currently checks approvals
submitted by `ngpersona` or work items assigned to `ngpersona`. The Finance work item is
queue-assigned and submitted by the admin, so the existing restore guard will not detect it.

A durable `persona.sh` fix is not applied in this plan. Use the explicit guard before every
restore. If a pending Finance item remains, stop and resolve it before restoring.

## Execution Sequence

1. Preflight read-only checks: confirm org, baseline, zero pending Finance approvals,
   `Q_Finance_Approvals`, `PSG_Finance`, and no existing seed.
2. Switch persona: `scripts/persona.sh finance`.
3. Run `sf apex run --target-org ng-demo --file scripts/uat/finance_setup.apex`.
4. Capture `FIN_UAT_RESULT`. Verify the record in Salesforce:
   - Financing `Draft`, flag false, decision null.
   - Amount, rate, term, payment, interest, rate source.
   - Quote `30742`, adjusted `30742`, zero rules.
   - Process `Pending`, one work item, actor `Q_Finance_Approvals`.
   - Three manual Read shares.
5. Stop and hand the work item to the owner.
6. Owner logs in as `ngpersona`, opens the approval URL, confirms the displayed values,
   and clicks Approve once. Do not reject, edit, or reassign.
7. Verify the post-approval state: process `Approved`, one completed step by Northgate
   Persona, zero work items, flag true, decision date equal to the org date at approval
   time (prepared expectation `2026-10-19`), status `Draft`, quote unchanged, zero pending
   Finance approvals.
8. Run `scripts/uat/finance_pre_restore_guard.apex`. It must print
   `FIN_PRE_RESTORE_GUARD` with `status: PASS`.
9. Restore: `scripts/persona.sh restore`.
10. Verify the baseline: role `VP_Sales`, no persona PSGs, `ManagerId` null, profile
    `NG_Sales`, no pending approvals.
11. Record evidence under `evidence/UAT/live_2026-10-19/`. Retain the UAT records and
    shares for audit; do not delete them.

## Browser Instructions

1. Owner logs in with Login As for `ngpersona` after the persona switch.
2. Confirm the displayed user is Northgate Persona, not Arjun.
3. Open the `approvalUrl` printed by the script, or open the Financing record and use the
   pending approval component.
4. Confirm the approval page shows:
   - Financing name containing `UAT-2026-10-19 FIN Exception`
   - Amount financed `30742`
   - Rate `7.25`
   - Term `60`
   - Monthly payment `612.36`
   - Rate source `Manual_Exception`
5. Click Approve once. Do not edit the record.
6. If the page shows insufficient privileges, no work item, different values, or a
   non-Draft status, stop and report. Do not approve as admin and do not switch personas
   to work around the problem.

## Risks and Stop Conditions

- **Restore guard gap:** `persona.sh restore` will not see the queue-assigned Finance work
  item. Run the explicit guard. Stop if it fails.
- **Status expectation:** approval sets the flag and date but leaves `Status__c = Draft`.
  Do not treat this as a failure of this UAT; do not manually change status.
- **Private record access:** queue membership is necessary but not sufficient. The three
  scoped shares are required. If the owner still cannot open the record, stop rather than
  adding broader shares.
- **Queue visibility delay:** role-based queue membership is usually immediate. If the work
  item is not visible, refresh or re-login once. If still absent, stop.
- **P3-DEF-01:** do not open Quote Builder or save another Quote on this Opportunity after
  submission. The setup creates the Quote before submission. No further Quote activity.
- **Approval submitter:** the setup script runs as admin; the work item is assigned to the
  queue. The owner must approve as `ngpersona`; admin approval would not validate the
  Finance Manager path.
- **Process criteria:** `Manual_Exception` matches the entry criteria. If the record
  auto-approves or bypasses the queue, stop; do not change the process.
- **No config changes:** no approval process, queue, role, PSG, OWD, or sharing-rule change
  is part of this UAT.

## Consolidated Approval Request

Approve these live actions in `ng-demo` only:

1. Switch `ngpersona` from `VP_Sales` to `Finance_Manager` and assign `PSG_Finance`.
2. Create the seeded Account, Contact, Opportunity, Quote, Quote Line, and Financing.
3. Insert exactly three scoped manual Read shares to `ngpersona`: Financing, Opportunity,
   Contact.
4. Submit one Finance exception approval to `Q_Finance_Approvals`.
5. Owner approves once as `ngpersona` in the browser.
6. Run the explicit pre-restore guard, restore `ngpersona` to the captured baseline, and
   verify zero pending Finance approvals.
7. Retain the UAT records and shares for audit.

This approval does not cover deployment, source changes, commits, pushes, `ng-dev`, other
orgs, deletion of historical records, or changes to approval thresholds/configuration.
