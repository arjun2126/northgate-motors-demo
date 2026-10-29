# Retrofit validation evidence — 2026-10-28

Local harness only. No historical UAT status is changed. Salesforce authentication, Apex,
deployment dry-runs, strict DQ and actual browser/persona acceptance are SKIPPED, not passing.
No dependency install or org call was performed by this task.

**Historical disposition (superseded by owner concurrent-worktree correction below): local fast/full checks passed at execution time; retrofit sign-off BLOCKED by
unexpected out-of-scope source changes detected afterward.** No rerun or corrective application
edit performed. These receipts do not certify the subsequently changing tree.

## Actual checks

CONFIRMED — raw default-entry output excerpts (`bash harness/check.sh`, exit 0):

```text
LOCAL ONLY: mode=fast focus=harness
CHECK: entry-point Bash syntax
PASS: entry-point Bash syntax
Required documents and local links: 9 checked
Matrix inventory: 52 Apex and 11 local test files exist (not execution proof)
Python source syntax: 6 checked; no bytecode written
Receipt consistency: PASS; 8 receipts; 91 criterion groups
Historical Apex: 360 Pass / 10 Fail; NOT rerun
Historical UAT: FAIL; no acceptance upgrade
Ran 12 tests in 0.003s

OK
Ran 3 tests in 0.114s

OK
SKIPPED: local UI checks not selected; use focused AREA or full
SKIPPED: presentation metadata checks not selected
SKIPPED: Salesforce CLI/auth/org availability not probed; no org access authorized
SKIPPED: Apex, metadata dry-run, strict DQ, browser/persona acceptance; separately gated
SKIPPED: deployment, data/configuration changes and Git writes; never performed by this entry point
PASS: selected available LOCAL checks only; review SKIPPED lines. Full project acceptance remains BLOCKED.
```

CONFIRMED — raw full-entry output excerpts (`bash harness/check.sh full`, exit 0):

```text
LOCAL ONLY: mode=full focus=harness
PASS: entry-point Bash syntax
Required documents and local links: 9 checked
Matrix inventory: 52 Apex and 11 local test files exist (not execution proof)
Python source syntax: 6 checked; no bytecode written
Receipt consistency: PASS; 8 receipts; 91 criterion groups
Historical Apex: 360 Pass / 10 Fail; NOT rerun
Historical UAT: FAIL; no acceptance upgrade
Ran 12 tests in 0.003s

OK
PASS: existing offline UAT orchestration guards
{
  "status": "PASS",
  "checks": [
    "safe explicit commands",
    "ordered four-step gate",
    "fail-fast at each step",
    "wrong-org denial",
    "non-check-only/incomplete rejection",
    "DQ false remains failure",
    "sensitive field removal"
  ],
  "salesforceCalls": 0,
  "apexTestsRerun": 0
}
PASS: existing offline regression runner guards
Ran 3 tests in 0.054s

OK
PASS: entry-point safety contract (offline)
1..58
# tests 58
# suites 0
# pass 58
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 124.907667
PASS: selected existing local UI mocks/static checks (not browser)
Ran 4 tests in 0.009s

OK
PASS: existing D08 local metadata checks (not server validation)
SKIPPED: Salesforce CLI/auth/org availability not probed; no org access authorized
SKIPPED: Apex, metadata dry-run, strict DQ, browser/persona acceptance; separately gated
SKIPPED: deployment, data/configuration changes and Git writes; never performed by this entry point
PASS: selected available LOCAL checks only; review SKIPPED lines. Full project acceptance remains BLOCKED.
```

Complete merged stdout/stderr receipts are session-local, outside the repository:

```text
/private/var/folders/82/d8xptlz976z981kdf1yg_k3c0000gn/T/opencode/northgate-harness-fast.txt
SHA256 35365a0ce219d01c39b60a22df1595d1a2e843092761943834d45feb60112905
/private/var/folders/82/d8xptlz976z981kdf1yg_k3c0000gn/T/opencode/northgate-harness-full.txt
SHA256 9d64d48e71dbd741cef84c0e0df114d7b02df721ec40eba59fa4c9bcce047dfa
```

These temporary files are not guaranteed to survive the session; the excerpts above are retained
repository evidence. No expensive Salesforce suite was repeated. Focused routing branches were
not separately executed; full ran their union once. Help/invalid arguments were exercised by the
three entry-point tests (including outside-root invocation and a forbidden default-org environment).
No missing-dependency simulation was executed; Node/Python were installed. CLI presence was
observed with local PATH lookup only, not authenticated or invoked.

CONFIRMED — raw versions:

```text
python3 --version: Python 3.14.8
node --version: v22.12.0
```

## Preservation stop / escalation

REFUTED — whole-tree preservation assertion against the initial 6,520-path snapshot.
The ad hoc before/after check asserted `changed == ['AGENTS.md']` and exited 1:

```text
Traceback (most recent call last):
  File "<stdin>", line 24, in <module>
AssertionError
```

CONFIRMED — raw `nonHarnessExistingChanges` output:

```json
[
  "force-app/main/default/lwc/ownerPortalAppointment/ownerPortalAppointment.css",
  "force-app/main/default/lwc/ownerPortalAppointment/ownerPortalAppointment.html",
  "force-app/main/default/lwc/ownerPortalCases/ownerPortalCases.css",
  "force-app/main/default/lwc/ownerPortalCases/ownerPortalCases.html",
  "force-app/main/default/lwc/ownerPortalHistory/ownerPortalHistory.css",
  "force-app/main/default/lwc/ownerPortalHistory/ownerPortalHistory.html",
  "force-app/main/default/lwc/ownerPortalHome/ownerPortalHome.css",
  "force-app/main/default/lwc/ownerPortalHome/ownerPortalHome.html",
  "force-app/main/default/lwc/ownerPortalLoyalty/ownerPortalLoyalty.css",
  "force-app/main/default/lwc/ownerPortalLoyalty/ownerPortalLoyalty.html",
  "force-app/main/default/lwc/ownerPortalVehicles/ownerPortalVehicles.css",
  "force-app/main/default/lwc/ownerPortalVehicles/ownerPortalVehicles.html"
]
```

New out-of-scope paths were also observed under
`evidence/UAT/FULL_PROJECT_2026-10-28/REGRESSION_CLOSURE/` (query/retrieve/source evidence).
This task wrote none of those application/evidence paths. Concurrent work is a possible cause,
not a verified attribution. Nothing was reverted, investigated further, staged or repaired.

**Changes made by this task:** additive 25-line AGENTS rules; new PLANS, architecture/decision
navigation, baseline, regression matrix, run template, triage, local entry point, entry-point tests
and this evidence file. No existing application/test/tooling file was edited.

**Last verified state:** the raw fast/full local outputs above; no claim they match the later
source bytes. Initial snapshot remains at the session-local
`/private/var/folders/82/d8xptlz976z981kdf1yg_k3c0000gn/T/opencode/northgate-harness-before.json`.

**Historical owner-action request (superseded; do not pause concurrent workstreams):** confirm whether another session/operator is writing the listed portal
files and REGRESSION_CLOSURE evidence, then pause that writer or provide an approved stable
source snapshot. Authorize a new preservation baseline and affected local checks only afterward.
Do not revert those changes or rerun broad Salesforce tests as a workaround. Wait for owner
response before resuming preservation/validation sign-off.

## Git status / scoped diff at the stop

CONFIRMED — raw branch, overall status counts (untracked directories collapsed), index output
and tracked scoped diff stat:

```text
## main...origin/main
{" D": 8, " M": 67, "??": 560}
"stagedPaths": []
 AGENTS.md | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)
```

CONFIRMED — raw task-scoped status (untracked expanded):

```text
 M AGENTS.md
?? PLANS.md
?? docs/architecture/OVERVIEW.md
?? docs/decisions/STATUS.md
?? harness/BASELINE.md
?? harness/REGRESSION_MATRIX.md
?? harness/RUN_TEMPLATE.md
?? harness/TRIAGE.md
?? harness/VALIDATION.md
?? harness/check.sh
?? harness/test_check.py
```

The tracked stat excludes ten new untracked harness files. Existing dirty-tree changes remain
separate; no commit/push/cleanup occurred. This evidence-file update is documentation-only after
the stop; no validation was rerun afterward. Full project acceptance and retrofit sign-off are
not claimed.

## Owner-authorized concurrent-worktree correction

The owner confirms intentional shared workstreams. The original assertion was an overly broad
task-attribution assumption, not a harness unit-test failure or evidence of corruption. The 12
portal files and REGRESSION_CLOSURE evidence are consistent with other work, but exact writers
remain **unknown**. Historical outputs above are preserved; no UAT evidence or application changed
by this correction. The earlier request to pause writers is withdrawn, not executed.

Current correction: exact intended harness edits are compared separately from unrelated INFO
drift; protected harness files and selected tests' required inputs are frozen over validation
intervals. Missing/drifting inputs FAIL rather than being silently ignored. New synthetic tests
exercise concurrent additions/changes/deletions, exact scope/hash checks, input drift/restoration,
ignored required inputs and unknown attribution. Actual correction results follow below.

### Correction checks — CONFIRMED

Raw `python3 -B harness/test_preservation.py` excerpt (exit 0):

```text
Ran 14 tests in 0.005s

OK
```

Raw `bash harness/check.sh focused harness` excerpts (exit 0):

```text
LOCAL ONLY: mode=focused focus=harness
CHECK: capture scoped validation inputs (read-only worktree)
{
  "status": "PASS",
  "requiredInputCount": 28,
  "conflicts": []
}
PASS: capture scoped validation inputs (read-only worktree)
PASS: entry-point Bash syntax
Required documents and local links: 9 checked
Matrix inventory: 52 Apex and 11 local test files exist (not execution proof)
Python source syntax: 8 checked; no bytecode written
Receipt consistency: PASS; 8 receipts; 91 criterion groups
Historical Apex: 360 Pass / 10 Fail; NOT rerun
Historical UAT: FAIL; no acceptance upgrade
Ran 12 tests in 0.003s

OK
PASS: existing offline UAT orchestration guards
PASS: existing offline regression runner guards
Ran 3 tests in 0.085s

OK
PASS: entry-point safety contract (offline)
Ran 14 tests in 0.004s

OK
PASS: scoped concurrent-worktree preservation contracts (offline)
SKIPPED: local UI checks not selected; use focused AREA or full
SKIPPED: presentation metadata checks not selected
SKIPPED: Salesforce CLI/auth/org availability not probed; no org access authorized
SKIPPED: Apex, metadata dry-run, strict DQ, browser/persona acceptance; separately gated
SKIPPED: deployment, data/configuration changes and Git writes; never performed by this entry point
CHECK: scoped preservation; unrelated drift is informational, attribution unknown
{
  "status": "PASS",
  "conflicts": [],
  "acceptedHarnessEdits": [],
  "informationalChanges": [],
  "attribution": "unknown",
  "requiredInputCount": 28,
  "limitation": "Endpoint fingerprints are not an atomic snapshot or writer attribution; results apply only to recorded inputs at this interval. No automatic retries."
}
PASS: scoped preservation; unrelated drift is informational, attribution unknown
PASS: selected available LOCAL checks only; review SKIPPED lines. Full project acceptance remains BLOCKED.
```

The existing regression-runner fake-result assertions also passed (same seven safety contracts
shown in the historical full output). Existing safety checks were not removed or weakened.
No UI/application tests or expensive server suites were repeated in this correction.

Raw task-edit preservation invocation (exit 0):

```text
python3 -B harness/preservation.py edits --before /private/var/folders/82/d8xptlz976z981kdf1yg_k3c0000gn/T/opencode/northgate-correction-before.json --expected /private/var/folders/82/d8xptlz976z981kdf1yg_k3c0000gn/T/opencode/northgate-correction-expected.json
```

Raw output excerpt:

```json
{
  "status": "PASS",
  "conflicts": [],
  "acceptedHarnessEdits": [
    "AGENTS.md",
    "PLANS.md",
    "harness/BASELINE.md",
    "harness/REGRESSION_MATRIX.md",
    "harness/RUN_TEMPLATE.md",
    "harness/TRIAGE.md",
    "harness/VALIDATION.md",
    "harness/check.sh",
    "harness/preservation.py",
    "harness/test_preservation.py"
  ],
```

Raw informational-change excerpts from that same output (no writer assignment):

```json
    {
      "path": "evidence/UAT/FULL_PROJECT_2026-10-28/REGRESSION_CLOSURE/convert-d06.json",
      "attribution": "unknown",
      "status": "INFO"
    },
```

```json
    {
      "path": "scripts/tests/p8_portal_presentation.test.mjs",
      "attribution": "unknown",
      "status": "INFO"
    }
```

The complete first edit comparison reported ten REGRESSION_CLOSURE paths and the new portal
presentation test as informational drift. None were inputs of the focused-harness run. No portal,
Apex, application metadata or UAT evidence was edited by this task. No attribution is inferred
from the filenames. The corrected checks did not pause other workstreams or touch the index.

Session-local complete receipts (not guaranteed to survive the session):

```text
/private/var/folders/82/d8xptlz976z981kdf1yg_k3c0000gn/T/opencode/northgate-correction-focused.txt
/private/var/folders/82/d8xptlz976z981kdf1yg_k3c0000gn/T/opencode/northgate-correction-preservation.txt
```

### Correction readiness and limits

The local harness is ready for concurrent-worktree use within its declared input boundaries.
The original whole-tree sign-off block is superseded, not relabeled as a historical pass.
Exact writer attribution, atomic filesystem snapshots, all future source states and undeclared
dependencies remain unverified. Presence-only claims do not certify Apex/source behavior.
Full local UI/presentation and Salesforce/browser validation were SKIPPED in this correction;
the previous full run is historical only. Required-input drift still FAILs an affected run.

This result-document update occurred after the focused run and does not change executed code.
The final task-edit hash comparison is repeated after recording this output; no tests are
automatically repeated. Current application/full-project acceptance remains outside this result.
