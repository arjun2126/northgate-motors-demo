# Bounded engineering run — <backlog ID / date>

## Authorization and scope

- Mode: read-only investigation / local change / local validation / server validation /
  deployment / operational change / Git operation (list separately).
- Owner approval reference and exact allowed actions/files/target:
- Explicit exclusions and preserved CP2/security/Phase 1–8 behavior:
- Existing plan, decision, UAT/defect IDs and acceptance criteria (link; do not replace):

## Before-state

- Raw `git status --short --branch`, index status, relevant diff and untracked files:
- Task-local content hashes/snapshot (include existing edits/deletions; HEAD alone insufficient):
- Intended harness edit allowlist and reviewed final path→SHA256/null map (not blanket permission):
- Selected required-input set, content vs presence-only claims and validation interval fingerprints:
- Tools/versions; required assets/auth/persona availability (do not log tokens):
- Last verified evidence/date/source scope and reason it remains applicable:

## Planned validation

| Level / check | Exact command / fixed approved target | Expected criterion | Approval / cost / reuse rationale |
|---|---|---|---|
| L0/L1 | | | |
| L2/L3 | NOT AUTHORIZED unless explicitly approved | | |

## Actual evidence

CONFIRMED or REFUTED — <narrow claim, not general acceptance>

```text
$ <exact executed command>
<raw stdout/stderr, exit status; receipt path/hash if long>
```

| Check | PASS / FAIL / SKIPPED | Evidence / reason / actual scope |
|---|---|---|
| Local | | |
| Salesforce tests/auth/metadata validation | SKIPPED | No org authorization by default |
| Actual-persona/browser/security acceptance | SKIPPED | Not proved by mocks/admin |
| Deployment / data / permissions / Git writes | SKIPPED | Separately gated |

### Assumptions / owner-reported facts — not verified evidence

- <statement, source, missing proof>

## Changes and preservation

- Exact created/updated files and intent; scoped before→after diff including untracked files:
- Raw end Git status and index comparison; scoped exact-edit/input preservation result:
- Unrelated concurrent additions/edits/deletions: INFO; attribution unknown unless independently proved:
- Required-input drift: affected results invalidated; no silent ignore/retry or writer interference:
- No unrelated staging, cleanup, reset or business-record/configuration repair:
- Historical receipts and unresolved UAT/accepted exceptions unchanged:

## Disposition

- Local outcome vs project/release acceptance (do not conflate):
- Failures/limitations and [escalation](TRIAGE.md) request, if any:
- Specific next owner decision/task; no automatic retry/deploy/push:
