# Decision status index

Navigation only; do not duplicate ADRs or rewrite historical failed attempts. “Retain” means
preserve the existing decision, not newly verified live behavior. A proposed change requires a
demonstrated defect, exact evidence/impact and bounded owner approval.

| Decision | Status / constraint | Authoritative source |
|---|---|---|
| Permanent orgs, no scratch orgs | Retain; **never access or modify ng-dev**. ng-demo requires explicit approval. Old build-target/CI text is not executable authority. | [Agent rules](../../AGENTS.md), [governance](../GOVERNANCE.md), [org strategy](../architecture/ORG_STRATEGY.md) |
| No new project-owned backend Flows | Owner-ratified; preserve existing accepted appraisal Flow and native features | [Automation direction](../architecture/AUTOMATION_DIRECTION.md) |
| CP2 signed pricing and unambiguous primary vehicle | Retain precedence/winners, signed net including negative premium, zero-price guard and rounding | [CPQ seam](../architecture/SIMULATION_CPQ.md), handoff §3/§5 |
| Separate manager/VP discount processes | Retain >5–10% manager and >10% VP, individual actor derivation/tier guards, no self-approval; criteria-miss is not skip-next-step | [Handoff](../../NORTHGATE_PROJECT_HANDOFF.md) §3/§5 |
| Quote overwrite prevention | P3-DEF-01 historically completed; one-Quote guard retained. Older sibling/create-only instructions do not override the later guard. Never reprice historical CP2 exception rows. | [Current UAT register](../../evidence/UAT/FULL_PROJECT_2026-10-28/UAT_REGISTER.md), [repair plan](../planning/P3-DEF-01_QUOTE_OVERWRITE_FIX.md) |
| Customer vehicle capability broker | Approved/deployed per existing receipts; exact-time request authorization, whitelisted DTOs, independent service authority and idempotency; no native CRUD workaround or scheduled-expiry guarantee | [Broker amendment](../architecture/P8_NATIVE_VEHICLE_ACCESS_DECISION.md), [ledger](../architecture/P8_CONTACT_VEHICLE_OWNERSHIP.md) |
| Actual-persona security evidence | Retain System.runAs and browser identity checks; Admin success is not customer/department acceptance | [Agent lessons](../../AGENTS.md), [UAT orchestration](../planning/UAT_ORCHESTRATION.md) |
| Paid-product seams | Retain honest custom simulation vs native vs documentation-only labels; no new licensed product assumptions | [Architecture index](../architecture/OVERVIEW.md), [master plan](../../DEMO_ORG_MASTER_PLAN.md) §4 |
| Accepted exceptions / unresolved defects | P5/P6 exceptions retained; P7/P8 not fully accepted, D01–D14 remain scoped open dispositions, D15 closed. D08 deployment receipt does not close presentation UAT. | [Current UAT register](../../evidence/UAT/FULL_PROJECT_2026-10-28/UAT_REGISTER.md), [technical debt](../TECH_DEBT.md) |
| Vehicle Studio / Staff Workspace | Future proposal / new scope required; no implementation authorized by this harness | [Backlog](../../DEMO_ORG_BACKLOG.md), [execution guide](../../PLANS.md) |

If sources disagree, inspect the latest scoped owner decision and raw receipt rather than the
oldest header. Record uncertainty and ask; do not silently migrate historical plans or broaden approval.
