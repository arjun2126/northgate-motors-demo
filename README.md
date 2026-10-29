# Northgate Motors

A fictional dealership demo on Salesforce: Lead routing/conversion, inventory/reservations,
test drives, standard Quotes with custom CP2 pricing, approvals, financing/delivery, and custom
service/loyalty/consent workflows. Licensed-product seams are documented honestly; this is not
an Automotive Cloud, Revenue Cloud/CPQ, Field Service or Loyalty Management installation.

Current authority/status: [project handoff](NORTHGATE_PROJECT_HANDOFF.md),
[backlog](DEMO_ORG_BACKLOG.md), [governance checklist](docs/GOVERNANCE.md) and
[technical-debt register](docs/TECH_DEBT.md). A document or command example is not authorization.

## What exists and what remains gated

| Area | Actual state |
|---|---|
| Phases 1–5 | Implemented lifecycle; Phase 5 owner-accepted with documented exceptions |
| Phase 6 | Owner-accepted with documented exceptions on October 24, 2026; ten Knowledge Drafts remain unpublished; loyalty/jobs and operational gates stay explicit |
| P7 Batch 1 | Application and thirty licensed stock photographs deployed; browser/gallery/event acceptance, page placement, operational access and VIN credentials deferred; not owner-accepted |
| P7 Batch 2 | Ten application components/four trigger removals deployed atomically; separate six-component territory package deployed; NG_Rooftops remains Planning with zero Account/User associations; not owner-accepted |
| P7 Batch 3 | Strategy/seams and regression wrapper delivered; Case triage prompt deployed in Draft/inactive state; actual Agentforce, Data Cloud, portal and full regression acceptance remain outstanding |
| P7 Batch 4 | Concept note/README/persona pack delivered; photo header and new Vehicle page deployed but unassigned/inactive; placement, screenshots and live walkthrough acceptance remain separate |
| Phase 8 | Final development package deployed `0Afaj00000pPottCAC` (34/34, zero errors; reused 43/43 tests, UI 25/25). P8-05/07 broker deployed; no native customer Vehicle CRUD/Visit Create. Existing customer access/data/sharing/pages/scheduler preserved. Ledger empty/reviewer unassigned/site unpublished. Operational two-customer/data/access/placement/publication/UAT approvals remain; not owner-accepted. See handoff §71 and `evidence/P8/BROKER_DEPLOYMENT/RESULT.md` |

Batch 3 capability inspection finds Prompt platform enabled, Agent Platform/Copilot/Bots,
CustomerDataPlatform and Networks disabled. Available external license counts do not choose a
portal identity/sharing model. No live agent, ingestion, identity-resolution or portal demo is
claimed. See [capability gates](docs/planning/P7_BATCH3_CAPABILITY_GATES.md).

## Architecture and repository map

- `force-app/main/default/`: authoritative metadata/LWC/Apex source. Standard objects include
  Account, Contact, Lead, Opportunity, Quote/QuoteLineItem, Product2/PricebookEntry, Case and Campaign.
- Custom Vehicle/Model/Rooftop/Staff, finance/delivery, service visit, consent and loyalty models
  reuse existing domain services. CP2 pricing/approvals are not replaced by Phase 7 UI components.
- Native Platform Events, queues, reports, approvals, business-hours SLA and Sales Territories
  remain native. No new project-owned Flow or React portal is introduced.
- `manifest/`: exact scoped packages, not permission to deploy every file in this dirty tree.
- `scripts/` and `data/`: tests, read-only verification and separately controlled data tooling.
- `docs/`: [org strategy](docs/architecture/ORG_STRATEGY.md),
  [Automotive concept mapping](docs/architecture/AUTOMOTIVE_CLOUD_MAPPING.md),
  [CPQ](docs/architecture/SIMULATION_CPQ.md), [service](docs/architecture/SIMULATION_FIELD_SERVICE.md),
  [loyalty](docs/architecture/SIMULATION_LOYALTY.md), [nurture](docs/architecture/SIMULATION_NURTURE.md)
  and [integration](docs/architecture/SIMULATION_INTEGRATION.md) seams.
- `evidence/`: timestamped validation/deployment/exception receipts, not fabricated acceptance.
  [Current persona walkthroughs](evidence/DEMO_SCRIPTS/README.md) begin with Activate persona.

## Org strategy and access boundaries

All current commands target **ng-demo**, expected ID **00Daj00001Ae3iWEAR** (Developer Edition).
The original two-org build/UAT-versus-demo strategy is history; never access ng-dev under current
authorization. No scratch orgs. Preserve separate Sales/Finance identities, administrator accounts
and VP reporting boundaries. Historical persona-switcher/permission-matrix documents do not
authorize role swaps, grants, user creation or a substitute administrator persona.

Use explicit target flags and verify identity before authorized org work:

```sh
sf data query --target-org ng-demo --query "SELECT Id, OrganizationType FROM Organization" --json
```

The worktree contains prior modified/untracked source and is not a reproducible clean release.
Do not stage/commit/push, discard unrelated work, infer remote freshness or create a release tag
without owner authorization. Never place secrets or personal identities in source/evidence.

## Toolchain and focused validation

Use the existing Salesforce CLI, Node 22+ and Python toolchain. TypeScript/tsx in package.json is
for existing data tooling; no new LWC test framework/dependency is required for the header tests.
The following commands are local only; run focused checks when relevant source changes:

```sh
node --test scripts/tests/vehicle_photo_header.test.mjs
python3 scripts/tests/check_p7_batch4.py
bash scripts/test.sh --plan
```

The Node checks execute real component state with UI API stubs, not a browser/DOM or actual-persona
permission test. The header uses Lightning UI API record/FLS boundaries, optional model/photo
fields and the same local WebP path contract as the gallery. It never injects Photo__c IMAGE
markup as HTML, reads financial fields or writes records. A separate unassigned page retains
native highlights/details and existing service history; current pages/mappings are untouched.

[P7-17 regression guidance](docs/verification/P7_REGRESSION_GATE.md) describes the explicit
full-run command. It performs only check-only/tests and existing strict read-only DQ gates,
requires real storage evidence, and stops on failure. Do not rerun the unchanged successful
235 Apex methods merely to read this README or demo the wrapper. A green full native run,
strict-DQ disposition and clean-checkout/M3 release acceptance remain outstanding.

## Check-only and deployment workflow

For a newly authorized scope, inspect exact manifest/source hashes and relevant dependencies,
then use an explicit check-only. These most recently reviewed scopes remain separate; they are
already deployed, so examples are for future authorized changes, not a request to repeat checks:

```sh
# Batch 3: one Draft prompt only; no prompt execution, activation or agent setup.
sf project deploy start --dry-run --target-org ng-demo --manifest manifest/p7-batch3-check.xml --test-level NoTestRun --wait 10 --json
# Batch 4: Vehicle photo header LWC plus new unassigned Vehicle FlexiPage only.
sf project deploy start --dry-run --target-org ng-demo --manifest manifest/p7-batch4-check.xml --test-level NoTestRun --wait 10 --json
```

These examples do not request repeating completed validations. NoTestRun is supported for this
Developer Edition metadata-only scope; changes to Apex/security/behavior need the relevant tests.
Actual deployment requires separate owner approval of the exact reviewed scope and command;
only then remove `--dry-run` for that approved package. No broad `force-app/` deployment.
Activation, page assignment, permissions, users, data and jobs remain separate approvals even
after a metadata deployment succeeds. Stop on unexpected failures; do not weaken tests or gates.

Batch 2 application deployment `0Afaj00000p84KRCAY` already atomically installed/replaced ten
components and removed four obsolete triggers using supported native pre-destructive packaging.
Do not replay that destructive manifest as a routine regression step. Territory deployment
`0Afaj00000p8GtRCAU` persists Account Read / Contact None / Opportunity None / Case None; do not
activate or assign Accounts/users. Preserve the five Accounts without Preferred_Rooftop__c.

## Reset and data handling

There is **no authorized reset execution**. `scripts/reset.sh` only prepares an exact-ID plan
from a fresh snapshot; it refuses deletion/reload. Existing loader/automation-control tools can
mutate records/settings and must not be run as part of a demo or regression check.

Under separate read-only snapshot authorization, the documented planning sequence is:

```sh
python3 data/scripts/phase5.py snapshot --output evidence/P7/fresh-reset-snapshot.json
bash scripts/reset.sh --snapshot evidence/P7/fresh-reset-snapshot.json
```

These commands are documentation, not actions performed in Batch 4. Use a new snapshot path;
the existing tool refuses overwrite. A resulting reset plan does not authorize deletion, reload,
BAD-fixture correction, replaying the completed Knowledge import, loyalty reconciliation or jobs.
Read [data-quality notes](docs/DATA_QUALITY.md) and preserved acceptance exceptions first.

## Evidence and remaining acceptance

- [Phase 6 owner acceptance/exception index](evidence/P6/PHASE6_OWNER_ACCEPTANCE_2026-10-24.md).
- [Batch 1 deployment/limits](evidence/P7/BATCH1_STANDARD_DEPLOYMENT_2026-10-25.md).
- [Batch 2 actual deployments/readback](evidence/P7/BATCH2_DEPLOYMENT.md).
- [Batch 3 actual local results/gates](evidence/P7/BATCH3_EXECUTION.md).
- [Batch 4 source/check-only history](evidence/P7/BATCH4_EXECUTION.md).
- [Final Batch 3/4 actual deployment/readback](evidence/P7/P7_FINAL_DEPLOYMENT.md).
- [All 23 Phase 7 block states and acceptance exceptions](docs/planning/PHASE7_FINAL_STATUS_2026-10-26.md).
- [Phase 8 preparation: all eleven requirements, no implementation](docs/planning/PHASE8_HANDOFF_2026-10-26.md).
- [Persona walkthroughs and unexecuted acceptance checklist](evidence/DEMO_SCRIPTS/README.md).

Source/check-only success is not actual page rendering, event delivery, persona access or UAT.
No screenshot is invented. Agentforce, Data Cloud, portal and full regression gates remain open;
Batch 1/2 owner review, Batch 4 page placement/screenshots/walkthroughs, strict release DQ,
clean tag and final M3 approval remain outstanding.
