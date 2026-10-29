# Phase 7 — consolidated dependency-correct implementation plan

## Status and scope

**Original dependency/design baseline; current execution supersedes historical status below.**
Batch 1 deployed under separate authorization; evidence:
`evidence/P7/BATCH1_STANDARD_DEPLOYMENT_2026-10-25.md`. Browser/gallery/event acceptance,
operational access/page placement and VIN credentials remain deferred; Batch 1 is not owner-accepted.
Batch 2 is now deployed (handoff §43 / `evidence/P7/BATCH2_DEPLOYMENT.md`): atomic application/
removals 14/14, territories 6/6, no new Apex run beyond reused 235/235 evidence. Model Planning,
Read/None/None/None persisted, zero associations/memberships; not owner-accepted.
Batch 3 strategy/seams/regression wrapper and Draft prompt are implemented; final prompt 1/1 and
Batch 4 header/page 2/2 are deployed under separate owner authorization (handoff §§46–47 /
`evidence/P7/P7_FINAL_DEPLOYMENT.md`). Prompt remains Draft/inactive; page unassigned/inactive.
Native agent/Data Cloud/site and runtime/full-release gates remain. Permission-
audit native/browser reader and territory assignment/activation/persona gates remain open.
Batch 4 docs/scripts and metadata are delivered; placement/screenshots/actual-persona end-to-end
acceptance and existing Batch 3/M3 gates remain outstanding. All 23 current states are in
`docs/planning/PHASE7_FINAL_STATUS_2026-10-26.md`; Phase 7 is not fully owner-accepted. Phase 8 is
preparation only in `docs/planning/PHASE8_HANDOFF_2026-10-26.md`.
No business records, credentials, assignments,
activation, scheduling or Git release action is authorized by this plan. Original tables and
observations below remain the design baseline, not a current-state claim about installed assets.

**Phase 6: OWNER-ACCEPTED WITH DOCUMENTED EXCEPTIONS — October 24, 2026.**
The exception index and underlying evidence remain authoritative:
`evidence/P6/PHASE6_OWNER_ACCEPTANCE_2026-10-24.md`. Acceptance does not activate the program,
publish articles, assign personas, prove browser/live acceptance or authorize additional records.

Goal: complete the 23 existing Phase 7 blocks through four independently testable implementation
batches, preserving the accepted lead-to-sale/post-sale lifecycle. Keep all eleven Phase 8 blocks
on the separate M4 roadmap. This plan changes execution grouping, not item IDs or acceptance scope.

Target for every future authorized command: **ng-demo / 00Daj00001Ae3iWEAR only**. Never access
ng-dev. P7-13 may describe the historical two-org strategy without operating against the other org.
No deployments, records, assignments, activations, jobs, Git staging/commit/push or feature code
were performed during this preparation.

## Final four-batch grouping

| Batch | Blocks | Count | Independently testable outcome |
|---|---|---:|---|
| 1 — Inventory experience, integration and events | P7-22, P7-01–P7-06 | 7 | Required image resource plus secure gallery/reservation, calculator widget, mock VIN integration, contract and event refresh |
| 2 — Trigger consistency, maintenance and governance | P7-07–P7-12 | 6 | Bounded trigger consolidation, isolated counter reconciliation, governance/debt/security evidence and capability-gated territories |
| 3 — Architecture, capability demos and regression gate | P7-13–P7-18 | 6 | Seam/strategy docs, capability-approved Agentforce/Data Cloud/portal slices and a safe repeatable validation command |
| 4 — Final presentation and release evidence | P7-19–P7-21, P7-23 | 4 | Automotive concept note, photo header, accurate README and complete persona-based demo pack |

**Only required inter-batch move:** P7-22 moves from provisional Batch 4 to the start of Batch 1.
P7-01 explicitly depends on its image resource. Keeping P7-22 in Batch 4 would leave Batch 1's
photo acceptance blocked or require mislabelling placeholders as complete. P7-23 does not block
the gallery, so it stays in Batch 4 and reuses the established asset/rendering contract.

## Focused dependency evidence

Only the blocking asset dependency and relevant existing source were checked; no accepted
Phase 6 investigation or successful regression suite was reopened.

CONFIRMED — read-only Organization query excerpt:

```json
"Id": "00Daj00001Ae3iWEAR"
```

CONFIRMED — `SELECT Name,ContentType,BodyLength FROM StaticResource WHERE Name = 'NG_VehicleImages'`:

```json
"records": [],
"totalSize": 0
```

CONFIRMED — `SELECT COUNT() FROM Vehicle_Model__c` and the same COUNT with
`WHERE Image_Path__c != null` each return:

```json
"totalSize": 30
```

There are 30 models and 30 nonblank existing paths, but the required named static resource is
absent. Nonblank paths do not prove that images render or meet P7-22. Preserve the current
mapping until an explicitly approved data-update scope replaces any paths; no path was changed.

Bounded source facts that affect the plan:

- `Vehicle__c.Photo__c` is `IMAGE(Vehicle_Model__r.Image_Path__c, "Vehicle photo")`: its result
  is formula-generated image markup, not a raw URL. The model field currently supplies the path.
- `VehicleReservationGuard` already maintains Reserved status/time and rejects an existing
  reservation takeover. `VehicleTrigger` performs VIN/reservation checks; `VehicleCounterTrigger`
  maintains rooftop counts in after contexts, including both old/new rooftops. Reuse these paths.
- Local trigger inventory contains multiple entry points on Lead (three), Vehicle (two) and
  Test_Drive (two). P7-07 has a concrete consolidation scope; other already-thin triggers do not
  need a cosmetic rewrite. Source inspection is not a fresh live trigger audit.
- `PaymentCalculatorService`, `TradeIn_Calc_Equity`, `FinanceApplicationController` and
  `financeApplication` already contain approved maths, context/security and preview behavior.
- `Inventory_Age_Days__c` is already `TODAY() - Acquisition_Date__c`. P7-08 must not introduce
  a redundant stored age or try to update a formula field.
- `docs/TECH_DEBT.md` already exists. Extend/classify it rather than create a competing ledger.
  `scripts/verify.sh` is an existing ng-demo-only read-only Phase 5 verifier; do not run it now
  or replace it with a live repair/reset path.
- `package.json` already provides Node 22+, TypeScript and tsx for data tooling. The historical
  React proposal's “no Node toolchain” sentence is not current repository fact; it also does not
  establish that an LWC/React/browser-test toolchain is installed or approved.
- Other capability/licensing states were not re-audited in this planning run. They are explicit
  pre-build gates below, not assumptions that Agentforce, Data Cloud, territories or portal access
  are currently ready.

## Common preservation and acceptance rules

1. Preserve CP2/Quote Builder/Summary/pricing and approvals; appraisal screen Flow; finance
   application/approval identity boundaries; delivery/enrollment; VIN/reservation/test-drive
   rules and counters; service capacity/intake/history; loyalty ledger/configuration; consent,
   Knowledge Drafts, native SLA and corrected reports/folder security.
2. No new project-owned Flows. Native Salesforce features remain native. Interactive additions
   use LWC/Apex. Historical fallback wording that mentions a new triage/self-service Flow needs
   an explicit owner exception or an approved LWC/Apex amendment, not automatic implementation.
3. Preserve separate Sales/Finance identities and existing users. New metadata access and actual
   assignments/role changes are separate decisions. Test as the actual intended persona using
   CRUD/FLS/record boundaries; admin context is not permission evidence for another persona.
4. Add each mutation only through its authoritative existing trigger/service path. Lock/re-read
   mutable reservation state on the server, authorize the actor and handle stale/conflicting saves.
   No client-only guard, per-caller bypass or new third Vehicle trigger.
5. Use smallest source changes and current dependencies/native UI. Do not add a framework,
   factory, generalized bus or migration merely for this plan. Map callers before each actual fix.
6. Each future implementation batch gets an exact manifest, selected source inventory and focused
   tests, then affected regressions and actual acceptance evidence. Reuse unchanged passing
   evidence unless new changes or concerns justify rerunning it. Verify effective report filters
   and native access, not only metadata compilation.
7. Future code/tests/check-only work, actual deployments, record writes, assignments, endpoint
   credentials, publication, platform/site enablement, jobs, page activation and Git release
   actions require the corresponding explicit owner authorization. This plan grants none.
8. Keep intentionally inactive functionality and Phase 5/6 exceptions explicit. Do not alter BAD
   fixtures, loyalty balances or historical ledger evidence to make a release gate look green.

## Batch 1 — inventory experience, integration and events

**Build order:** P7-22 asset readiness first; then P7-01. P7-02 and the paired P7-03/P7-04 work
can proceed independently. Draft the HTTP contract before the client, finalize P7-04 after the
client tests. Complete P7-05 after reservation succeeds, then P7-06. This is not permission to
start any build now.

| Block | Actual dependencies | File-level scope / existing reuse | Acceptance criteria and evidence |
|---|---|---|---|
| P7-22 | P1-02; P0-09 storage/asset checks; preserved 30-model/path mapping; local resource now ready | Native `staticresources/NG_VehicleImages` bundle with thirty distinct real stock photographs under owner sourcing amendment, rights register and preserved exact paths; existing Photo__c contract unchanged | Appropriate source/photographer/license proof; body/approximate-year match, genuine optimized WebP (~50 KB where practical), no deceptive logo removal/endorsement; resource/storage/path checks and later actual formula/gallery rendering; `evidence/P7/vehicle_images.png`. Local asset validation passes; actual deployment remains separately approved |
| P7-01 | P2-06 reservation rules; P7-22; current Sales CRUD/FLS; actual reservation/status fields | Proposed inventory gallery LWC and narrow read/reserve controller/tests; reuse VehicleReservationGuard and existing trigger/counter paths; no CP2 repricing or other reservation channel rewrite | Make/body/price/status filters, loading/empty/error states, accessible photo cards and Reserve without reload; authorized server lock/re-read, stale/double-reserve/denied-user cases; native IMAGE markup handled safely rather than passed as an img URL; `evidence/P7/inventory_lwc.png` |
| P7-02 | P4-01 payment maths; P3-01 equity/appraisal; existing finance and Sales context boundaries | Proposed Opportunity calculator LWC/controller adapter only where needed; reuse PaymentCalculatorService/TradeIn_Calc_Equity and accepted finance preview pattern | Interactive calculations match existing services, including zero rate, rounding, invalid/null inputs and negative equity; current configuration supplies rates, not hardcoded pricing; no implicit Quote/Financing saves or approval bypass; `evidence/P7/widget.png` |
| P7-03 | P1-02 VIN semantics; approved mock contract/endpoint; Named/External Credential capability and actor access | Proposed VIN decoder callout/controller and HttpCalloutMock tests; preserve VinValidator as checksum validation, not a decoder; source-managed credential metadata where supported, secrets outside source | Mock success, timeout, malformed/non-2xx and denied-actor handling pass; no silent inventory overwrite, real VIN service or paid endpoint; no real credential/callout activation without approval; `evidence/P7/vin_callout.txt` |
| P7-04 | P7-03 for finalized behavior; contract drafted before implementation | `docs/integration/API_CONTRACT.md`, matching actual mock decoder request/response/error behavior | Examples match tests and implemented API, distinguish mock from real integration, document authentication, timeout/error handling and write policy; doc diff and contract-test references |
| P7-05 | P7-01 authoritative successful reservation; native Platform Event capability/limits; approved subscriber access | Proposed Vehicle_Reserved__e metadata, minimal publish service hooked into the existing after-save path, gallery subscription and tests | Publish-after-commit semantics; rollback/failed reservation produces no successful-reservation event; subscriber refreshes authorized data without duplicate mutation; minimize payload/PII and enforce read boundary on refresh; handle subscription/publish failure; `evidence/P7/platform_event.txt` |
| P7-06 | P7-05; P7-03/P7-04 contract and actual native/simulated boundary | Proposed event/CDC/Pub-Sub seam note under `docs/architecture/`, linking the real implementation | Explain what publishes/subscribes, after-commit/replay/delivery limits and what CDC/Pub-Sub integration is only documented; no implied CDC enablement or external subscriber; document evidence |

**Batch 1 exit:** image/gallery/widget/callout/event contracts and focused tests pass; affected
VIN/reservation/counter/test-drive and finance/CP2 regressions pass as relevant. Approved Sales
browser evidence shows the actual surface and error path. Deployment, image mapping data writes,
credentials, permission assignments and page placement are separate live approvals. A gallery
with only placeholders does not pass the required photo acceptance.

**Concise start recommendation:** request one bounded Batch 1 local implementation/test/check-only
authorization for these seven blocks, with deployment/data/security/activation held separately.
First establish the image bundle/path contract without touching existing records, then implement
the minimal secure gallery/reserve path. Do not block this on unrelated Phase 6 operational gates.

## Batch 2 — trigger consistency, maintenance and governance

**Build order:** establish P7-09/P7-10 documentation from actual Batch 1 behavior; perform scoped
P7-07 consolidation, then P7-08. P7-11 is read-only evidence work. Check P7-12 capability before
designing territory metadata; an unavailable feature does not justify silently simulating it.

| Block | Actual dependencies | File-level scope / existing reuse | Acceptance criteria and evidence |
|---|---|---|---|
| P7-07 | P1-13; Batch 1 event/reservation entry points; existing Lead/Vehicle/Test_Drive trigger/service callers | Consolidate only duplicate object entry points where required; preserve existing domain services, contexts, event order and each documented bypass contract | One entry trigger per affected object, bounded routing/recursion controls, 200-row and partial-save/re-entry tests; preserve Lead conversion/routing, reservations/counters/events and test-drive follow-up; no unrelated Quote/finance/delivery/loyalty rewrite; `evidence/P7/trigger_tests.txt` |
| P7-08 | P2-12 counter definitions; P7-07 touchpoints and bypass/security; Inventory_Age_Days__c already formula | Proposed Queueable maintenance/tests reusing accepted VehicleCounters semantics; verify native age formula rather than add a stored copy | Test.stopTest proves idempotent reconciliation of scoped cached counts for inserts/moves/deletes/undeletes; no per-row queries or unbounded retry; no automatic enqueue/schedule, loyalty balance repair or live reconciliation; `evidence/P7/queueable.txt` |
| P7-09 | Existing AGENTS/automation direction and Batch 1 actual conventions | `docs/GOVERNANCE.md`: focused naming, review, deployment boundary, definition of done and evidence policy | Used by the review checklist; scope/test/actual-persona/exception requirements explicit; no hypothetical framework mandate; doc references |
| P7-10 | P2-04 and current accepted architecture; existing docs/TECH_DEBT.md; Phase 5/6 exceptions | Extend one ledger with location, actual limitation, owner/disposition and future trigger; classify obsolete entries rather than repeat old architecture claims | Include deliberate race/Source_Reference/history/throughput limits with evidence; distinguish slot-overlap history from accepted daily capacity; no unsolicited repair of accepted work; doc evidence |
| P7-11 | P1-19; current profiles/PSGs/licensing; effective FLS/report lessons from Phase 6 | Read-only permission assignment/report inventory and supporting queries/native reporting where supported | Evidence-backed assignments and unused-permission candidates with observation limits; do not equate no usage evidence with proven unused; actual reader can run the report; no automatic grants/revocations; `evidence/P7/perm_audit.png` |
| P7-12 | P0-09 current Territory capability; rooftop/account mapping and explicit future sharing/activation approval | Native Territory model/type/rules metadata and tests/evidence if actually supported; no paid substitute or blanket sharing change | Four rooftop-aligned territories; approved Account assignments and rendered tree; verify no unintended access widening. Inactive metadata alone does not pass active assignment acceptance; unavailable capability requires owner disposition; `evidence/P7/territories.png` |

**Batch 2 exit:** affected trigger/counter behavior remains equivalent; maintenance is proven in
test isolation, not silently executed live; governance/debt/security evidence is usable. Territory
capability/sharing/assignment state is explicitly verified or dispositioned by the owner. Accepted
Phase 6 exceptions remain indexed; no maintenance job may absorb loyalty or Case reconciliation.

## Batch 3 — architecture, capability demos and regression gate

**Build order:** P7-13/P7-14 and the P7-17 validation wrapper can proceed from completed earlier
batches; the wrapper should be used during this batch rather than postponed until the final day.
P7-15/P7-16/P7-18 are independently capability/authorization gated. Close P7-17 evidence after
the actual chosen Batch 3 payload and approved capability dispositions are known.

| Block | Actual dependencies | File-level scope / existing reuse | Acceptance criteria and evidence |
|---|---|---|---|
| P7-13 | P0-01 strategy; actual approved target and release boundaries | `docs/architecture/ORG_STRATEGY.md`; document two-org history, explicit manifests, source/LDV/archiving practice | Describes actual setup and ng-demo-only execution, not permission to use ng-dev; no scratch org/remote initialization; doc exists and is internally consistent |
| P7-14 | P3-11/P4-12/P6-10/P6-13 plus completed P7-03/P7-04/P7-06 integration/event facts | Reuse/update existing CPQ/Loyalty/Nurture seam notes; fill missing Field Service/Integration notes and master-plan §4.4 index | All five seams distinguish standard objects/native features from custom/licensed simulations; no new paid-product build or rewrite of accepted engines; correct source references and doc index |
| P7-15 | P0-09 current Agentforce/Prompt Builder capability and quota; P6-02; P6-15 actual Draft/publication/reader state | One native internal service agent and one Prompt Builder template after approval; reuse allowed Case/service sources and existing security; no agent auto-mutation | Authorized prompt produces grounded, scoped triage or service summary within measured limits; no cross-persona/customer disclosure. Knowledge-grounded use needs explicit publication/reader decision; Drafts are not published acceptance. Any labelled fallback requires owner approval and must honor no-new-Flow direction; `evidence/P7/agentforce.png` |
| P7-16 | P0-09 current Data Cloud space/storage/credits and ingestion capability; P6-05 source/identity/access | Minimal approved ingestion plus identity-resolution configuration; no duplicate CRM data model or scheduled sync by default | Known synthetic records resolve correctly in the approved space with a negative false-match case; measured limits, mapping and lineage recorded; no CRM merge, unapproved data export or auto refresh; `evidence/P7/datacloud.png` |
| P7-17 | P5-08/P0-04; existing verify.sh/data tooling; Batch 1/2 changes and actual Batch 3 payload | Proposed scripts/test.sh wrapper, scoped manifests and existing test/verify commands; preserve dirty/unrelated source | One command runs explicit check-only + relevant Apex tests + read-only DQ verification, fails on unexpected failures, captures IDs/coverage/expectations; no deploy/reset/load/repair/job/secret printing. Clean-checkout gate requires a reviewed source baseline, not this uncommitted tree; `evidence/P7/regression.txt` |
| P7-18 | P0-08/current Experience capability and actual external-user licenses; P6-05; owner Digital Experiences/identity/sharing decisions; Phase 8 security constraints | Small real authenticated Owner Portal seed using existing Experience Cloud/LWC baseline; verify per-object relationship-anchored CRUD/FLS and external sharing before build | One/two approved external users see their own service history/appointment surface and fail cross-customer/guest checks; no assumption that External Identity licenses grant Case/custom-object access. React/Multi-Framework remains unapproved P7-18-only evaluation, not default; `evidence/P7/portal.png` |

**Batch 3 exit:** strategy/seams and safe regression wrapper are complete; each native capability
demo is proven with approved access/limits or explicitly owner-dispositioned as blocked/deferred.
Do not claim native demos from a mock screenshot or activate Data Cloud/Agentforce/site settings
under a metadata-only approval. Missing capability blocks that item, not safe independent docs.

For P7-18, preserve `docs/architecture/EXPERIENCE_PORTAL.md`'s relationship isolation and
cross-customer tests. Confirm external OWD/CRUD/licensing per object; do not grant broad direct
Vehicle/Loyalty access or silently bypass permissions because internal OWD is public. Any
security-model clarification is an explicit pre-build decision, not an assumption in this plan.
Historical documents mentioning ng-dev do not authorize accessing it. Historical Flow fallback
wording does not override the ratified LWC/Apex direction.

## Batch 4 — final presentation and release evidence

**Build order:** P7-19 and P7-23 can proceed independently. Finalize P7-20 after P7-17 and actual
implemented/capability-dispositioned outcomes, including the photo header. Complete P7-21 last.

| Block | Actual dependencies | File-level scope / existing reuse | Acceptance criteria and evidence |
|---|---|---|---|
| P7-19 | P0-09/licensed-product ledger; actual dealership model | `docs/architecture/AUTOMOTIVE_CLOUD_MAPPING.md` only | One-page mapping from custom/current entities to licensed concepts, labels gaps/native equivalents; never installs or builds Automotive Cloud |
| P7-20 | P7-17 plus actual Batch 1–3 outcomes/P7-23 and carried exceptions | Accurate README using current source/target/release/runbook facts | Describes what exists, target-only deploy/check-only boundaries and safe reset documentation; no reset execution or claim of live activation/clean checkout where false |
| P7-21 | All completed/dispositioned Phase 0–7 items, especially P7-17/P7-20/P7-23 | `evidence/DEMO_SCRIPTS/` admin/developer/analyst/support/architect scripts; reuse accepted data and exception index | Every script opens with “Activate persona” using the approved existing identity, not automatic permission/role swaps; each authorized path runs end-to-end, inactive paths labelled. “All phases” means through Phase 7 here; P8-11 owns the later portal expansion, avoiding a circular future dependency |
| P7-23 | P7-22 completed in Batch 1; P1-06 existing Vehicle page and approved placement | Proposed photo-header LWC, reusing the established image/model contract and gallery handling where appropriate; preserve current details/history | Large Photo__c/model header, graceful missing-image behavior and keyboard/accessibility basics; screenshots with/without image. No blind replacement of accepted Vehicle pages or activation without approval; `evidence/P7/vehicle_header.png` |

**Batch 4/M3 exit:** all 23 IDs have actual evidence or explicit owner disposition; all four skill
domains are demonstrated honestly. The original clean deploy/test/approved-DQ/regression/UAT/seam/
governance/demo/tag release requirements remain. Carry accepted Phase 5/6 exceptions into the
gate explicitly; do not turn intentional fixtures into a false zero or silently waive a failed
gate. No clean tag or Git release action is authorized by this planning document.

The original zero-row release-query criterion is not weakened by this plan. If the existing
strict verifier still fails on an accepted exception, record that gate result and obtain an
explicit M3 disposition or separately approved correction; do not edit a check to force PASS.
That later release decision does not reopen Phase 6 acceptance or block independent Batch 1 work.

## Cross-batch dependency summary

- P7-22 precedes P7-01; P7-01 precedes P7-05; P7-05 precedes P7-06. P7-03 finalizes P7-04.
- Batch 1 reservation/events are preserved by Batch 2 P7-07, then reused by P7-08 maintenance tests.
- Batch 1 integration/event facts and existing Phase 3/4/6 seams feed Batch 3 P7-14.
- P7-17 consumes actual earlier payloads and gates Batch 4 P7-20; it should also be usable during
  Batch 3 implementation. P7-22 feeds Batch 4 P7-23 without delaying Batch 1.
- P7-21 is last after the header/README/capability dispositions. It does not depend on completion
  of Phase 8; the separate P8-11 script is the M4 extension.
- P6-E08 is a real gate for published Knowledge/agent grounding, not a reason to redo accepted
  Phase 6. History/external-user gates apply where P7-16/P7-18 actually need them. No blanket
  Phase 6 activation or operational replay is a prerequisite for Batch 1.

## Phase 8 roadmap — all eleven blocks retained, not authorized

P7-18 is the smaller site seed; Phase 8 extends it rather than rebuilding it or changing its
acceptance criteria. Phase 8 uses **Experience Cloud + custom LWC only**. React is excluded.
Digital Experiences enablement, external-user model, sharing, records and public/site activation
remain owner decisions. Licensing limits are verified, never inferred from nominal license names.

| Block | Roadmap item | Actual dependency/gate |
|---|---|---|
| P8-01 | Experience Cloud site scaffold | Owner Digital Experiences decision/capability and P7-18 seed; no enablement now |
| P8-02 | External access model | P8-01; measured licenses and relationship-anchored per-object access; cross-customer denial |
| P8-03 | Portal Apex controllers/tests | P8-02; sharing plus explicit relationship filtering and CRUD/FLS, guest/cross-customer negative tests |
| P8-04 | Portal dashboard home | P8-03; authenticated own-data widgets only |
| P8-05 | My Vehicles | P8-03/P7-22; verified external exposure and image contract, no broad object-access shortcut |
| P8-06 | Service history | P8-03/P6-05; approved own-contact/vehicle visit/Case/mileage access |
| P8-07 | Appointment request | P8-03/P6-01; LWC/Apex wizard reusing capacity enforcement and relationship write isolation |
| P8-08 | Case tracking | P8-03/P6-02; actual external Case support, approved create/comment/routing boundary |
| P8-09 | Loyalty/rewards read-only | P8-03/P6-06; own-membership/transaction scope, no activation or redemption implied |
| P8-10 | Responsive/branding/accessibility polish | P8-04–P8-09; desktop/mobile, keyboard/focus/contrast and original assets |
| P8-11 | Portal demo/UAT/seam note | Block B completed; approved persona first, recorded real/simulated boundaries and M4 evidence |

The existing M4 exit gate and owner-approved fallback decision process remain unchanged. No
P8 item is absorbed into Phase 7, removed, renumbered or marked complete by this plan.

## Approval and evidence boundaries

The next decision is a bounded **Batch 1 local implementation/test/check-only authorization**
for seven blocks, retaining separate approval for deployment, image data mapping, credentials,
permissions and placement. No further broad audit is recommended. Before each later capability
batch, perform only the feature-specific checks needed for that batch's direct dependencies.

This planning run changes documentation only. Coverage checks must confirm each P7 ID appears
once in the four batch tables (23 total) and every P8 roadmap ID appears once (11 total). No Apex
tests, deployments, record updates, assignments, activations, external service calls, new feature
source or Git staging/commit/push are part of preparing this plan.

### Completed planning checks

Read-only row-coverage and dependency-order checks were run against this document. They validate
the four allocations, unique coverage and forward/same-batch dependency placement; they are not
feature tests or evidence that any planned block is implemented.

CONFIRMED — raw planning-check output:

```json
{
  "status": "PASS",
  "phase7Blocks": 23,
  "uniqueBlocks": 23,
  "batchCounts": [7, 6, 6, 4],
  "crossBatchDependencyOrder": "PASS",
  "missing": []
}
```

CONFIRMED — raw Phase 8 roadmap coverage output:

```json
{
  "status": "PASS",
  "phase8RoadmapBlocks": 11,
  "uniqueBlocks": 11,
  "missing": []
}
```

Targeted `git diff --check` on the tracked handoff/backlog/Knowledge documentation returned no
output and succeeded. Existing Phase 6 tests were not rerun. No deployment, record mutation,
permission/activation change or Phase 7 feature implementation occurred.
