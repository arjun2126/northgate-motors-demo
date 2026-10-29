# Lightweight Phases 1–8 UAT orchestration

## Decision and boundaries

Use **Python standard library → existing scripts/receipts → JSON files → existing UAT register**.
Use OpenCode only for bounded browser observation and owner-approved defect analysis. No agent
framework, scheduler, paid service, dependency install or MCP bridge is needed. No OpenCode
configuration changes. Only `ng-demo` / `00Daj00001Ae3iWEAR` is allowed; never access ng-dev.

The current UAT register supersedes stale handoff/backlog statuses (Live portal, owner-confirmed
My Cases/history, completed P3-DEF-01). Do not reopen CP2 or D01–D04/D15 investigations. The
370-result reconciliation and D01–D04 diagnoses already exist; no suite rerun is appropriate.
Historical evidence is not fresh acceptance. Full acceptance remains BLOCKED.

## Inventory: reuse rather than duplicate

| Existing asset | Reuse / restriction |
|---|---|
| `scripts/tests/{finance_launch_context,test_drive_vehicle_picker,p7_batch1_ui,vehicle_photo_header,p8_batch_b_ui,p8_batch_c_ui,p8_broker_ui}.test.mjs` | Seven dependency-free Node suites, previous 48/48 TAP. Mock/state/static checks, not DOM/persona acceptance. Wrapper provides opt-in batch only. |
| `scripts/tests/p7_regression.py`, `scripts/test.sh`, `p7_regression_test.py` | Existing plan/fail-fast/identity patterns; **do not run --run here**: includes deployment dry-runs and broad tests. |
| `scripts/verify.sh`, `data/scripts/phase5.py verify` | Existing strict read-only DQ; D05 missing canonical `data/csv/01-rooftops.csv`. Do not repeat known failure or regenerate assets. Later supply canonical bundle and exact storage evidence before a separate approved run. |
| `scripts/tests/check_*`, `capture_p8_*`, `verify_p8_*`, `audit_p7_batch2.py` | Existing scoped package/security/source receipts; examine exact script before any reuse. Not all are read-only; historical setup assumptions may be stale. |
| `scripts/tests/p7_vin_mock_test.py`, `scripts/integration/vin_mock_server.py` | Offline VIN transport contract tests, not credential/live decoder acceptance. |
| `data/scripts/tests/`, `package.json` | Generator/loader/refusal tests exist. Do not run broad `data:test`: generation/asset prerequisites and npx install risk; no replacement generator. |
| `scripts/uat/*.apex`, `scripts/persona.sh`, `scripts/portal/create_customer_fixtures.py` | Historical UAT/setup tools can mutate identities/business data. Not wrapped or executed. Names such as probe/dryrun do not imply safety. |
| `scripts/reset.sh`, backfill, deploy/validate helpers | Excluded; even rollback-only Apex and check-only deployment need separate approval. |
| `evidence/UAT/FULL_PROJECT_2026-10-28/{raw,triage,execution_summary.json,UAT_REGISTER.md}` | Authoritative current receipts/defects. Reuse 360 Pass/10 Fail, 48 UI mocks and scoped DQ/CP2/inventory evidence. D15 CLOSED. |
| Python 3.14.8, Node 22.12.0, Salesforce CLI 2.153.5 | Installed; sufficient for harness. `opencode` and `gh` found; gh unnecessary. No standalone `playwright` on PATH (not proof no library exists). |
| OpenCode in-app browser + configured `browsermcp` | Existing browser surfaces; no new bridge. Config presence does not prove extension connectivity. No repository browser E2E runner found in `scripts/`. |

## Coverage by phase and exact criterion mapping

The existing register's **Complete feature checklist** is the authoritative per-criterion map.
Every run exports each grouped backlog ID, current scope and remaining criterion verbatim to
`coverage.json`. The table below assigns execution lanes; multiple lanes are intentional.
**A** = automated (reuse unless affected source changes), **B** = browser-assisted read-only,
**O** = owner-only/gated. No lane assignment changes an acceptance criterion or defect status.

| Phase / criteria | A: automated scope | B: actual persona/browser scope | O: remaining gates |
|---|---|---|---|
| 1: P1-01–22 | Reuse VIN and security subchecks; metadata/matrix receipt review | P1-01–12/14–20 app/layout/record scope, negative Finance FLS, intended tabs | P1-13 bypass, P1-15 licensing, P1-16/17 live invalid/duplicate creates, P1-21 role swap, P1-22 credentials/CI; final matrix sign-off |
| 2: P2-01–15 | Reuse routing/conversion/booking/stage/reservation/counters/bulk; D04 remains FAIL; picker mocks | Existing Sales relationship trail, Tasks, stage history, P2-09–11 source/report/tile comparison | New lead/conversion/booking/reservation, email/inbox, connected P2-14/15 walkthrough; no D04 rerun |
| 3: P3-01–12, DEF-01 | Reuse equity/guards, pricing 23, builder 14, approvals 6, summary 11; saved CP2 arithmetic only | Sales Quote 00000069, existing appraisal/lines/summary, print preview, approval history, stale reports/Quote Health, seam labels | Fresh save/pricing, all tier submissions/approve/reject, >=90% fresh coverage; preserve Pending/history and one-Quote guard; DEF-01 remains closed |
| 4: P4-01–13 | Reuse calc/application/status/rates/approval/delivery/enrollment/FLS receipts; launch mocks | Existing Finance→Quote→Delivery→member, cent values, Sales denial, reports/deal desk/seam | D09 compliant Finance session, live lifecycle/checklist/approval/enrollment writes; coverage certification |
| 5: P5-01–20 | Reuse 8 scoped DQ probes, historical determinism/refusal evidence; strict verifier blocked D05 | Intended-reader report/tile/drill-through parity; exact Storage Usage screenshot; CSI N/A vs zero | Canonical archive/provenance, loads/repeatability, destructive drift/reset/purge/burst, final accepted-exception disposition |
| 6: P6-01–17 | Reuse capacity/intake/history/loyalty/consent/SLA tests; D03 reporting setup BLOCKED | Actual Advisor/manager scope, B existing Visit/Case, timeline, dashboard/CSI, seam labels, console navigation | Service identity, contention, escalation/email and business-hour clocks, loyalty jobs/activation, consent writes, Knowledge publication/Case attachment; P6-E01–E14 retained |
| 7: P7-01–23 | Reuse gallery/calculator/VIN mocks/events/architecture/reconciliation/photo states and historical asset hashes; regression still FAIL | Gallery/header/labels/fallback, mobile/focus, placement, governance/demo/seam review, existing territory inventory only | Live events/reservation contention, credentials/transport, territory activation, Agentforce/Data Cloud, deployment/clean release/coverage/Git and final walkthrough acceptance |
| 8: P8-01–11 (+ comments) | Reuse Live inventory, owner positives and portal state mocks; negative certification BLOCKED D01–03; D06/D07 retained FAIL | B dashboard/vehicles/history/My Cases, A/guest negative viewing, desktop/mobile/keyboard/labels; comments existing response only | Authenticated A/B/guest contexts, entitlement expiry/revocation/live writes, booking/comment submits, loyalty permission fix, final security and owner sign-off |

## Commands: plan → execute → collect → publish → analyze

From repository root (no default-org reliance):

```sh
python3 scripts/uat/orchestrate.py plan --batch reuse
python3 scripts/uat/orchestrate.py run --batch reuse
# Use the exact returned evidence directory, not this placeholder:
python3 scripts/uat/orchestrate.py publish --evidence evidence/UAT/FULL_PROJECT_2026-10-28/orchestration/<run-id>
```

**First batch:** `reuse`. Reads/hashes eight existing receipts, checks historical org/run identity,
360/10/370 reconciliation and 48/48 TAP; exports all criterion groups. No SF/browser calls,
new Apex/UI execution, repeated diagnosis or acceptance upgrade. A collection PASS can coexist
with `historicalUatStatus: FAIL`. Missing/malformed receipts = BLOCKED, not invented success.
SHA256 records bytes at collection time; it is not a retroactive trusted signature or proof that
current source equals the previously tested source. Before reusing results after future changes,
review the affected diff against the original receipt/source snapshot; rerun only impacted checks
after approval. Time/persona-sensitive checks do not become current from cached evidence.

Optional later batches, **not executed during preparation**:

```sh
python3 scripts/uat/orchestrate.py plan --batch local-ui
python3 scripts/uat/orchestrate.py run --batch local-ui
python3 scripts/uat/orchestrate.py plan --batch live-readonly
python3 scripts/uat/orchestrate.py run --batch live-readonly --allow-readonly-org
```

`local-ui` reuses the seven existing suites, capturing raw TAP. `live-readonly` uses only two fixed
SELECTs: identity first, then exact portal Live inventory. It is for an explicitly requested
freshness check, **not** an instruction to repeat existing investigations or a persona test.
Wrong org stops before inventory; no retries. No arbitrary shell/SOQL input or mutating commands.
CLI errors/timeouts/malformed results are BLOCKED; completed assertion mismatch FAIL. Stop and
ask owner; do not repair. Each run writes immutable-by-convention timestamped `results.json`
(stdout/stderr, exit codes, status/scope) and `coverage.json`. Source receipts remain untouched.
`publish` is a separate, idempotent local register append, never a defect close or Salesforce write.

Routine execution needs **zero AI calls**. Owner/operator can run Python directly. Review compact
results first; feed only a new failure's exact output, IDs, source diff and last known-good scope
to OpenCode. Optional `opencode run "..."` is for bounded analysis, not the batch executor; it
consumes model tokens. No autonomous repair/retry agent. Reference D01–D15 rather than duplicate
defects. New defect entries require reproduced expected/actual, persona, timestamp, record ID,
severity, exact receipt and owner decision; never auto-diagnose from a nonzero exit code.

## Browser-assisted execution and limitations

Current non-mutating capability check: `browser.tabs.list` returned `tabs: []` and
`focusedTabID: null`. No authenticated page was inspected. Do not repeat the prior Browser MCP
version-mismatch investigation or assume CLI authentication transfers to browser cookies.
Owner must open this OpenCode session in the desktop app, open ng-demo, and authenticate as the
actual already-provisioned persona. If using the existing Browser MCP instead, owner must connect
its existing extension; connection was **not probed** in this task. No additional bridge/install.
Credentials, MFA and persona selection stay with owner; do not store passwords/session URLs/tokens.

Use register **Ordered owner UAT** steps 1–10, in order, on existing records. For each scenario:
record actual username/persona (not Admin substitute), timestamp, record ID/URL without tokens,
expected/actual, PASS/FAIL/BLOCKED and screenshot path. Save local browser evidence alongside
the run and append a scoped row to the register; do not silently overwrite its original status.

- **Personas:** target an explicit returned tab ID. Verify ng-demo hostname and visible identity
  before observation. Tabs are not independent cookie containers: opening A/B tabs does not
  prove isolation. Use owner-prepared independent contexts or owner-managed sequential sessions
  with verified identity on every transition. No persona.sh, grants or Login As mutation workaround.
- **CP2 first:** Sales session, direct URL from register to Quote `0Q0aj000003kVS5CAM`.
  Assert CAD 50,615 / 43,022.75, one rule, 15%, linked Opp `006aj00000fbDI1AAM`;
  inspect lines and print preview. No Save/Price/Submit. Existing Pending is not a work-item proof.
- **Approvals:** legitimate approver reads history/inbox/ActorId/submitter. No suitable current
  example = NOT TESTED; no Approve/Reject/Recall or Knowledge work-item actions.
- **Reporting:** actual intended readers compare source/report/tile totals with matching filters,
  timestamps and scope. Read Staff lookup target access; stale metrics != zero. No dashboard
  refresh/publisher, report Save, folder/running-user changes or admin-as-reader acceptance.
- **Portal:** B views existing requested Visit `a08aj00001UbaiFAAR` / Case 00001102 and dashboard,
  vehicles/history/My Cases; A/guest inspect known foreign URLs read-only. Retain owner smoke PASS,
  D06 loyalty FAIL and D07 comments FAIL. Capture existing addComment/getComments response only
  if available; do not resubmit to generate traffic. No native Case or Visit writes.
- **Visuals/accessibility:** focused screenshot only when useful; accessibility snapshot/keyboard
  order/labels/focus and owner-set desktop/mobile widths. In-app tools do not promise isolated
  persona contexts or automatic viewport emulation. Use existing network capture for failed
  responses, not browser JS that invokes Apex. Redact auth/cookies/customer data before sharing.

In-app browser supports explicit-tab snapshots, navigation, screenshots, console and bounded
network inspection. Discover exact tool signatures before use. Prefer targeted extraction and
direct URLs; don't stream full DOM/network logs into the model. No current browser PASS claimed.

## Approval gates (all Salesforce mutations denied by this harness)

| Operation | Required separate owner approval before any action |
|---|---|
| Read-only live query / browser observation | Exact ng-demo identity, bounded query/scenario and actual authenticated persona; no implicit refresh/publisher |
| New/updated/deleted records, booking, comments, conversion, save-and-price, approvals, email | Exact synthetic records, identities, fields, expected automations/email, limits, cleanup plan and preservation checks; never canonical/CP2/history rows |
| Apex tests / anonymous Apex / check-only deployment | Exact tests/manifest/target and rollback-fixture/test-result effects. Current authorization includes none; no automatic isolated rerun of D03 |
| Permissions, sharing, role/PSG/profile/user/license or ledger changes | Exact minimum grant/records and persona negative cases, rollback, owner decision. No D06 fix or D02 privilege removal here |
| Deployment / activation / page placement / publication / schedules / integrations | Reviewed exact source manifest and prior validation, explicit release window and independent operational approval; no paid-feature workaround |
| Reset/purge/burst/backfill, seed generation/load | Exact destructive scope, canonical assets, snapshot/restore/storage proof and explicit operation approval; excluded from harness |
| Git commit/push/tag | Separate explicit owner approval; none authorized |

Unexpected failures: stop affected work; report verbatim error/test/IDs, touched files/diff intent,
last verified state and concrete requested owner action. Do not speculate, retry or patch symptoms.
Independent local documentation work may continue. No final phase acceptance without owner sign-off.

## Validation

Run `python3 scripts/tests/uat_orchestration_test.py` for offline guard/collection tests. The
preparation receipt is `evidence/UAT/FULL_PROJECT_2026-10-28/orchestration_validation.txt`.
No dry-run deployment, Apex rerun, live SF query, real browser scenario or existing UI-suite rerun
is needed to validate this local-only wrapper. Those checks are deliberately skipped, not passed.
