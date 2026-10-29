# Phase 6 Batch 4 — bounded local implementation

Owner authorizes P6-13–P6-17 local implementation, isolated tests and exact check-only against
ng-demo (`00Daj00001Ae3iWEAR`). No deployment, persistent records, assignments, publication,
page activation, scheduling or Git publication. Preserve all earlier batches and dirty files.

## Dependencies and file-level implementation

- P6-13: `docs/architecture/SIMULATION_NURTURE.md` documents the deployed consent services,
  permission boundary, retained suppression and absent Marketing Cloud/sender/scheduler features.
- P6-14: new named native milestone types and opt-in Platinum Care entitlement process; use
  existing Default business hours (4 and 48 business hours, not elapsed time). No default process
  replacement or automatic entitlement assignment. A new Case field and thin Case trigger/service
  complete only this process's milestones after an explicitly recorded first response or closure.
  New unassigned layout/page and restricted read/report metadata expose native evidence.
- P6-15: prepare ten reviewed local article drafts and category mapping. Live Knowledge settings
  explicitly return `enableKnowledge=false`; `Knowledge__kav` and CaseArticle are absent. Enabling
  Knowledge is an owner-controlled feature decision, not an authorized reversible metadata repair.
  Do not enable it, fabricate native Knowledge, create records or publish. Ship the complete local
  article pack and gated import specification; native import/search/Case attachment remain blocked.
- P6-16: add separate Sales/Service Console applications and an unassigned app-only permission set.
  Preserve current apps, users, object grants and accepted Sales action overrides. No page activation.
- P6-17: new isolated native milestone lifecycle/bulk/persona tests; run relevant prior regressions
  and separately capture actual coverage on deployed accrual/tier/redemption/capacity implementations.

Exact package: `manifest/p6-batch4-check.xml`. Knowledge content is data, not deployable metadata;
it stays outside the package. No Knowledge feature settings change is included. Browser/timer,
Knowledge readiness, real personas and earlier live acceptance remain explicitly deferred.
