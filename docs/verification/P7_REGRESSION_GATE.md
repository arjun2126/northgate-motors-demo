# P7-17 — safe repeatable regression command

Print the exact plan with no org calls:

```sh
bash scripts/test.sh --plan
```

Run the full gate only when a reviewed change/release decision justifies repeating its tests,
with actual observed storage and evidence (replace the example values/path):

```sh
bash scripts/test.sh --run --storage-mb 3.0 --storage-evidence evidence/storage-observation.txt
```

The example is not a claim that current storage is 3.0 MB. The evidence file must exist within
this workspace. NaN/infinite/negative values, missing evidence and non-ng-demo SF_TARGET_ORG
are rejected before org commands. Default invocation is plan-only, not a live release gate.

Ordered full-run steps:

1. Query and verify Organization ID 00Daj00001Ae3iWEAR using explicit --target-org ng-demo.
2. Check-only current Batch 3 draft prompt manifest with NoTestRun.
3. Check-only the deployed Batch 2 application manifest with all 33 specified regression classes,
   including CP2 and affected lifecycle tests. No destructive manifest: obsolete triggers are
   already removed and must never be replayed by a routine regression wrapper.
4. Invoke existing scripts/verify.sh with the supplied storage evidence. Its original strict DQ
   criteria are unchanged. A passed=false body fails even if a subprocess exits zero.

The runner stops at the first unexpected/malformed/incomplete result, wrong org, failed test,
check-only or DQ gate. It never deploys, creates data, repairs fixtures, grants permissions,
activates a site/model, schedules jobs, switches personas or prints credentials. Native --dry-run
is hardwired on both deployment commands; no arbitrary manifest/command argument is accepted.
Each full run writes a timestamped sanitized JSON receipt under evidence/P7; no historical receipt
is overwritten. The live strict checker may fail on accepted Phase 5 exceptions or missing storage
evidence. Such failure is not silently waived; obtain an owner M3 disposition/correction decision.

Local verification uses scripts/tests/p7_regression_test.py with a fake command executor. It
checks command safety/order, fail-fast behavior at every step, wrong/empty org denial, incomplete/
non-check-only rejection, JSON shape, DQ body failure and secret-field removal without Salesforce
or repeated Apex tests. These local checks are not an actual green native release gate.

The repository remains dirty/untracked. Full clean-checkout acceptance, approved DQ disposition
and end-to-end native execution remain open. The unchanged 235/235 test baseline is reused in
this Batch 3 implementation; no concrete reason justified executing those tests again solely
to test this wrapper. Actual native prompt check-only has its own one-component receipt.
