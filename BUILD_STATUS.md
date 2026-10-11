# Build Status — Northgate Motors demo org

Target org: **ng-dev only** (`arjun.ngdev@northgate.demo`). Never touch ng-demo or other orgs.
CLI: @salesforce/cli 2.153.5. sourceApiVersion 67.0, org API 68.0.

Working and escalation rules live in `AGENTS.md` at the repository root and apply to every agent in every session.

## Phase 1 — DONE (commit `dba455b`)

Phase 1 complete and exit report written (`evidence/P1/phase1_exit_report.md`).
CI green: `validate.yml` run 37718718354 PASS.
All blockers resolved. Users created; PSGs assigned; persona switch verified.

## Phase 2 — DONE (M1 gate passed, tag `demo/v0.1`)

End-to-end vertical slice: web lead → qualification → test drive → opportunity,
with automation, reports and tests. First demoable state.

M1 gate passed: dry-run clean, tests 100%, DQ 0 rows, UAT_P2 signed, tag `demo/v0.1` pushed.

## Phase 3 — NEXT

**Start here next session.** Read these first:

1. `DEMO_ORG_BACKLOG.md` — Phase 3 items P3-01 through P3-12 (Trade-in, quoting, simulated CPQ)
2. `DEMO_ORG_MASTER_PLAN.md` §4.4 — simulation seam notes for CPQ, Loyalty, Finance
3. `DEMO_ORG_DATA_MODEL.md` §8 — Trade_In__c, Price_Rule__mdt, Rate_Table__mdt, Quote objects
4. `docs/TECH_DEBT.md` — round-robin cross-transaction limitation (accepted exception)
5. `force-app/main/default/objects/` — Trade_In__c, Price_Rule__mdt, Rate_Table__mdt, Quote objects already in source

**Key dependencies to resolve before P3-01:**
- `Staff__c` records must exist (currently 0) for `Opportunity.Sales_Staff__c` lookups in quotes
- `Price_Rule__mdt` records (≥10) per backlog P3-03
- `Rate_Table__mdt` records for credit tier → rate mapping
- `Quote` object + `QuoteLineItem` in org (standard objects)

**Open decisions (owner approval required before P3 start):**
- Round-robin durable rotation: implement or keep exception (TECH_DEBT.md)
- `Staff__c` record creation + ownership + sharing for quote ownership
- `Price_Rule__mdt` rule design (trim premium, aged-inventory discount, loyalty, fleet, holiday)

**Last validation state (HEAD `c0ae11e`):**
- Dry-run: ✅ 429/429 components, 30/30 tests
- Full suite: 31/31 pass (100%)
- Tag: `demo/v0.1` pushed
- Tag commit: `c0ae11e`

**Probe classes (untracked, decision pending):**
- `P2UAT_ProbeTemp` / `P2UAT_RoutingTemp` — commit or retire (see O6 in Phase 2)

**No Phase 3 work started. Awaiting owner approval to begin.**