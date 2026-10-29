# Phase 7 Batch 4 — focused local implementation plan

## Authority and baseline

Implement only P7-19, P7-20, P7-21 and P7-23 locally; read-only ng-demo inspection and scoped
check-only are permitted. No Batch 3/4 deployment, feature/page activation, permission/user/
business-data changes or Git release actions. Target only ng-demo `00Daj00001Ae3iWEAR`.

Handoff §44 is the starting state. Batches 1/2 are deployed, not owner-accepted. Batch 3 has a
validated Draft prompt only, disabled Agent Platform/Data Cloud/Networks and an unexecuted full
regression/clean-checkout gate. Preserve those limits, Phase 6 exceptions and CP2/domain services.

## File-level sequence

1. P7-19: add the one-page `docs/architecture/AUTOMOTIVE_CLOUD_MAPPING.md`, using existing
   standard/custom objects and licensed concepts without adding an Automotive Cloud build.
2. P7-23: add a small read-only `vehiclePhotoHeader` LWC using Lightning UI API getRecord and the
   established Photo__c/model Image_Path__c contract. Photo__c is IMAGE markup, not an img URL;
   require the formula value and allow only the existing NG_VehicleImages WebP path pattern.
   Optional image/model fields must fail closed under FLS. Add an unassigned new Vehicle page
   with native highlights/details, the photo header and existing service history. Leave existing
   pages, mappings, app assignments, source gallery and record data untouched.
3. Validate new component state/access/fallback/navigation behavior with existing Node test/VM
   conventions; validate exact LWC/page scope and preserved source hashes, then a two-component
   NoTestRun check-only. Do not repeat unchanged Apex suites for a UI-API-only addition.
4. P7-20: replace minimal README with accurate project status, architecture, toolchain, safe
   command/manifest boundaries, reset-plan documentation and evidence/acceptance links.
5. P7-21: add five persona-first Admin/Developer/Analyst/Support/Architect walkthroughs and an
   indexed gate/evidence checklist. Preserve the old P2 demo as clearly historical, not executable
   current instructions. Do not substitute an admin or scripted role switch for missing personas.
6. Run focused docs/link/scope checks. Update handoff/backlog and report code/docs delivered versus
   unexecuted real-persona walkthroughs, page placement and with/without-photo screenshots.

## Acceptance boundary

The photo-header source/page and local state tests do not establish live rendering. Deployment,
placement and both actual record-page screenshots require separate approval/evidence; no fake
screenshots or persistent test records. The five runbooks can be prepared under this authority,
but their end-to-end live acceptance is not passed without actual identities/authorized operations.
Keep Agentforce, Data Cloud, portal, P7-17 full regression, M3 clean tag/DQ/UAT and Batch 1 browser/
gallery/event/page/operational/VIN gates explicit. Phase 8 is not started.
