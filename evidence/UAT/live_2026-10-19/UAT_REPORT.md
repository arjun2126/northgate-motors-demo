# Northgate Motors — Live End-to-End UAT Report (ng-demo)

Date: 2026-10-19. Org: `ng-demo` (`00Daj00001Ae3iWEAR`). Owner authorized live UAT with
mandatory restoration of `ngpersona` to the `VP_Sales` baseline.

## Preflight (all CONFIRMED)

| Check | Result |
|---|---|
| Org alias / ID | `ng-demo` / `00Daj00001Ae3iWEAR` |
| User | `ngpersona.ngdemo@northgate.demo` / `005aj00000gE0b3AAC`, active |
| Baseline file | matches live: role `VP_Sales`, `ManagerId` null, profile `00eaj00000TnZaFAAV`, no persona PSGs |
| Pending approvals before start | 0 |
| PSGs | `PSG_Rep`, `PSG_Manager`, `PSG_Finance`, `PSG_Service` all `Updated` |
| Queues | `Q_Finance_Approvals`, `Q_Inbound_Leads`, `Q_Service_Intake` present |
| Approval processes | `Financing_Exception_Approval`, `Opportunity_Discount_Approval`, `VP_Discount_Approval` all `Active` |

## Persona transitions (CONFIRMED)

| Time (UTC) | Action | Role | PSGs |
|---|---|---|---|
| 19:28:40 | switch:rep | `Sales_Rep` | `PSG_Rep` |
| 19:33:46 | switch:vp | `VP_Sales` | `PSG_Manager` |
| 19:34:57 | switch:finance | `Finance_Manager` | `PSG_Finance` |
| 19:36:06 | restore | `VP_Sales` | none |

Partial-failure recovery exercised live: a `vp` switch failed on a transient `fetch failed` while
deleting `PSG_Rep`; the script performed automatic restore and re-verified the baseline. The next
`vp` switch succeeded. `ManagerId`, profile, and `PSG_Service` were preserved throughout.

## Workflow results

| Workflow | Result | Evidence |
|---|---|---|
| Sales Rep persona runtime permissions (FLS/visibility) | BLOCKED | `System.runAs` is test-only; no logged-in `ngpersona` browser session. Requires owner Login As. |
| Controlled records created | PASS | Account `001aj0000467u6PAAQ`, Contact `003aj00002WPAQXAA5`, Opportunity `006aj00000fZqFSAA0`, Delivery `a03aj00002WPAQYAA5`, Test Drive `a0Aaj00000G7oA9EAJ`, Trade-In `a0Baj00001NTVYvEAP`, Loyalty Member `a05aj00000gJUS1AAO` |
| Quote Builder create/persist (CP2) | BLOCKED | `Standard Price Book is not active. Activate it before creating quotes.` Standard Price Book `01saj00000NvczOAAR` has `IsActive=false`; `getCatalog('Vehicle_Trim')` returned 0 |
| CP2 pricing engine exact-match | PASS | Live `QuotePricingService.evaluate` on `Q-0058` (`0Q0aj000003jGHWCA2`): list 55829.00; `Aged_Inventory_Discount_90` -15% = 8374.35; `Trim_Premium_Premium` +5% = 2372.73; adjusted 49827.38; net 10.75%; basis identified, no blocker |
| Manager 5-10% approval route | BLOCKED | `QuoteBuilderController.submitForApproval` returned `No manager found for the submitter.` `ManagerId` is null and was not changed |
| VP >10% routing | PASS | Active VP query returns only `005aj00000gE0b3AAC`; probe submitted instance `04gaj000001yCVZAA2`, work item actor = `005aj00000gE0b3AAC` |
| VP fail-closed with no active VP | PASS | `No VP approver available.` while persona was `rep` |
| Finance exception routing | PASS | Probe submitted instance `04gaj000001yCXBAA2`; work item actor `00Gaj00000ZYezlEAD` = queue `Q_Finance_Approvals` |
| Approval decision (manager/VP/finance) | BLOCKED | Decision must run as the persona; requires owner Login As. Probes were rolled back, so no pending approvals were left |
| Delivery completion -> Closed Won | PASS | Delivery `a03aj00002WPAQYAA5` Completed; checklist complete; `Completed_Date__c` 2026-10-19; Opportunity stage `Closed Won`, `Delivery_Completed__c=true` |
| Loyalty enrollment | PASS | `Loyalty_Member__c` `a05aj00000gJUS1AAO`, tier Bronze, created by delivery automation |
| Dashboards for ngpersona | OWNER ACTION REQUIRED | Dashboard folder shared to `PG_All_Sales`, but `PG_All_Sales` has 0 members; membership add not authorized |
| Reports for ngpersona | OWNER ACTION REQUIRED | `NG_01_Pipeline`/`NG_02_Leads` report folders shared to `arjun` only; report-folder sharing not authorized |

## CP2 pricing evidence

```
quoteId            0Q0aj000003jGHWCA2  (Q-0058 – Nguyen Household – Purchase 68)
model              Cascadia Premium 2024
trim               Premium
ageDays            322
listSubtotal       55829.00
Aged_Inventory_Discount_90   15.00%  base 55829.00   adjustment -8374.35
Trim_Premium_Premium          5.00%  base 47454.65  adjustment +2372.73
adjustedSubtotal   49827.38
netDiscountPercent 10.75
vehicleBasisIdentified true
rulesApplied       2
```

## Security and visibility findings

- Config-only: Opportunity/Account/Contact/Lead/Financing OWD Private; Quote ControlledByParent;
  Delivery/Loyalty ReadWrite. `PS_Sales_Manager` has no `viewAllRecords`. CONFIRMED via Tooling.
- Runtime persona visibility not verified (no persona session).
- No OWD, sharing, queue, public-group, or `ManagerId` changes were made.

## Regressions

None observed. Object counts after UAT: Financing 62 (unchanged), Quote 60 (unchanged), Delivery
13 (12 + 1 UAT), Loyalty 71 (70 + 1 UAT), Opportunity 132 (131 + 1 UAT). All deltas are the
controlled UAT records; no unintended side effects.

## Rollback / cleanup state

- `ngpersona`: role `VP_Sales`, `ManagerId` null, profile `00eaj00000TnZaFAAV`, no persona PSGs. CONFIRMED.
- Exactly one active VP (`ngpersona`); VP routing available. CONFIRMED.
- Pending approvals after UAT: 0. CONFIRMED.
- Baseline file SHA256 `e62b6a75f5e0757b99a93a0d0e1a197abfe45987`, unchanged. CONFIRMED.
- UAT business records were intentionally not deleted.

## Owner actions still required

1. Activate the Standard Price Book (`01saj00000NvczOAAR`) to enable Quote Builder create/persist.
2. Provide a logged-in `ngpersona` session (Setup Login As or credentials) to execute rep/manager/
   VP/finance UI and approval decisions, and to capture screenshots.
3. If manager-route validation is required, authorize a `ManagerId` change for `ngpersona` (minimum
   additional configuration); the controller throws `No manager found for the submitter.` until then.
4. Authorize `PG_All_Sales` membership (and optionally report-folder shares) for dashboard/report
   visibility as `ngpersona`.

## 2026-10-20 status addendum (supersedes stale owner actions)

| 2026-10-19 blocker | Current status |
|---|---|
| Standard Price Book inactive | RESOLVED. `01saj00000NvczOAAR` is active; 30 active `Vehicle_Trim` entries; zero at price 0. Quote Builder can create and price. |
| No logged-in persona session | Manager, VP, and Finance approval decisions completed in the browser as `ngpersona`; persona restored `2026-10-20T04:26:29Z`. Sales Rep browser UAT remains pending owner Login As. |
| Manager approval blocked by null `ManagerId` | RESOLVED for the completed UAT. Manager approval `04gaj000001yDbJAAU` is Approved. `ManagerId` was restored to null. |
| `PG_All_Sales` empty | RESOLVED. `PG_All_Sales` `00Gaj00000ZYYhUEAX` contains `ngpersona`. Source folder metadata shares View to the group; live `FolderShare` rows are not queryable via SOQL. |
| Reports/dashboards not visible | Source shares updated and group membership confirmed. Live folder-share rows are not proven because SOQL returns `sObject type 'FolderShare' is not supported.` |

Still open:

- Sales Rep browser UAT (`scripts/uat/rep_setup.apex`, Login As, `scripts/uat/rep_verify.apex`).
- `P3-DEF-01`: local fix written; not deployed or tested.
- Phase 2 UAT sign-off: unverified.
- P4-10 dashboard screenshot and P4-10..P4-13 closure sign-off.
- Finance pre-restore guard: run `scripts/uat/finance_pre_restore_guard.apex` before every restore.

Current consolidated record: `docs/planning/PRE_PHASE5_READINESS_2026-10-20.md`.
