# Phase 2 Cross-Verification Report (corrected)

**Date:** 2026-10-08
**Target org:** ng-dev (`arjun.ngdev@northgate.demo`) only
**Purpose:** cross-verify the initial build instructions against the current implementation
and the Phase 0–2 evidence, before any Phase 3 work.

---

## 0. Corrections to the previous report

The previous report named the probe classes incorrectly. The identifiers below were
verified programmatically (git `status --porcelain` for local paths, Tooling API
`ApexClass` query for deployed names) so they are exact, not re-typed.

### 0.1 Probe classes — exact identifiers

| Role | Exact path / name |
|---|---|
| Local source (untracked) | `force-app/main/default/classes/P2UAT_ProbeTemp.cls` + `P2UAT_ProbeTemp.cls-meta.xml` |
| Local source (untracked) | `force-app/main/default/classes/P2UAT_RoutingTemp.cls` + `P2UAT_RoutingTemp.cls-meta.xml` |
| Deployed in ng-dev | `P2UAT_ProbeTemp` (ApexClass) |
| Deployed in ng-dev | `P2UAT_RoutingTemp` (ApexClass) |
| Archived, NOT deployed | `force-app/main/default/classes/P2UAT_Diagnostic.cls` + meta, held in `evidence/P2/blocked-metadata/debug/` |

**Change from previous report:** the classes are `P2UAT_ProbeTemp` and `P2UAT_RoutingTemp`.
The archived diagnostic is `P2UAT_Diagnostic`. Both `P2UAT_*` test classes are deployed to
the org but **not committed to git** — this is a real source-control gap and is
recorded as a finding below, not resolved.

### 0.2 Owner checklist location

The owner-click checklist is at `evidence/P2/OWNER_ACTION_LIST.md`.
Confirmed by walking the repository tree for `.md` files whose filename contains `ACTION`.

---

## 1. Verified against build instructions

| Check | Result | How verified |
|---|---|---|
| Full Apex suite | **31 pass / 0 fail** | `sf apex run test` against ng-dev |
| Full-project deploy dry-run | **Clean**, deploy `0Afg800000GGgQhdCAL`, 0 component failures | `sf project deploy start --dry-run` |
| P2-01 FSA prefix routing | **Verified by real save** | `PostalCode = M5V2T6` → Rooftop `Northgate Downtown`, owner Sales Rep, `Assigned_Batch__c = M-R1` |
| `Lead_Enrich_Rooftop` Flow | Active in org (v4) | Tooling API query on `Flow` |
| `ViewRoles` permission | Granted on `PS_Sales_Rep` | `SELECT PermissionsViewRoles FROM PermissionSet` → true; required by `LeadRoutingHandler.resolveLane`'s cross-object query |
| Phase 1 evidence present | 18 files in `evidence/P1/`, plus `phase1_exit_report.md` | Directory listing |
| `AGENTS.md` escalation policy | Present at repo root | File created earlier this session |

## 2. Findings not yet satisfied

| # | Finding | Evidence |
|---|---|---|
| F-1 | **The ≈80/20 distribution test has not been run.** | Only 2 Leads carry a batch label, both `M-R1`. See §3 for the corrected definition and proposed inputs. |
| F-2 | **Cross-transaction round-robin is deferred.** | Confirmed by lead data: sequential saves both yield `M-R1`. Documented in `docs/TECH_DEBT.md`. See §4 for the acceptance-exception question. |
| F-3 | **P2-09/10/11 reports and dashboard are not built.** | Folders `NG_01_Pipeline` and `NG_02_Leads` exist but contain **0** reports; org has **0** custom dashboards. Owner instructions in `evidence/P2/OWNER_ACTION_LIST.md` §1, summarised in `owner_checklist_p209_p210_p211.md`. |
| F-4 | **Source-control gap:** `P2UAT_ProbeTemp` and `P2UAT_RoutingTemp` exist in the org but are untracked in git. | `git status --porcelain` vs `ApexClass` query. **No action taken** — pending owner decision to commit or retire them. |
| F-5 | `evidence/P2/blocked-metadata/debug/` contains archived diagnostic output and is untracked. | Directory listing. Preserved per owner instruction; no cleanup proposed. |

---

## 3. The "10 test leads distribute ≈80/20" criterion

### 3.1 What is measured — resolved

It measures **postal-code consistency versus inconsistency with a specified Rooftop** — i.e.
whether a lead's postal code falls under the Ontario FSA prefix set belonging to the rooftop
that the routing table (`Lead_Routing__mdt`) maps that prefix to.

It is **not** "matched versus unmatched" against an independent expectation, and it is
**not** a rep/queue ownership split. The fields the metric evaluates are:

| Field | Role in the metric |
|---|---|
| `Lead.PostalCode` | the lead's postal code; the prefix is derived from it in the Flow |
| `Lead_Routing__mdt.FSA_Prefix__c` / `Rooftop__c` | the routing-table row selected for that prefix |
| `Lead.Rooftop__c` | the rooftop the Flow assigns — must be the rooftop named by the matched row |
| `Lead.Assigned_Batch__c` | `UNROUTED` marks the inconsistent 20% |

### 3.2 Requirement context (verbatim)

Backlog P2-01 acceptance column:
> "10 test leads distribute ≈80/20 → `evidence/P2/lead_routing.png`"

`DEMO_ORG_SYNTHETIC_DATA_PLAN.md` (§2.3):
> "Lead routing demo: ~80% of leads match their rooftop's Ontario FSA prefix
> (downtown `M*`, North `L4H*`, Airport `L5V*`, Service Centre `L1G*`)."

`DEMO_ORG_DATA_MODEL.md` (§8 table) — **this is the exception-report requirement**:
> "Lead routing | Ontario FSA prefixes only (all four rooftops are in Ontario):
> `M*` downtown, `L4H*` North, `L5V*` Airport, `L1G*` Service Centre; ~80% match
> rate, 20% deliberate mismatch for the exception report"

So the 20% deliberately-inconsistent rows are the population that exception report exists to
surface; there is no additional field beyond `Rooftop__c` / `Assigned_Batch__c`.

### 3.3 Proposed ten-row input / expected-result table (NOT run — awaiting approval)

Eight rows chosen to be consistent with the assigned rooftop's prefix set; two deliberately
inconsistent.

| # | PostalCode | Derived prefix | Expected Rooftop__c | Expected Assigned_Batch__c | Classification |
|---|---|---|---|---|---|
| 1 | `M5V2T6` | M | Northgate Downtown | `M-R1` | consistent |
| 2 | `M4C1B5` | M | Northgate Downtown | `M-R2` | consistent |
| 3 | `L4H1A1` | L4H | Northgate North | `L4H-R1` | consistent |
| 4 | `L4H2R5` | L4H | Northgate North | `L4H-R2` | consistent |
| 5 | `L5V1M5` | L5V | Northgate Airport | `L5V-R1` | consistent |
| 6 | `L5V2N5` | L5V | Northgate Airport | `L5V-R2` | consistent |
| 7 | `L1G1A1` | L1G | Northgate Service Centre | `L1G-R1` | consistent |
| 8 | `L1G2H1` | L1G | Northgate Service Centre | `L1G-R2` | consistent |
| 9 | `K2A9J1` | none | null | `UNROUTED` | inconsistent |
| 10 | `P1B1A1` | none | null | `UNROUTED` | inconsistent |

Expected result: **8/10 consistent (80%)** and **2/10 inconsistent (20%)**.

Slot labels are exact only when all 10 leads are inserted in one transaction (each rooftop's
lane rotates R1 → R2). Inserted one at a time, both rows for a rooftop land on R1 because
durable rotation is deferred — this does not change the 80/20 metric, which counts rooftop
consistency, not the slot number.

The 10 leads will not be inserted until the owner approves this table.

## 4. Cross-transaction round-robin — accepted deferral

**Status: accepted by the owner as an explicit Phase 2 acceptance exception, not as a
passed requirement.**

- Current behaviour: the lane index rotates **only within a single transaction**. Separate
  Lead saves can repeat the initial slot (two separate saves both produced `M-R1` on
  Northgate Downtown).
- This is **not** production-ready fair distribution and is not claimed as such.
- Kept as technical debt in `docs/TECH_DEBT.md`.
- Durable rotation (a counter object updated under `SELECT ... FOR UPDATE`, or a
  hierarchy custom-setting counter) is **deferred**, not implemented.

## 5. Outstanding items requiring owner action before Phase 2 exit

1. **P2-09 / P2-10 / P2-11 reports and dashboard are not built.** Folders
   `NG_01_Pipeline` and `NG_02_Leads` exist but contain **0** reports; org has **0**
   custom dashboards. Owner clicks are in `evidence/P2/owner_click_p209_p210_p211.md`.
2. Approve the §3.3 ten-row table so the ≈80/20 test can be run.
3. Decide whether the probe classes are committed to git or retired (see F-4).

### 5.1 Temporary source-reconciliation item (probes preserved)

`P2UAT_ProbeTemp` and `P2UAT_RoutingTemp` are **preserved locally and in ng-dev for now**,
at the owner's instruction.

Current status, recorded as a **temporary source-reconciliation item**:
- deployed in ng-dev: yes
- tracked in git: no (untracked)
- no commit and no retirement has been performed, and none may occur without approval.

### 5.2 Phase 2 exit criteria still outstanding

| # | Exit criterion | State |
|---|---|---|
| 1 | P2-09 / P2-10 / P2-11 reports + dashboard built, retrieved, validated; dashboard uses "The dashboard viewer" | **Outstanding** — owner clicks not yet done |
| 2 | P2-01 ≈80/20 distribution evidence | **Outstanding** — inputs proposed in §3.3, not run |
| 3 | Probe source reconciliation | **Outstanding** — owner decision |
| 4 | Cross-transaction round-robin exception recorded | Recorded in §4 as an accepted exception |

## 6. Declaration

- No Phase 3 work started.
- No ng-demo changes made.
- No leads inserted; the §3.3 table is a proposal awaiting owner approval.
- `P2UAT_ProbeTemp` and `P2UAT_RoutingTemp` are preserved locally and in ng-dev; their
  untracked-but-deployed state is recorded as a temporary source-reconciliation item.
- Cross-transaction round-robin is recorded as an **accepted Phase 2 acceptance exception**,
  not as a passed requirement, and remains in technical debt. Durable rotation is deferred.
- Production-ready fair distribution is not claimed.

## 7. Closeout-batch addendum (supersedes stale findings above)
- §5/F-3 ('0 reports, 0 dashboards, not built') is SUPERSEDED: ng-dev now holds 3 reports
  (Pipeline_by_Stage `00Og8000008aVYXEA2`, Lead_Source_Effectiveness `00Og8000008aZsHEAU`,
  Open_Opps_by_Sales_Staff `00Og8000008abZ7EAI`) and dashboard DM_Sales_PipelineSnapshot
  (`01Zg80000045WTBEA2`, 3 components, LoggedInUser) — all retrieved to source in the
  closeout batch. §5.2 exit item 1 is partially done; dynamic-by-role evidence still missing.
- F-4 probe decision, §3.3 table approval, and §4 exception language are unchanged.
