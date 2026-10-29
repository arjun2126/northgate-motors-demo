# Phase 7 Batch 3 — focused local implementation sequence

## Authorization and baseline

Batch 2 deployment must succeed first. It did: application/removals `0Afaj00000p84KRCAY`
(14/14 in one native pre-destructive transaction), then territories `0Afaj00000p8GtRCAU` (6/6).
Readback confirms active single entry points, absent obsolete triggers, source-matching classes,
unchanged unrelated triggers and a Planning territory model with Read/None/None/None access and
zero Account/User associations. No new Apex tests were run; prior 235/235 evidence is reused.

The current authorization covers P7-13–P7-18 local source/metadata work, focused tests and
check-only as appropriate. It does not authorize Batch 3 deployment or persistent data,
publication, assignments, feature/site activation, ingestion, jobs or credentials. Only ng-demo
`00Daj00001Ae3iWEAR` may be accessed. Preserve CP2 and all completed lifecycle functionality.

## File-level sequence

1. P7-13: add `docs/architecture/ORG_STRATEGY.md` for this repository's actual ng-demo-only
   execution, historical two-org model, exact manifests, dirty source/release and LDV/archive limits.
2. P7-14: inspect actual services; correct only stale CPQ seam statements, reuse Loyalty/Nurture
   notes, add missing Field Service and Integration notes, and link five seams in master-plan §4.4.
3. P7-15/P7-16/P7-18: use `scripts/tests/inspect_p7_batch3.py` for feature-specific read-only
   object/metadata/license/configuration evidence. Do not infer activation/quota/security from
   object exposure. Prepare native source only after its capability/security prerequisites hold;
   explicitly record owner-dependent gates instead of inventing mock completion or new Flows.
4. P7-17: add `scripts/test.sh` and a narrow Python runner reusing the existing read-only DQ
   verifier and specified regression classes. Default to a printable plan; explicit --run performs
   check-only/test/DQ, fails closed and records evidence. Local tests use a fake command executor
   to verify safety/order/failure behavior without rerunning the unchanged 235 Apex tests.
5. Record actual implemented/validated versus blocked acceptance and exact future deployment
   scope. Update handoff/backlog separately for Batch 2 deployment and Batch 3 progress.

## Acceptance boundaries

P7-15 needs an actual authorized agent/template/prompt within verified limits; Knowledge Drafts
are not published grounding. P7-16 needs approved native space/ingestion/identity rules and real
positive/negative resolution evidence without CRM merges. P7-18 needs approved enabled site,
external license/relationship access and real cross-customer tests; nominal External Identity
licenses are not proof of business-object rights. These live actions are not authorized here.

P7-17's clean-checkout/full-green release gate is not implied by local wrapper tests or accepted
DQ exceptions. Do not edit strict verify.sh criteria to force PASS. Batch 1 browser/gallery/event
acceptance, operational access/page placement and VIN credentials remain deferred. Neither
Batch 1 nor Batch 2 is owner-accepted by implementation or deployment alone.
