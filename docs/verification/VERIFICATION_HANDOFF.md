# Verification/UAT Agent Handoff — project-wide verification

**Owner-committed scope.** Run by a dedicated verification agent once the **entire project**
is complete (all phases, latest `DEMO_ORG_BACKLOG.md` = scope authority). This file is the
single handoff. Validation is planned now; nothing below executes here.

**Baseline docs:** `DEMO_ORG_BACKLOG.md` (scope authority), `BUILD_STATUS.md`,
`docs/architecture/AUTOMATION_DIRECTION.md`, `docs/architecture/EXPERIENCE_PORTAL.md`,
`DEMO_ORG_MASTER_PLAN.md`,
`DEMO_ORG_DATA_MODEL.md`, `DEMO_ORG_SYNTHETIC_DATA_PLAN.md`, `DEMO_ORG_SETUP_CHECKLIST.md`,
`metadata-log/ORG_INFO.md`, `metadata-log/README.md`, `docs/TECH_DEBT.md`,
`docs/VERIFY_RESULTS.md`, `evidence/P0..P8`, `evidence/UAT/*`.

---

## 1. Operating rules (binding)

1. **Default target: ng-dev only.** Before any command, verify alias, username, and org ID:
   `sf org display --target-org ng-dev` → alias `ng-dev`, username `arjun.ngdev@northgate.demo`,
   org ID matching `metadata-log/ORG_INFO.md`. Abort on mismatch. Never touch ng-demo.
2. **Read-only first.** Inspection (metadata retrieve, SOQL of *existing* data, `sf org display`,
   git/tag inspection) needs no approval. Anything that *creates, updates, deletes records*,
   switches personas, changes permissions, grants bypass, deploys, or runs productive Apex
   tests against the org requires explicit approval.
3. **Preflight is read-only and aborts on drift.** Inspect `Automation_Settings__c`
   (`Bypass_Validation__c`/`Bypass_Flows__c`/`Bypass_Triggers__c`) and permission assignments
   (`PS_Bypass_Load` on the operation user) with read-only queries only. If any bypass is ON
   or `PS_Bypass_Load` is assigned to the operation user, **do not change or remove anything**.
   Record the observed state and stop for owner approval, naming the exact switch/assignment.
4. **Reuse valid evidence before rerunning tests.** For each check, first reconcile the
   latest existing artifact in `evidence/`. Mark prior evidence reused/superseded/still-valid
   in the report. Run new tests or queries **only** for unresolved gaps or cases needing fresh
   verification.
5. **Never change production logic to make a test pass.** A failing check is a finding or a
   shippable-to-owner defect; it is never a reason to edit Apex/Flow/VR.
6. **Separate discovered defects from missing evidence.** Two distinct sections in every report.
7. **Never claim UI or persona verification from an admin SOQL query.** UI state requires a
   browser or owner confirmation. `System.runAs` evidence only proves the *Apex* path.
8. **Never sign UAT on the owner's behalf.** Owner signs; agent gathers evidence and labels it.
9. **Preserve automation direction:** no new project-owned Flows (`AUTOMATION_DIRECTION.md`);
   P3-01 appraisal Flow is kept; accepted features are verified, not rebuilt.
10. **Distinguish accepted-with-deferred-checks from fully verified.** Never upgrade a
    deferred item to "passed" because the feature was accepted.
11. **The latest backlog is the scope authority; the inventory here is a starting point.**
    Refresh the implemented/deferred/excluded/not-yet-built inventory at run time against the
    latest backlog and `BUILD_STATUS.md`. Do not freeze today's status as final.

## 2. Status labels (reporting rule — one per check)

- **PASS** — evidence recorded, artifact produced, method executed as described.
- **FAIL** — behaviour contradicts requirement (defect: D-<n>).
- **BLOCKED** — dependency/approval missing; name the blocker.
- **DEFERRED** — owner-approved delay or accepted exception; carries a doc reference.
- **EVIDENCE-GAP** — behaviour likely present but proof missing (never a PASS).

## 2.5 Scope-inventory states (distinct from check labels)

Applied once per backlog item in the inventory (§3.0). One item carries exactly one state:

- **IMPLEMENTED** — exists in ng-dev; may still need checks (then it also gets a §2 label).
- **DEFERRED** — owner-approved delay; carries a doc reference.
- **DELIBERATELY-EXCLUDED** — out of scope or superseded (e.g. cross-transaction round-robin
  accepted exception); carries the decision reference.
- **NOT-YET-BUILT** — planned in backlog, absent at run time. Applies to the **agreed final
  delivery scope** only: anything in scope but absent at project completion is a finding, not
  a pass. Owner-approved deferred or excluded features are **not** NOT-YET-BUILT; they carry
  the state above and stay listed separately with their decision reference.

## 3. Prioritized verification checklist

### 3.0 Scope inventory (refresh at run time, never author-less)

Build one table over **every** backlog ID (P0-01..P8-11): backlog row → implementation
state (§2.5) → check IDs that apply (§3 categories). The gate reads **agreed final delivery
scope** only: in-scope rows must be IMPLEMENTED (or carry a check label). Owner-approved
deferred/excluded rows keep §2.5 states and their decision references; they are never passes.
Phases 4-7 rows below are written today in NOT-YET-BUILT planning form; the agent fills real
state against the live backlog the day the run starts.

### Cat R — status reconciliation (do first; several items are inconclusive)

| # | Requirement & source | Current evidence / gap | Verification method | Expected result / artifact | Permissions / fixtures / approval | Label |
|---|---|---|---|---|---|---|
| R1 | M1 gate evidence vs sign-off: `BUILD_STATUS.md:19` "M1 gate passed … UAT_P2 signed, tag `demo/v0.1` pushed" versus `evidence/P3/equity_test.md` §4 "UAT_P2 signed? **No**" and `evidence/P2/cross_verification_report.md` §5.2 | Direct contradiction between BUILD_STATUS and evidence files | Read-only: git `tag -l`, `git show demo/v0.1`, diff BUILD_STATUS history; **owner clarification** on which statement is current | One reconciled record: which statements are current, which superseded | none | R |
| R2 | P3-01 "ACCEPTED for this demo scope" (`BUILD_STATUS.md:23`) while `equity_test.md` §7 lists pending gates | Accepted-with-deferred vs fully verified | Read-only reconciliation of both docs | Accepted-status statement with explicit deferred-check list | none | R |
| R3 | Probe classes `P2UAT_ProbeTemp`/`P2UAT_RoutingTemp` deployed but untracked (cross_verification F-4) | Source-control gap, decision open | Read-only: `git status --porcelain`, console query | Label current state; decision stays owner-only | none | R |
| R4 | M2 / M3 gate tags (`demo/v0.2`, `demo/v1.0`) and milestone evidence, when they exist | Not yet run (phases 3–7 unwritten) | Read-only `git tag -l`, `git show <tag> --stat`; reconcile with `BUILD_STATUS.md` phase rows live | Tag/metadata/evidence reconciliation matrix | none | R |
| R5 | Phase status table in `BUILD_STATUS.md` vs `evidence/` completeness (all phases) | Re-evaluate at run time | Read-only diff of BUILD_STATUS vs evidence listings | Consistency report; owner detail only for sign-off meaning | none | R |

### Cat B — Phase 3 (priority: B1-B5 are P3-01 gates)

**B0 — Reconcile latest evidence first (before any new run).** Read the newest P3-01
saved-record evidence (record IDs, field-level values) and any P3-02 enforcement/gate report
already in `evidence/P3`. Decide for each whether it is still valid, superseded, or a gap.
Only B1-B5/B6/B7 steps that remain unresolved run fresh. Reused artifacts are referenced by
path in the report, not regenerated.

| # | Requirement & source | Current evidence / gap | Verification method | Expected result / artifact | Permissions / fixtures / approval | Label |
|---|---|---|---|---|---|---|
| B1 | P3-01 Sales Manager persona verification (`BUILD_STATUS.md:39`, `equity_test.md` §3) | Pending; no manager user, record, or outcome named | Run active `Trade_In_Appraisal` as ngpersona (Sales Manager) via `scripts/persona.sh manager`; open saved records; inspect `Appraised_By__c` = manager | Owner/UI run; `evidence/P3/persona_manager.png`; named user + record IDs | persona switch + record access — **approval** | P3 |
| B2 | P3-01 saved-record verification (equity = appraisal−payoff, `Status__c=Appraised` not Accepted, `Appraised_By__c`/`Appraisal_Date__c` populated) (`equity_test.md` §2) | Requested, no record IDs/results until B0; reuse any newer evidence with IDs | B0 reconcile first; read-only SOQL on `Trade_In__c` **only for records/fields still unresolved** | Per-record field table + IDs → `evidence/P3/saved_records.txt` (or a reused-artifact reference) | read-only | P1 |
| B3 | P3-01 per-run record-count correlation: exactly one `Trade_In__c` per flow run (`equity_test.md` §2 bullet 6) | No correlation performed | SOQL count + run timestamps matching UAT runs | Count table per run → `evidence/P3/record_counts.txt` | read-only; relies on B1 runs | P1 |
| B4 | P3-01 vehicle input + required-field validation (review-screen field validation, `BUILD_STATUS.md:42`) | Deferred — not examined | Browser/UI pass on the screen flow (required fields, odometer type, condition picklist) | UI evidence `evidence/P3/input_validation.png` | browser availability + approval | P3 |
| B5 | P3-01 review-screen values + screenshots (`BUILD_STATUS.md:40`) | Deferred | Browser/UI capture of `Screen_Equity_Result`, equity, saved record | `evidence/P3/review_screen.png` | browser + approval | P3 |
| B6 | P3-02 Quote gate: block unless any `Trade_In__c` child is `Accepted`; flag `Has_Trade_In__c` governs | Plan only (guard not deployed); **B0: reconcile any later enforcement report first** | Automated Apex/DML cases for **unresolved cases only** (flag false/no child, true/no child, Appraised, Accepted, multiple children) | `evidence/P3/appraisal_gate_tests.txt` + reused-report reference; all cases labelled | Apex tests need deploy approval once guard exists | P1 |
| B7 | Phase 3 end-to-end: appraisal → acceptance → quote → pricing → approval/output, as built | P3-01 done (pending B1-B5); P3-02/04/05/06/07 not yet built | Check each present *user-facing* step (P3-04 quote builder, P3-05 pricing) only if implemented; absent components are **not** failures | Enumerated matrix of implemented vs not-yet-built with status per step; also feeds H2/H3 | depends on implementation state | P2 |

### Cat C — outstanding Phase 1/2 acceptance checks

| # | Requirement & source | Current evidence / gap | Verification method | Expected result / artifact | Permissions / fixtures / approval | Label |
|---|---|---|---|---|---|---|
| C1 | P2-01 ≈80/20 distribution (`BACKLOG P2-01`, data plan §2.3; ten-row proposal at cross_verification §3.3) | Not run; proposal awaiting approval; cross-transaction rotation is an accepted exception (`TECH_DEBT.md`) | Bulk insert of the 10 leads **in one transaction** (slot labels exact only then); assert 8/10 consistent | `evidence/P2/lead_routing.png` + batch table | insert 10 Lead rows — **approval** + table approval | P2 |
| C2 | UAT_P2 full run + sign-off (`UAT_P2.md`, status in `equity_test.md` §4) | Not signed; screenshots absent | Run steps §1–§10 as ngrep/ngpersona; capture `evidence/P2/uat/*.png`; owner signs | Sign-off row filled by owner | persona runs + screenshots — **approval** | P1 |
| C3 | P2-11 dashboard dynamic-by-role evidence (viewer = LoggedInUser) | Dashboard + reports retrieved; dynamic-by-role evidence missing | Persona read: open `DM_Sales_PipelineSnapshot` as rep and as manager; compare scope | `evidence/P2/uat/persona_view.png`-style dynamic proof | persona switch + folder share — **approval** | P1 |
| C4 | Folder shares: `NG_01_Pipeline`/`NG_02_Leads`/`NG_Sales` currently Hidden → share to `PG_All_Sales` (`OWNER_ACTION_LIST.md` §1) | Owner clicks pending; shares unverified | Read-only FolderMember/FolderShare query after owner clicks | Share matrix verified → `evidence/P2/folder_shares.txt` | owner clicks first; then read-only | P2 |
| C5 | `PG_All_Sales` membership: 1 of 3 (`ngrep` only) | 2 members missing (`p211_...txt`). Membership is Setup-only | Owner adds members; agent re-queries `GroupMember` read-only | 3-of-3 verified | owner click then read-only | P2 |
| C6 | P2-08 email receipt vs invocation (`tasks.txt`) | Invocation proven; delivery suppressed by DE "System email only" | Owner checks inbox acceptance; agent re-asserts invocation via `Messaging` path only | `evidence/P2/uat/confirm_email.png` if delivered, else explicit EVIDENCE-GAP | owner inbox | P2 |
| C7 | P2-03 test-drive **screen flow** skipped (UX via P2-04 guard); P2-02/07 screenshots; P2-04 subflow pending | Recorded as skipped/pending in prior BUILD_STATUS table | Confirm each is an accepted-with-deferred item, never a PASS | Reconciliation table | none | R |
| C8 | P1 owner evidence screenshots (roles, OWD, layouts, apps) TODO (`phase1_exit_report.md`) | Missing screenshots only | Owner capture; agent verifies files exist + named | `evidence/P1/` screenshot set | owner-only | P3 |

**Accepted exceptions carried forward (verify they are recorded, not passed):**
cross-transaction round-robin (`TECH_DEBT.md`), service-visit slot race (same file), P2-09
acceptance = structural validation + P5-03/P5-13 data-scope follow-ups (`p209_p210_data_scope.txt`),
email deliverability = invocation-only within DE limits.

### Cat D — Phase 4: financing, delivery, loyalty enrollment (write live state at run time)

Backlog P4-01..P4-13. M2 depends on this phase. Rows below are planning rows; replace the
§3.0 state when run.

| # | Requirement & source (backlog row) | Verification method | Expected result / artifact | Permissions / fixtures / approval |
|---|---|---|---|---|
| D1 | P4-01 Payment calculator | Automated Apex: amortisation correct to cent (0%, standard, high rate) | `evidence/P4/calc_tests.txt` | Apex test run — **approval** |
| D2 | P4-02 Finance application (LWC screen per direction) | Browser/UI: live payment while typing; term/rate validation | `evidence/P4/finance_wizard.png` | browser + persona + **approval** |
| D3 | P4-03 Financing status lifecycle + P4-04 rate table | Automated Apex cases per status transition + tier→rate | `evidence/P4/status_tests.txt`, `rate_tests.txt` | Apex test run — **approval** |
| D4 | P4-05/06 Finance + delivery approval/checklist gate | Automated Apex negative per gate; VR stays | `evidence/P4/checklist_block.txt` | Apex test run — **approval** |
| D5 | P4-07 Delivery closes opportunity + P4-08 loyalty enrollment | Automated Apex: Closed Won, `Delivery_Date__c`, `Lifetime_Vehicles_Owned__c`, member row | `evidence/P4/closedwon_gate.txt`, `loyalty_enrol.txt` | Apex test run — **approval** |
| D6 | P4-09/10/11 reports, deal-desk dashboard, FLS denial | Read-only metadata/SOQL for report structure; persona negative for FLS; owner view | `rpt_finance.txt`, `dash_dealdesk.png`, `fls_denied.png` | folder shares + persona — **approval** |

### Cat E — Phase 5: synthetic-data reconciliation, data quality, reset

| # | Requirement & source | Verification method | Expected result / artifact | Permissions / fixtures / approval |
|---|---|---|---|---|
| E1 | P5-01/02 determinism + idempotency | Re-run generator/loader twice; byte-compare CSVs, compare counts | `evidence/P5/determinism.txt`, `idempotency.txt` | generator/loader run — **approval** |
| E2 | P5-03/05 volumes + ledger | Read-only counts vs data plan §2.1 table; `Storage Usage ≤ 4.0 MB` | `counts.txt`, `storage.png`, `ledger.png` | read-only + owner UI for storage |
| E3 | P5-04/06/07 integrity + edge + legacy DQ batch | Read-only integrity query = 0; `SEED-99`/`SEED-98` counts vs §9 | `integrity.txt`, `bad_counts.txt`, `seed98.png` | read-only; bypass state logged (rule 3) |
| E4 | P5-08/09 release-gate DQ (14 must be 0) + demo findings | Run `scripts/verify.sh`; re-verify §9a=0, §9b expected counts | `verify_gates.txt`, `demo_findings.png` | script run — **approval** |
| E5 | P5-10..P5-16 reports/dashboards/CRTs | Read-only metadata structure + persona scope (dynamic dashboards) | per-item artifacts | folder shares + persona — **approval** |
| E6 | P5-17/18/19/20 reset + snapshot + burst protocol | Dry-run order; forced-refusal test; full reset+reload run; burst protocol round trip | `reset_run.txt`, `reset_refusal.png`, `burst_*.png` | destructive-ish: reset/burst — **explicit approval** |

### Cat F — Phase 6: service, cases, capacity, escalation, loyalty, consent

| # | Requirement & source | Verification method | Expected result / artifact | Permissions / fixtures / approval |
|---|---|---|---|---|
| F1 | P6-01/02 capacity + intake case | Automated Apex: over-capacity rejected; visit→Case created, owner `Q_Service_Intake` | `capacity_block.txt`, `case_queue.txt` | Apex test run — **approval** |
| F2 | P6-03 escalation rule | Read-only metadata + controlled firing | `escalation.txt` | escalation fire — **approval** |
| F3 | P6-04/05/06/11 history linkage + accrual + repeat signal | Automated Apex accrual maths; read-only related-list data; report structure | `vehicle_history.txt`, `accrual_tests.txt`, `rpt_repeat.png` | Apex + read-only + report view |
| F4 | P6-07/08 tier batch + redemption/expiry | `Test.stopTest()` assertions: tier move; negative balance prevented | `tier_batch.txt`, `redemption_test.txt` | Apex test run — **approval** |
| F5 | P6-09 dashboard (dynamic #3) | Persona scope comparison | `dash_service_*.png` | persona — **approval** |
| F6 | P6-12 consent + nurture gate | Automated Apex: non-consented contact excluded | `consent_gate.txt` | Apex test run — **approval** |
| F7 | P6-14/15/16 entitlements+milestones, Knowledge, console coexistence | Read-only metadata + UI as dual-role persona | `milestones.png`, `knowledge.png`, `console.png` | UI/persona — **approval** |

### Cat G — Phase 7: integrations, async, events, LWC, Agentforce, Data Cloud, Experience

| # | Requirement & source | Verification method | Expected result / artifact | Permissions / fixtures / approval |
|---|---|---|---|---|
| G1 | P7-01/02/23 LWC (inventory, calculator, vehicle header) | Browser/UI functionality + presence/error states; Reserve action round-trip | `inventory_lwc.png`, `widget.png`, `vehicle_header.png` | browser + LWC use — **approval** |
| G2 | P7-03/04 VIN callout + API contract | Automated mock test (callout); read-only contract→impl consistency | `vin_callout.txt`, contract diff | Apex test — **approval** |
| G3 | P7-05/06 platform event + pub-sub doc | `Test.stopTest()` event end-to-end; doc seam statement | `platform_event.txt` | Apex test — **approval** |
| G4 | P7-07/08 trigger architecture + Queueable | 200-row bulk + bypass test; async reconciliation via `Test.stopTest()` | `trigger_tests.txt`, `queueable.txt` | Apex test — **approval** |
| G5 | P7-11/12 permission audit + territories | Read-only report runs + territory tree (if present) | `perm_audit.png`, `territories.png` | owner view |
| G6 | P7-15 Agentforce + Prompt Builder | Native prompt test within DE limits; **labelled fallback** verified present | `agentforce.png` | UI + LLM quota — **approval** |
| G7 | P7-16 Data Cloud | Manual-refresh ingestion + identity-resolution demo in DE space | `datacloud.png` | UI + data space — **approval** |
| G8 | P7-18 Experience Cloud owner portal | External-user login; service history/appointments visible | `portal.png` | external login + 1-2 licences — **approval** |
| G9 | P7-17/20/21 regression, README, demo script pack | One-command `scripts/test.sh` green from clean checkout; scripts run end-to-end | `regression.txt`, doc diffs | script run — **approval** |
| G10 | P7-19/13/14/09/10/06/22 arch + governance + debt + seam notes + images | Read-only: docs exist, honest seams (P7-06 in G3, P4-12/P6-10/P6-13 in P7-14 index), images render via `Photo__c` | per-item paths | read-only |

### Cat H — cross-phase journeys, deployment/rebuild, regression, milestone evidence

| # | Requirement & source | Verification method | Expected result / artifact | Permissions / fixtures / approval |
|---|---|---|---|---|
| H1 | Data model, validation, security, persona access (P1 rows + §6 data model) | Read-only metadata: objects/fields/VRs/OWD/FLS; persona negative tests | `security_matrix.txt` | read-only + persona — **approval** |
| H2 | Complete **implemented sales journey**: lead intake → conversion → test drive → reservation → opportunity → trade-in appraisal → acceptance → quote → pricing → approval → quote output → financing → delivery → loyalty | Run the whole journey once (B/C/D rows feed it); each step labelled; browser or recorded Apex path. **Omitted steps are listed with their §2.5 scope status** (excluded/deferred/not-yet-built) and the journey is labelled per coverage — a partial journey is **never** called a complete end-to-end pass | `evidence/UAT/journey_sales.png` (or step matrix) | journey data inserts — **explicit approval** |
| H3 | Complete **implemented post-sale journey**: service visit → case → entitlement milestone → consent → loyalty accrual/redeem/expiry → repeat signal | Same discipline as H2: coverage + omitted-step status per part, no partial pass | `evidence/UAT/journey_postsale.png` | journey inserts — **explicit approval** |
| H4 | Deployment/rebuild from clean checkout (runbook MASTER_PLAN §3.6 + P7-17) | Clean clone → `scripts/test.sh` → dry-run → DQ gates → storage ≤4.0 MB | `rebuild.txt` | full rebuild — **explicit approval** |
| H5 | Milestone evidence M1/M2/M3 | Tags, gate rows in BUILD_STATUS, UAT sign-offs, screenshots per milestone present | milestone evidence matrix | read-only + owner sign-off |
| H6 | Regression: whole Apex suite + release-gate DQ at project end | Full suite + `verify.sh` at completion | `regression.txt` | Apex run — **approval** |
| H7 | Storage/budget envelope end state | `Storage Usage ≤ 4.0 MB`; reset protocol ran once | `storage.png` | owner UI |

### Cat I — Phase 8: Customer Experience Portal (milestone M4)

Planning rows; write live state at run time. Phase 8 is scoped to **Experience Cloud + custom
LWC** (React/Multi-Framework excluded). **Digital Experiences is not enabled and no external
licence model is chosen** — resolve `docs/architecture/EXPERIENCE_PORTAL.md` §3 before any run.
Security checks (I2/I3) are the priority. Existing Cat R–H records are unchanged.

| # | Requirement & source | Verification method | Expected result / artifact | Permissions / fixtures / approval |
|---|---|---|---|---|
| I1 | P8-01 site scaffold + Digital Experiences enablement | Read-only site metadata + owner Setup evidence; **BLOCKED until owner authorizes enablement (D4)** | `evidence/P8/site_live.png` | owner Setup — **approval** |
| I2 | P8-02 external access model + sharing | Negative `System.runAs` external-user tests per exposed object; sharing-set / `__Share` inspection; Public R/W objects not directly exposed | `evidence/P8/ext_access_denied.png` | external login + sharing config — **approval** |
| I3 | P8-03 portal Apex CRUD/FLS | Automated Apex: FLS denial, cross-customer isolation (read + write), bulk | `evidence/P8/portal_tests.txt` | Apex run — **approval** |
| I4 | P8-04..P8-09 portal LWCs | Browser/UI per component; per-customer data scope; appointment write isolation | `evidence/P8/portal_*.png` | browser + external login — **approval** |
| I5 | P8-10 responsive + accessibility | Browser at mobile/desktop widths; focus/contrast | `evidence/P8/responsive_*.png` | browser — **approval** |
| I6 | P8-11 demo script + UAT + seam note | Script runs; `docs/architecture/EXPERIENCE_PORTAL.md` present and honest | `evidence/P8/uat/` | — |
| I7 | Simulation fallback (only if licensing fails, owner D5) | Labelled **SIMULATION** Lightning app verified; licensing gap documented | `evidence/P8/sim_fallback.png` | owner decision |

## 4. Owner involvement — two distinct kinds

**A. Genuine owner decisions/sign-off (agent can never produce these).** Git/tag *existence*
and provenance are agent-inspectable, but owner *acceptance* is not evidence. Anything
labelled *acceptance*, *sign-off*, or approval of a business decision stays with the owner:

1. Any UAT sign-off row (P2, P3, P4; M1/M2/M3 gates) — never sign on the owner's behalf.
2. Milestone/tag reconciliation statements (R1, R4) — agent supplies git facts; owner
   confirms intent/acceptance.
3. Email receipt *acceptance* for any outbound-alert check (C6 and any financing/loyalty
   alert analogues).
4. Approvals for persistent/insert data and for reset/burst runs (C1, E6, H2, H3, H4).
5. Final project gate verdict (§5) and any re-statement of an acceptance (R2).

**B. Tool/access-limited (may become agent-executable with the right tool or approval).**
Not owner *decisions*; currently outside agent capability:

1. Browser/UI runs (P2-02/03/07, B1/B4/B5, D2, G1, G6, G7, G8, H2, H3) — agent-executable
   with browser tools; otherwise browser-capable agent or owner clicks, agent verifies.
2. Persona switching (`scripts/persona.sh`, C3, C2, F5, G5, H1) — needs explicit approval
   per use; never silent.
3. Setup clicks: groups (C5), folder shares (C4, P4-09/10, P5 reports), external-client/app
   items, Experience site publishing, Data Cloud space actions — owner or tool-authorized;
   **verification queries stay with the agent**.
4. Screenshot capture anywhere permission-gated (C8, P1 evidence) — any user with UI access.

Rule: **A never becomes B.** Decisions cannot be delegated to a tool. B can move from owner
to agent only with the missing tool + approval; resulting evidence is still verified by
read-only queries the verification agent controls.

## 5. Completion gate (whole project)

The gate is **status completeness, not screenshot count**:

- Scope inventory (§3.0): every backlog P0-01..P8-11 has exactly one §2.5 state; within the
  **agreed final delivery scope**, zero residual NOT-YET-BUILT at project completion — any
  in-scope absence is a finding. Owner-approved deferred/excluded items stay listed
  separately with their decision references; they are not passes.
- Every checklist row (Cat R..I) carries exactly one §2 label with a named artifact (or reused
  artifact path) or an owner decision; zero unlabelled items.
- Cat R: R1-R5 resolved or explicitly deferred with reference.
- Cat B/C: existing Phase 1-3 rows each PASS/BLOCKED/DEFERRED; nothing passed on admin-only evidence.
- Cat D-H: rows against *implemented* features only; DELIBERATELY-EXCLUDED/DEFERRED carry doc
  references; defects (D-<n>) separated from evidence gaps; none fixed by unapproved changes.
- Cat I (Phase 8, M4): rows against *implemented* portal features only; external-access isolation
  (cross-customer negative tests) is the gate; a licensing-blocked portal is DEFERRED with the
  SIMULATION fallback documented — never a pass.
- Journeys H2/H3 executed for every *in-scope* step; omitted steps recorded with their §2.5
  scope status and coverage labelled (a partial journey is never a complete pass); H4 rebuild
  + H6 regression green; H7 storage ≤ 4.0 MB.
- Final artifact: `evidence/UAT/UAT_VERIFICATION_REPORT.md` with §2.5 inventory, per-row
  labels, defects vs gaps, owner-decision outstanding list (§4A), and a proposed project gate
  verdict **for the owner to sign** — the agent does not self-certify.

---

## 6. Initial prompt for the verification agent (paste verbatim)

```
You are the dedicated verification/UAT agent for the Northgate Motors demo (ng-dev).
Verify, do not build. This is a one-time pass after the ENTIRE project is complete;
do not modify production.

START: read docs/verification/VERIFICATION_HANDOFF.md fully, then the LATEST
DEMO_ORG_BACKLOG.md (scope authority), BUILD_STATUS.md,
docs/architecture/AUTOMATION_DIRECTION.md, DEMO_ORG_MASTER_PLAN.md,
DEMO_ORG_DATA_MODEL.md, DEMO_ORG_SYNTHETIC_DATA_PLAN.md, docs/TECH_DEBT.md,
docs/VERIFY_RESULTS.md, metadata-log/ORG_INFO.md, and every evidence/P* and evidence/UAT
artifact that exists at run time.

STEP 0 — Inventory refresh (mandatory, before any check): build the §2.5 state table over
every backlog ID P0-01..P8-11 from the live backlog + BUILD_STATUS + evidence. Do not trust
today's handoff rows as final; refresh them from the repo now. In-scope absence at run time
is a finding; owner-approved deferred/excluded items stay listed separately (never passes).

PREFLIGHT (read-only; abort on drift):
1. `sf org display --target-org ng-dev --json`: confirm alias=ng-dev, username=arjun.ngdev@northgate.demo,
   and org ID matches metadata-log/ORG_INFO.md. Abort on any mismatch.
2. Read-only SOQL: Automation_Settings__c Bypass_Validation/Flows/Triggers state and
   PS_Bypass_Load assignment on the operation user. If any bypass is ON or PS_Bypass_Load is
   assigned to the operation user, DO NOT change or remove anything — record the exact state,
   stop, and ask for approval naming the switch/assignment.
3. `git tag -l` and `git show` for demo/v0.1 and any later milestone tag: record states for
   reconciliation R1/R4.

THEN WORK Cat R before Cat B/C before Cat D-H before Cat H journeys (Cat I last, Phase 8/M4), in handoff §3. At each
category, reconcile existing evidence first (rule 4): mark reused/superseded/gap, run fresh
tests only for unresolved gaps. Every check is labelled
PASS/FAIL/BLOCKED/DEFERRED/EVIDENCE-GAP with an artifact path or reused-artifact reference.
Do NOT execute any step whose Permissions column says approval without stopping and asking.

ABSOLUTE BOUNDARIES:
- ng-dev only; never ng-demo. No deploy, commit, push, tag, persona switch,
  record create/update/delete, permission change, bypass grant, cleanup, reset/burst,
  or full rebuild without explicit approval.
- Preflight drift (bypass ON or PS_Bypass_Load on the operation user): stop, record exact
  state, ask — never silently change settings or remove PS_Bypass_Load.
- No Apex/Flow/VR edits to make a test pass. A failure is a defect (D-<n>) or missing
  evidence (EVIDENCE-GAP), listed in separate report sections.
- Admin SOQL never counts as UI or persona verification (rule 7).
- Do not sign any UAT or the gate. Produce evidence/artifacts; the owner signs.

DELIVER one report in chat + write evidence/UAT/UAT_VERIFICATION_REPORT.md with:
(1) preflight results, (2) the refreshed §2.5 inventory, (3) checklist with status label per
row referencing reused artifacts by path, (4) defects D-<n> vs evidence gaps, (5) owner
decisions (§4A) and tool/access-limited (§4B) items outstanding, (6) journey results H2/H3 with per-step coverage and any omitted steps + their scope status
(partial journeys labelled partial, never complete passes),
(7) proposed project gate verdict (completeness of labels and journeys, not screenshots) for
owner sign-off.
```

---

## 7. Relationship to build work

The verification agent is read-only and may run only after the **entire project** completes.
It does not block any current phase development. Unresolved items flow to owner + build agent
only as defects or missing-evidence requests. The inventory in this document is refreshed at
run time (rule 11); today's status is never frozen as final. No planning files were edited
for this handoff.