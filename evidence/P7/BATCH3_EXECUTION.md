# Phase 7 Batch 3 — local implementation and native capability gates

## Separate baseline and authority

Batch 2 deployments succeeded first; see BATCH2_DEPLOYMENT.md. This report covers only subsequent
P7-13–P7-18 local source, read-only discovery, local tests and check-only. No Batch 3 metadata
was deployed; no persistent business data, feature settings, ingestion, publication, permissions,
site/user, credentials or scheduling was changed. No Git release actions or ng-dev access.

Plan: `docs/planning/P7_BATCH3_IMPLEMENTATION_PLAN.md`.

## Actual functionality and acceptance by block

| Block | Delivered | Genuine remaining gate |
|---|---|---|
| P7-13 | ORG_STRATEGY.md documents actual target-only execution, historical two-org design, scoped atomic release, source/dirty-tree and LDV/archive limits | No clean release/tag or archive operation is claimed |
| P7-14 | All five actual product seams indexed in master-plan §4.4; stale CPQ object/primary-basis wording corrected; missing Field Service/Integration notes added | Documents do not implement licensed products or close live acceptance |
| P7-15 | Native NG_Case_Triage Flex template, one Draft version, Case Subject/Status/Priority input, no activation/action/Knowledge grounding. One-component check-only passes | Agent Platform/Copilot/Bots disabled; actual agent, Service identity/permissions, usage limits, runtime model and prompt evidence need owner decisions |
| P7-16 | Actual Data Cloud gate/source-identity/approval sequence documented | CustomerDataPlatform disabled, streams zero, no DataSpace exposed; no native ingestion/identity configuration or runtime match/false-match proof |
| P7-17 | One-command plan/full-run wrapper with explicit ng-demo, check-only/test/DQ ordering, fail-fast evidence and local safety tests | Full native run, strict DQ/accepted-exception disposition and clean-checkout acceptance remain open; unchanged 235 tests were not rerun |
| P7-18 | Actual feature/license/security prerequisites and exact next decisions documented | Digital Experiences disabled, Network unavailable, Site zero; no real portal/users or cross-customer/guest acceptance |

P7-15/16/18 are not complete native demos. No screenshots or simulated substitutes are fabricated.
The no-new-Flow and Experience Cloud/LWC-only directions remain intact; Phase 8 is not started.

## Read-only capability evidence

`scripts/tests/inspect_p7_batch3.py` verifies Organization ID and inventories relevant object/
metadata/license states. Six relevant Settings members were retrieved into evidence only under
retrieve `09Saj00000mm9AEEAY`; force-app/settings was not overwritten.

CONFIRMED — raw retrieved flags:

```json
{"enableEinsteinGptPlatform":"true","enableEinsteinGptCopilot":"false","enableAgentPlatform":"false","enableBots":"false","enableCustomerDataPlatform":"false","enableNetworksEnabled":"false"}
```

CONFIRMED — raw license rows:

```json
[
  {"Name":"Salesforce","TotalLicenses":4,"UsedLicenses":4},
  {"Name":"Customer Community Plus","TotalLicenses":5,"UsedLicenses":0},
  {"Name":"External Identity","TotalLicenses":9,"UsedLicenses":0},
  {"Name":"Partner Community","TotalLicenses":5,"UsedLicenses":0},
  {"Name":"Customer Community","TotalLicenses":5,"UsedLicenses":0}
]
```

Knowledge inventory is ten Drafts only. DataStream/Site queries return total=0; Network and
DataSpace were not exposed. GenAiPromptTemplate metadata exists as a capability but its inventory
was empty before/after check-only. Exposure/license counts do not establish activation, credits,
model availability, object rights or actual-user access. No LLM prompt or ingestion ran.
Detailed next approvals: `docs/planning/P7_BATCH3_CAPABILITY_GATES.md`.

## New metadata check-only

Command executed:

```sh
sf project deploy start --dry-run --target-org ng-demo --manifest manifest/p7-batch3-check.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw result excerpts:

```json
{"id":"0Afaj00000p8MduCAE","status":"Succeeded","checkOnly":true,"completedDate":"2026-10-26T03:58:20.000Z","numberComponentsDeployed":1,"numberComponentsTotal":1,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0,"componentFailures":[],"warnings":[]}
```

Only GenAiPromptTemplate NG_Case_Triage succeeded. Its source contains no activeVersionIdentifier
or GenAiPromptTemplateActv metadata and version status is Draft. No grant, agent action or record
write is present. The chosen native default model reference compiles; actual availability/usage
and security remain runtime gates. Subsequent metadata listing returns result=[]: nothing persisted.
Selected raw result fields are in BATCH3_CHECK_ONLY.json; personal creator names/private paths omitted.

## Local checks and preservation

Commands executed:

```sh
python3 scripts/tests/p7_regression_test.py
bash -n scripts/test.sh
bash scripts/test.sh --plan
python3 scripts/tests/check_p7_batch3.py
```

CONFIRMED — raw local test excerpts:

```json
{"status":"PASS","salesforceCalls":0,"apexTestsRerun":0}
{"mode":"PLAN ONLY","orgCallsPerformed":0}
{"status":"PASS","batch3MetadataComponents":1,"promptStatus":"Draft","activePromptVersions":0,"caseInputFields":["Subject","Status","Priority"],"seamNotesIndexed":5,"preservedBatch2SourceHashes":26,"apexTestsRerun":0}
```

Shell syntax check exits zero with no output. Local runner tests prove safe command construction,
ordered execution, fail-fast at each stage, wrong/malformed org denial, non-check-only/incomplete
rejection, DQ passed=false rejection and sensitive-field removal with a fake executor. No live
full regression/DQ run occurred, and no 235-test rerun was needed. `regression.txt` explicitly
labels the local evidence; it is not a fabricated green clean-checkout gate.

The wrapper uses existing verify.sh/phase5.py strict read-only DQ criteria without modification.
Explicit --run requires actual finite storage and an existing workspace evidence file. Accepted
Phase 5 exceptions can still fail the original gate; no silent waiver or corrective record write.
The wrapper omits obsolete destructive changes now that Batch 2 is deployed. Runtime guidance:
`docs/verification/P7_REGRESSION_GATE.md`.

## Exact future approval scope

The only currently deployable new Salesforce metadata is **one Draft GenAiPromptTemplate**
NG_Case_Triage from `manifest/p7-batch3-check.xml`. Deployment would create the draft definition,
not activate a template or agent. No settings, access sets, agent, Data Cloud, Network/CustomSite,
user/Account, Flow, Apex or destructive scope is included. Docs/scripts are local deliverables.

Native agent/platform enablement, provider/usage approval, internal Service identity, Data Cloud
space/credits/source/ingestion/identity rules, Digital Experiences/domain/license/external-user/
relationship sharing and actual runtime demos each require explicit decisions/approvals before
their capability-gated implementation can continue. No nominal External Identity shortcut or
system-mode license bypass is acceptable. A full P7-17 run/clean reviewed source/DQ disposition
also remains due before claiming its release acceptance.

Batch 1 and Batch 2 are not owner-accepted. Batch 1 browser/gallery/event acceptance, page placement,
operational access and VIN credentials remain deferred. Territory model stays Planning with no
Account/User assignments. Phase 6 formal acceptance and documented exceptions are preserved.
