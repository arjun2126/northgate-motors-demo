# Northgate Motors — Git recovery checkpoint (2026-10-28)

## Purpose

This record accompanies the local Git recovery and source-preservation pass. It separates
**deployed**, **validated**, **locally implemented**, **owner-accepted** and **outstanding**
states. It is not a release tag, deployment record or acceptance claim.

## Recovery identifiers

| Item | Value |
|---|---|
| Original `HEAD` | `0423863794b70bb13c3c59128f7b57a0313aa0f4` (`0423863`) |
| Original remote `origin/main` | `0423863794b70bb13c3c59128f7b57a0313aa0f4` |
| Recovery branch | `main` (local only; not pushed) |
| Final local checkpoint | The commit containing this file |
| Backup archive | `/Users/arjunsubramanya/Documents/NorthgateRecoveryBackups/20261028T224027/northgate_repo_full.tar.gz` |
| Backup SHA-256 | `feaf68d381808e0c9444c44e2fffe2c908b4f2aeac1d450a5847ac6bd73111a0` |
| Git history bundle | `repo_history_all_refs.bundle` in the same backup directory |
| Bundle SHA-256 | `240937e5894aa1996d1c1fc26280a61b9d82e5a382d0cff8859edd0ebca17b39` |
| Backup verification | Archive/gzip test, bundle verification, reverse tracked-patch check and representative restore hashes all passed |

The backup excludes only `.sf/`, `.sfdx/`, `.freebuff/`, `.vscode/`, `node_modules/`,
`__pycache__/`, `*.pyc`, `.DS_Store`, `.key` and `.env`. It includes the complete working tree,
`.git`, the 6,198 untracked files, the 67 modified tracked files, the 8 intentional deletions,
a full status inventory, a binary tracked-change patch and a SHA-256 file manifest.

## Recovery commits

| # | Commit | Scope |
|---|---|---|
| 1 | `6d03bf4` | P2–P4 source dependencies missing from `HEAD`, including `QuotePricingService`, quote/trade-in guards, `QuoteTrigger`, Flows, 31 Rate Table records, Financing actions, workflow updates and `Funding_Lag` |
| 2 | `543df40` | Phase 5 reporting/data-quality metadata, management dashboards, booking dependencies and P2–P5 tracked-source reconciliation |
| 3 | `b2e3e98` | Phase 6 service, loyalty, consent, Knowledge metadata, Case automation and related tests |
| 4 | `46de6ce` | Phase 7 inventory/gallery, VIN, photos/attribution, territory, trigger architecture and the four intentional trigger removals |
| 5 | `360dd07` | Phase 8 owner-portal runtime, ownership/broker services, security metadata, profile and shared layouts |
| 6 | `c7bde01` | Current portal presentation, Aura theme/content layouts, D08 UI corrections, Executive dashboard and `NG_Overview` list views |
| 7 | `7a311c1` | Harness Engineering, UAT/regression tooling, scoped manifests, Phase 5 data generator/loader source and small fixtures |
| 8 | `a863574` | README, execution guide, handoff, architecture/decisions/security/planning documentation and root project metadata |
| 9 | `4128d25` | Curated deployment/test evidence, UAT register, rollback snapshots and post-deployment verification metadata |
| 10 | this commit | Generated-file exclusions and this status record |

## State separation

### Deployed and recorded

- Phases 1–4 are committed at the original `HEAD`; Phase 4 remains the last committed milestone.
- Phase 5 controlled release and reporting/data-quality work are deployed with documented exceptions.
- Phase 6 is deployed and owner-accepted **with documented exceptions** (2026-10-24).
- Phase 7 batches 1–4 and territory package are deployed; **Phase 7 is not fully owner-accepted**.
- Phase 8 development package `0Afaj00000pPottCAC`, broker, dashboard-runtime permission and
  service-history/My-Cases FLS corrections are deployed; **Phase 8/M4 is not fully accepted**.
- D08 nine-component presentation package was deployed as `0Afaj00000paG2TCAU`.
- D16 is closed after owner visual acceptance.
- D06 permission correction was deployed as `0Afaj00000pafVVCAY`; functional/security acceptance
  remains open.
- Initial six-LWC portal visual refresh was deployed as `0Afaj00000paKE9CAM`.

### Locally implemented / not confirmed deployed

- The 2026-10-28 Owner Portal structural theme/content layout redesign passed dry-run
  `0Afaj00000pYhI8CAK` but deployment was **not confirmed**. The Aura layouts and current
  `ownerPortalHome` shell must be treated as **LOCAL-ONLY**.
- D08-d photo-mapping correction remains pending exact Vehicle/component/image evidence.
- Vehicle Studio and Staff Workspace are **not implemented**.
- Canonical `data/csv/` remains absent. Generated `data/csv-resolved/` and `data/prepared/`
  outputs are excluded from Git and are not a substitute for the canonical bundle.

### Known source-control limits

- Experience Cloud `Network`, `CustomSite` and `NavigationMenu` metadata are **not present in
  `force-app/`**; they remain evidence-only under `evidence/P8/`.
- Knowledge articles exist as local draft JSON in `docs/knowledge/` and as in-org Drafts; no
  article was published or attached as grounding.
- P8 customer identities, memberships, shares, ledger rows and site publication are org/data
  state, not source. No Salesforce data was read or changed during this recovery.
- P7 VIN named-credential/principal/transport remains unverified and is not represented as a
  working live integration.
- Phase 7 and Phase 8 remain not fully owner-accepted. No release tag was created.

## Evidence exclusions

The following remain in the working tree/backup but are intentionally not in Git:

- `.sf/`, `.sfdx/`, CLI auth state, `.freebuff/`, `.vscode/`, caches, `.DS_Store`, `__pycache__`.
- `retrieved/`, `retrieve_tmp/`, `retrieve_tmp_flow/`, `retrieved_profile/`, `backup_flows/`.
- 89 root Data Loader `750*-success-records.csv` / `failed-records.csv` outputs.
- `data/csv-resolved/`, `data/prepared/`, `data/automation-snapshots/` and automation logs.
- Large P8 before/after permission dumps, raw permission JSON, site byte diffs, ZIP archives and
  customer/password/reset/auth investigation receipts.
- Duplicate source archives under `evidence/P7` and `evidence/P6`.

## Validation performed

- Archive integrity and restore verification: PASS.
- Git bundle verification: PASS.
- Tracked-change reverse-applicability check: PASS.
- Commit 1: 58 files, 0 deletions.
- Commit 2: 96 files, 0 deletions.
- Commit 3: 181 files, 0 deletions.
- Commit 4: 105 files, 8 intentional deletions.
- Commit 5: 66 files, 0 deletions.
- Commit 6: 41 files, 0 deletions.
- Commit 7: 170 files, 0 deletions.
- Commit 8: 92 files, 0 deletions.
- Commit 9: 294 files, 0 deletions.
- No Salesforce CLI org authentication, deployment, data change, permission change, browser UAT
  or Apex test execution was performed by this recovery.
- No GitHub push, tag, reset, clean, rebase, cherry-pick or force operation was performed.

## Remaining release blockers

- Phase 7 browser/gallery/photo/page/territory and full regression acceptance.
- Phase 8 operational customer UAT, portal structural-layout deployment/Builder save/publication,
  loyalty/comments defects, cross-customer/guest negative certification and visual acceptance.
- D06 functional/security acceptance; D07 submit/refresh response evidence; canonical D05 assets;
  D09 persona readiness; D08 remaining visual checks.
- Site metadata retrieval/decision, Knowledge publication decision and canonical data restoration.
- Owner authorization for any GitHub push or release tag.
