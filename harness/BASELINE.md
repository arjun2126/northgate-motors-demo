# Local engineering baseline — 2026-10-28

## Scope

HARNESS-ONLY. Preserve existing Phase 1–8 functionality; do not equate that with full phase
acceptance. No Apex/LWC/application metadata edits, org calls, deployment, data/permission changes,
cleanup, staging, commit or push. Never access/modify ng-dev. No dependencies installed.

Initial `git status --short --branch` showed `main...origin/main`, extensive modified/deleted
application files and untracked source, evidence, data and documents. Preserve all of it.
A session-local SHA256 snapshot of 6,520 tracked/unignored paths was captured outside the repository
before edits; it is a task preservation check, not a trusted release baseline or live-source parity.
Future runs must capture their own before-state; do not rely on that temporary file surviving.

## Concurrent worktree preservation (current policy)

The owner confirms three concurrent workstreams share this dirty tree. The initial ad hoc
`changed == ['AGENTS.md']` assertion was unnecessarily strict: unrelated source drift is not
proof of this workstream's edits or corruption. Its historical failure remains in
[VALIDATION.md](VALIDATION.md); the owner's correction supersedes the request to pause writers.
Do not interfere with Expansion or UAT work or assign modification origins without evidence.

`harness/preservation.py` now separates:

- **Intended harness edits:** explicit reviewed path→SHA256/null map compared with a pre-edit
  flat content snapshot. Only the declared harness namespace/root navigation files are eligible;
  unexpected harness additions or mismatched final hashes FAIL. This is an exact content check,
  not automatic semantic review or writer attribution. Inspect the before→after diff first.
- **Validation interval:** `check.sh` captures harness files, transitive scripts, reused receipts,
  and selected UI/metadata test inputs before executing checks; verifies them afterward. Hashes,
  file identity, mode and nanosecond timestamps detect rewrites (including restored bytes).
  Missing/unreadable/symlinked/unstable protected inputs or changed protected fingerprints FAIL.
- **Presence-only dependencies:** matrix inventory/link targets and D08 field definitions are
  existence claims only. Their disappearance FAILs; content changes alone are informational
  unless a selected test also reads those bytes. No Apex logic/source-parity claim is made.
- **Unrelated drift:** additions, edits and deletions outside protected/required inputs are
  `INFO`, attribution `unknown`, and do not fail preservation. No rollback, staging or cleanup.

Example task-edit review (the JSON files are operator-created outside the repository):

```sh
python3 -B harness/preservation.py edits --before /path/to/pre-edit-content.json --expected /path/to/reviewed-harness-hashes.json
```

The before JSON maps all observed repository paths to SHA256 (or null for missing paths); expected
maps only reviewed intended harness changes to exact final SHA256 (null only for approved removal).
The helper uses read-only `git ls-files`, not HEAD equality, and fingerprints untracked files too.
It accepts no executable command/target. `capture --output` only writes an empty external temporary
file; `verify --snapshot` is read-only. `check.sh` removes only its own temporary snapshot on exit.

Selected-input declarations live alongside the helper; extend them when tests start reading new
files. UI modes protect the selected component bundles, not the entire application. Full/D08
protect the files read through the historical preservation receipt. Fast/focused-harness mode
does not consume portal LWC bytes and therefore does not fail on their concurrent changes.

Limitations: endpoint collection is not atomic and is not a file lock, filesystem audit or proof
of who wrote a file. It cannot rule out changes after verification or every change-and-restore
attack. Required ignored files are included explicitly; other ignored files are not inventoried.
Tool binaries/standard libraries and undeclared new dependencies are not fingerprinted. Results
apply to the captured interval/declared inputs, not to all future working-tree states. Input drift
requires a new approved affected run or stable snapshot, not silent PASS, automatic retry or a
request to stop unrelated workstreams. No expensive tests are automatically repeated.

## Existing authority and infrastructure

- [Execution guide](../PLANS.md) links the original master plan/backlog/handoff, not replacements.
- [Governance](../docs/GOVERNANCE.md), architecture seam/ownership/broker notes, permission matrix,
  technical debt and current UAT remain authoritative for their scoped decisions.
- [UAT register](../evidence/UAT/FULL_PROJECT_2026-10-28/UAT_REGISTER.md) and adjacent raw/triage
  receipts record the latest consolidated acceptance; later appendices matter.
- [UAT orchestrator](../scripts/uat/orchestrate.py) already separates receipt reuse, local UI,
  gated live SELECTs and optional register publication. This harness reuses its functions/tests
  without generating/publishing new UAT entries.
- [Regression wrapper](../scripts/test.sh) plans by default; `--run` includes server dry-runs,
  broad tests and strict DQ. **Not invoked here.** Existing regression guard tests are offline.
- [DQ wrapper](../scripts/verify.sh) is read-only but requires live approval and canonical assets.
- [Package scripts](../package.json) contain data tooling, not a general LWC Jest/lint pipeline.
  `npx` may install and generator tests may write assets; broad `data:test` is excluded.
- Existing CI [workflow](../.github/workflows/validate.yml) is manual-dispatch and targets ng-dev.
  It is incompatible with current rules: **do not dispatch/enable it**. No CI changes here.

## Historical evidence, not results of this retrofit

- Run `707aj00001OOD4U`: 370 results, 360 Pass / 10 Fail, including failed TestSetup.
  D01 clock fixture; D02 ambient reviewer identity; D03 setup locks; D04 email invocation
  expectation. Production authorization bypass was not demonstrated; negative certification is
  still incomplete. Do not rerun or edit these tests without approval.
- Seven local UI/state suites recorded 48/48; mocks are not browser acceptance.
- Strict DQ blocked by missing `data/csv/01-rooftops.csv` (D05); eight scoped probes do not
  replace the strict gate, exact storage or provenance reconciliation.
- Portal positive owner observations retained; D06 loyalty and D07 comments remain unresolved.
  D08 local/validation/deployment receipts do not establish browser fixes or close defects.
- P5/P6 owner acceptance with exceptions remains intact; P7/P8 and full project acceptance
  remain incomplete. Do not rewrite historical receipts or force historical counts.

## Running and interpreting local checks

```sh
bash harness/check.sh                       # fast: docs, syntax, receipt consistency, offline guards
bash harness/check.sh focused portal        # fast + selected existing Node state/static suites
bash harness/check.sh full                  # fast + all allowlisted local UI/presentation checks
```

Other focused areas: `finance`, `inventory`, `presentation`, `harness` (fast only).
All modes are offline and use installed Python 3.10+; UI modes need Node 22+ per project engines.
No automatic install, `sf`, arbitrary command/target, shell evaluation or Git write path exists.
Exit 0 = selected available local checks passed, with omissions explicitly SKIPPED; 1 = failed
check, stop; 2 = invalid usage or missing required Python. Missing optional Node is SKIPPED,
not a UI pass. Output always distinguishes local success from full release acceptance.

Salesforce CLI/authentication/org availability is **not probed**. All server/browser/deployment
checks are SKIPPED regardless of authentication; absent auth must never be inferred as success.
For a future separately approved server run, verify fixed ng-demo org ID first and follow the
[matrix](REGRESSION_MATRIX.md) and [triage](TRIAGE.md); never change records/config to pass.

Current retrofit execution evidence belongs in [VALIDATION.md](VALIDATION.md), kept separate
from historical UAT evidence. Raw stdout/stderr and scoped preservation results are recorded there.
