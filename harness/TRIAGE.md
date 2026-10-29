# Stop-and-escalate protocol

Follow [AGENTS.md](../AGENTS.md). Unexpected test/deploy failures, mangled commands/identifiers
or uncertain diagnosis stop the affected line immediately. No speculative retries or unapproved
corrective edits. Independent, non-blocked local documentation may continue.

## Concurrent worktree, not automatic corruption

Expansion and UAT intentionally share this tree. Unrelated concurrent modifications are INFO,
with unknown attribution, not a preservation failure. Do not pause/interfere with other streams
or infer a writer from path names. The original whole-tree assertion is superseded by
the [scoped policy](BASELINE.md). A protected harness conflict or required-input change still
FAILs the affected validation: preserve raw fingerprints/path, invalidate that result, and request
bounded owner review or an approved stable snapshot/affected rerun. Never silently waive input
drift, auto-retry, reset, clean, overwrite, or weaken checks. Legitimate input changes are not
evidence of corruption or an application defect.

## Escalation packet

1. **Exact error:** raw stdout/stderr, exit status, test class/method/stack, run/result/org IDs and
   command. Do not paraphrase away evidence; redact credentials, not relevant failure details.
2. **Changes made:** exact files and diff intent, separated from pre-existing work. No automatic
   rollback/discard of user work. No test expectation weakening, grants or data cleanup.
3. **Last verified state:** raw evidence/date, source scope, actual persona and what remains
   unverified. Historical PASS is not a fresh run; mocks/collection are not live acceptance.
4. **Specific owner action:** exact bounded command/click or explicit approval decision needed.
   Then wait before continuing the affected line. Do not execute the proposed action yourself.

## Existing failures: reuse, do not rediscover

The [current register](../evidence/UAT/FULL_PROJECT_2026-10-28/UAT_REGISTER.md) and its raw/triage
receipts already contain the authoritative diagnoses. Reference D IDs rather than duplicate them.

| Existing item | Safe next owner decision, not an instruction to execute |
|---|---|
| D01 | Approve deterministic same-Toronto-day capacity fixture and explicit cross-day case; preserve production capacity/broker behavior |
| D02 | Approve explicit restricted runAs identities and reviewer positive case; never revoke a legitimate assignment to satisfy ambient-user assertions |
| D03 | Approve bounded isolated/serial verification of existing setup locks; success is not guaranteed, no repeated attempts |
| D04 | Approve observable notification-contract diagnosis; invocation counter is not delivery evidence. Never simply change expected 0 to 1 |
| D05/D11 | Owner supplies canonical approved CSV archive and exact Storage Usage evidence; no regeneration/reload/backfill to force parity |
| D06/D07 | Separate least-privilege loyalty fix decision / missing comment submit-versus-refresh response evidence; no duplicate customer submits or speculative grants |
| D08/D12 | Inspect exact presentation/reader/viewport evidence and later receipts; deployment does not close browser defects or accepted CSI exception |
| D09/D10/D13/D14 | Owner supplies compliant actual personas and operational/capability/acceptance decisions; no admin reclamation, role swap, activation or release workaround |
| D15 | Closed reconciliation; preserve 370 = 360 Pass + 10 Fail, do not rerun to reconcile again |

Missing local dependency is **SKIPPED**, not PASS; record the exact missing prerequisite and ask
before installation. Missing Salesforce authentication/org access blocks server claims; never
fall back to another org or ng-dev. `harness/check.sh` intentionally performs no auth probe.
If required local structure fails, report FAIL and stop; do not silently create placeholder
evidence. A known historical failure displayed during successful receipt collection is not a
new execution failure and is not permission to reopen that investigation.
