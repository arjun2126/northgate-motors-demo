# Phase 7 Batch 2 — owner-authorized deployments

## Atomic application/removal transaction

Target verified ng-demo `00Daj00001Ae3iWEAR`, Developer Edition. Local source hashes and exact
manifest sets matched successful validations. All 26 selected source files remain unchanged.
No unrelated worktree changes were deployed.

Before execution the saved command/result for `0Afaj00000p7GCLCA2` was inspected: it already
included the ten application members and four ApexTrigger removals in one successful check-only,
with 235/235 methods. The CLI's supported --pre-destructive-changes flag represents native
destructiveChangesPre.xml in the same Metadata API transaction. This is the equivalent supported
format requested by the owner; no separate application/removal calls or phase change were used.
No combined revalidation was needed because the exact combined format/source was already covered.

Command executed:

```sh
sf project deploy start --target-org ng-demo --manifest manifest/p7-batch2-check.xml --pre-destructive-changes manifest/p7-batch2-destructive.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw deployment excerpts:

```json
{"id":"0Afaj00000p84KRCAY","status":"Succeeded","checkOnly":false,"completedDate":"2026-10-26T03:33:42.000Z","numberComponentsDeployed":14,"numberComponentsTotal":14,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0,"rollbackOnError":true}
```

Fourteen successful changes are ten installed application components plus exactly these four
deleted triggers: LeadBeforeConvertGuard, LeadAfterConvertSeedBlock, VehicleCounterTrigger and
TestDriveFollowupTrigger. The native rollbackOnError flag is true; no ignore-errors/warnings,
purge or extra removal scope. Component failures and warnings are empty.

CONFIRMED — raw readback:

```json
{"status":"PASS","deploymentId":"0Afaj00000p84KRCAY","activeEntryTriggers":["LeadRoutingTrigger","TestDriveTrigger","VehicleTrigger"],"obsoleteTriggersAbsent":["LeadAfterConvertSeedBlock","LeadBeforeConvertGuard","TestDriveFollowupTrigger","VehicleCounterTrigger"],"classBodiesMatchSource":7,"unrelatedTriggersUnchanged":12}
```

Actual live class/entry-trigger bodies match source. All twelve unrelated trigger hashes,
including Quote, financing, delivery, service, loyalty and consent paths, remain unchanged.
This is metadata/source preservation evidence, not fresh browser or live-reservation acceptance.

## Separate territory deployment

Only after application success/readback, the exact six validated native members were deployed:

```sh
sf project deploy start --target-org ng-demo --manifest manifest/p7-12-territories.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw deployment excerpts:

```json
{"id":"0Afaj00000p8GtRCAU","status":"Succeeded","checkOnly":false,"completedDate":"2026-10-26T03:33:49.000Z","numberComponentsDeployed":6,"numberComponentsTotal":6,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0,"rollbackOnError":true}
```

CONFIRMED — raw model/type/association readback excerpts:

```json
{"Id":"0MAaj0000017bLdGAI","DeveloperName":"NG_Rooftops","State":"Planning"}
{"Id":"0M5aj000000AsyPCAS","DeveloperName":"NG_Rooftop","Priority":1}
"objectAssociations":[{"total":0}]
"userMemberships":[{"total":0}]
```

All four native territories exist as siblings, share NG_Rooftop and persist Account Read,
Contact None, Opportunity None, Case None. No setting/default change was needed to persist
Contact None. Model stays Planning; there is no activation or Account/User association.
Full IDs/field readback: `BATCH2_TERRITORY_READBACK.json`.

Both deployments used supported Developer Edition NoTestRun and ran zero Apex methods. The
235/235 combined validation and 6/6 territory validation were reused, not rerun. There were no
deployment failures, corrections, retries, warnings or extra component scope.

## Records, boundaries and evidence

No business-record changes, maintenance enqueue/schedule, reservation test, territory activation,
Account/User assignment, permission grant, sharing-default change, credential setup, Git staging/
commit/push or ng-dev access. Only the two expressly authorized metadata transactions were issued.
Read-only verification followed each step; Batch 3 was started only after both succeeded.

Raw sanitized command/results: `BATCH2_APPLICATION_DEPLOYMENT{,_COMMAND}.json`,
`BATCH2_TERRITORY_DEPLOYMENT{,_COMMAND}.json`; source/atomic preflight and actual readbacks:
`BATCH2_DEPLOYMENT_PREFLIGHT.json`, `BATCH2_APPLICATION_READBACK.json`, `BATCH2_TERRITORY_READBACK.json`.
Creator display names/private machine paths are removed from generated command receipts.

Batch 2 is deployed, not owner-accepted. Territory Account/User/activation/persona/tree acceptance
and P7-11 native/browser reader gates remain outstanding. Preserve five unmapped Accounts and
the existing identity decision. Batch 1 browser/gallery/event acceptance, operational access/page
placement and VIN credentials remain deferred; Batch 1 is not owner-accepted. Phase 6 acceptance
and all documented exceptions are unchanged.
