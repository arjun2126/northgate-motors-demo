# Local Phase 2/5 implementation checks — 2026-10-20

No Salesforce data writes or actual deployments were performed.

## Offline checks

Command:

```sh
NG_TEST_TMP=<approved-temporary-directory> PYTHONDONTWRITEBYTECODE=1 python3 data/scripts/tests/test_phase5_preparation.py -v
```

Raw test output:

```text
test_drift_alarm (__main__.PreparationTest.test_drift_alarm) ... ok
test_full_acceptance_cannot_pass_missing_legacy_or_ledger (__main__.PreparationTest.test_full_acceptance_cannot_pass_missing_legacy_or_ledger) ... ok
test_generator_determinism_without_touching_canonical (__main__.PreparationTest.test_generator_determinism_without_touching_canonical) ... ok
test_ledger_never_labels_updates_as_inserts (__main__.PreparationTest.test_ledger_never_labels_updates_as_inserts) ... ok
test_legacy_shape_and_isolation (__main__.PreparationTest.test_legacy_shape_and_isolation) ... ok
test_original_count_conflict_cannot_pass (__main__.PreparationTest.test_original_count_conflict_cannot_pass) ... ok
test_snapshot_refusals (__main__.PreparationTest.test_snapshot_refusals) ... ok
Ran 7 tests in 0.825s
OK
```

Generator check performs two same-anchor runs in isolated directories and compares all
30 CSV hashes. It also asserts canonical CSV and SEED_VERSION hashes did not change during
the check. Legacy fixture output was then prepared locally (not loaded):

```json
{"prepared":{"Contact":24,"Trade_In__c":6},"executed":false}
```

`bash -n` for reset/verify wrappers, scoped `xmllint --noout`, and `git diff --check`
returned no errors. XML well-formedness does not establish Salesforce metadata validity.

## Native check-only

- Phase 2 `0Afaj00000oPyx5CAC`: FAILED, checkOnly=true, 4 components, 3 errors.
  ConvertLeads requires EditTask; dependent rep group fails; Flow entry navigation invalid.
- Phase 5 `0Afaj00000oPzQ6CAK`: FAILED, checkOnly=true, 15 components, 6 errors.
  Two legacy report errors and four metric dashboards missing indicatorLowColor.

Exact native errors and component names are preserved in
`docs/planning/P2_P5_IMPLEMENTATION_2026-10-20.md`. No corrective retries or real deploy
followed. Original P5 acceptance is not passed by these offline tests.
