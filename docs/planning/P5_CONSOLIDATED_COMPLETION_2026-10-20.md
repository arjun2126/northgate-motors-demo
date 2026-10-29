# Northgate Motors — Phase 5 consolidated completion plan

**Decision: NO-GO for full Phase 5 acceptance or additional loads.** Evidence collection and
bounded local preparation can proceed. No deployment, Salesforce DML, permission/persona
change, bypass, reset, deletion, commit, or push is authorized by this plan. Only `ng-demo`
(`00Daj00001Ae3iWEAR`) was accessed. Preserve CP2, Quote Builder, approvals, financing,
delivery, loyalty, all existing records, and completed-phase acceptance.

This is the current handoff. Earlier continuation sections are historical, not instructions
to repeat completed releases. The working tree is substantially dirty; never stage whole
folders or overwrite unfamiliar changes. Current work changes documentation and one local
candidate CSV only; no application or Salesforce metadata source was changed.

## 1. Evidence and acceptance rules

- **COMPLETE:** the full original criterion and its runtime/evidence requirements are met.
- **PARTIAL:** implementation or evidence exists, but at least one criterion remains unproved.
- **BLOCKED:** a hard prerequisite prevents completion; the prerequisite is explicitly named.
- No original backlog item is presently established COMPLETE in full: **15 PARTIAL, 5 BLOCKED**.
  This does not reopen accepted subfeatures or imply that deployed functionality is missing.
- The governing allocation remains 2,085 canonical records + 30 SEED-98 = 2,115. Historical
  2,123 used the superseded Product2/Delivery allocation. Actual fixture additions must be
  inventoried separately; a canonical-only count is not proof of the exact whole-org envelope.

Evidence references used below:

| Ref | Evidence |
|---|---|
| E1 | `evidence/P5/consolidated_completion_checks_2026-10-20.md`: fresh raw deployment-status, report GET, SOQL and access excerpts; failures are explicitly recorded |
| E2 | `evidence/P5/continuation_2026-10-20.md`: earlier 11-check offline output, scoped release results and deployment IDs |
| E3 | `evidence/P5/execution_ledger_2026-10-20.json`: 37 real jobs, 27 objects, 2,085 distinct canonical insert IDs; 2,630 attempts = 2,085 inserts + 403 updates + 142 failures |
| E4 | `evidence/P5/release_uat_2026-10-20.md`: 15-component reporting release, actual report/runtime results and restored persona baseline |
| E5 | `data/scripts/load.ts`, `resolve.ts`, `automation-control/load-wrapper.sh`: loader, result accounting, relationship resolution and restoration implementation |
| E6 | `data/scripts/phase5.py`, `scripts/reset.sh`, `data/scripts/tests/test_phase5_preparation.py`: preparation/check-only planners and offline refusal checks |
| E7 | `evidence/P5/seed98_parents_2026-10-20.json`, `data/prepared/seed98-mapped-20261020/`: exact six-parent proposal and 24/6 legacy CSVs |
| E8 | `evidence/UAT/live_2026-10-19/REP_UAT_COMPLETED_2026-10-20.md` and manager/VP/finance completion records: owner-attested prior lifecycle UI checks, not P5 dashboard acceptance |
| E9 | `DEMO_ORG_BACKLOG.md` P5 table and `DEMO_ORG_SYNTHETIC_DATA_PLAN.md` §§2,7,9: original acceptance contract |
| E10 | `data/SEED_VERSION.txt`, resolved CSVs, and source report/dashboard/report-type XML: implementation artifacts, not independent runtime proof |

## 2. P5-01 through P5-20 acceptance matrix

| Item | Original acceptance retained | Status | Evidence and exact remaining work |
|---|---|---|---|
| P5-01 | Deterministic generator, stored ANCHOR_DATE, byte-identical same-anchor CSVs | PARTIAL | E2 archives the passing two-run/all-30-file comparison; E10 stores anchor. **`data/csv/` is now absent**. Recover the original versioned artifacts and verify recorded hashes; do not regenerate or substitute resolved CSVs silently. |
| P5-02 | Dependency-ordered external-ID loader, bypass cleanup, second load with identical counts | PARTIAL | E5 has successful loader/result work and OLI deduplication. It uses an ID-resolution pass, unlike the original no-resolution contract; no full second-load evidence exists. Document the actual compatibility decision, preserve surgical BAD-02/date changes on any future reload, and validate idempotency only in an approved isolated exercise. |
| P5-03 | Exact governing per-object volumes and Storage Usage <=4.0 MB | BLOCKED | E3 proves historical 2,085-ID insert coverage, not a current whole-org volume/storage pass. SEED-98 is absent; owner reports 4.1 MB. Extra UAT/BAD-03 and proposed BAD-01 records conflict with literal whole-org exact counts. Missing canonical source also blocks a reliable reload. See §5. |
| P5-04 | Zero lookup/master-detail orphans | PARTIAL | E6 implements some non-null anti-joins. Missing complete lookup inventory, required-parent checks, OLI/QLI/PBE relationships and Task/Event polymorphic links; no full live zero-orphan artifact. Reconcile by canonical IDs plus separately named fixture/UAT pools, without hiding any invalid record. |
| P5-05 | One truthful ledger row per batch, version/counts/timestamps/anchor/storage matching SEED_VERSION | BLOCKED | E3 recovers counts and job modification timestamps. E1 still finds 20 Mixed/Loaded rows with inserted=0. Historical per-batch storage and true completion timestamps are unavailable; 37 attempts do not map one-to-one to 20 placeholders. See §6. |
| P5-06 | All BAD-01..10 at scaled counts and separably resettable | PARTIAL | E1: 8 negative-equity trades; six stage-aged Opportunities; operational Cases=3, simulated=11; stale Leads=0/35; stacked-rule canonical Quotes=0/4; No_Show=12 but no-follow-up subset unproved. BAD-01 missing and inventory/SLA counts differ. Separate resetability is unproved for embedded canonical scenarios. See §7. |
| P5-07 | Exactly 30 SEED-98 rows, 10/8/6/6 defects, logged bypass grant/revoke, documentation | BLOCKED | E1 has zero Contacts and zero Trade-Ins in this range. E7 prepares 24 Contacts + 6 Trade-Ins. Storage, duplicate behavior, exact-parent recheck and an approved bypass window must precede insertion. |
| P5-08 | All 14 original release gates automated and passing | PARTIAL | Existing canonical-only PASS is narrower than original acceptance. E6 requires legacy/ledger but has remaining scope issues. Reconcile real field/schema behavior and all 14 checks; retain a non-green result while storage/ledger/volume requirements fail. Do not rerun a broad gate expecting acceptance now. |
| P5-09 | Eight expected-count DQ reports and real delete-one-row drift evidence | PARTIAL | E1 executes deployed reports; stage report=0 despite six correct records. Legacy and household report logic/evidence incomplete; current findings helper uses CreatedDate/CaseComment instead of the accepted operational LastModifiedDate rule. Align the verifier, not the operational report. Offline drift tests do not prove the required live drift exercise. |
| P5-10 | Inventory >60/120 days, grouped by rooftop and make, distribution matches | PARTIAL | E4/E10 provide >60 and make grouping. E1 gives 120 >120, not 12, and >60 report=120. No separate proved >120 view. Date corrections require CP2 price-impact review; never change live ages or reprice existing quotes merely to get a count. |
| P5-11 | Scheduled past visits / SLA report gives exactly 12 | PARTIAL | E1 actual report=13. `SEED-18-040` (`a08aj00001Snsk0AAB`) has start 2026-10-19T00:00Z and crosses the clock boundary. Keep the operational TODAY predicate. See §7. |
| P5-12 | Loyalty 39/18/9/4 with balances and relevant Staff grouping | PARTIAL | E1 canonical `SEED-21-%` query confirms 39/18/9/4; all balances sum to 0. The live all-date report includes 72 (40/18/9/5 including two historical rows). Capture an unsaved canonical-scope view, actual balance totals, relevant Staff lookup access/grouping and owner screenshot. Do not remove historical members. |
| P5-13 | Duplicate audit proves 8 household pairs and 6 email defect rows | PARTIAL | Current Duplicate_Audit is a general Contact listing; household report omits street/distinct-account proof. E7 email rows form three case-insensitive pairs (six rows), not six pairs or necessarily syntactically malformed emails. Needs BAD-01/SEED-98, field-level defect verification and duplicate-rule/DuplicateRecordSet evidence. |
| P5-14 | Dynamic executive dashboard: pipeline, aging, SLA, loyalty, CSI; two personas differ | PARTIAL | E1 confirms live `LoggedInUser` and all five reports. No genuine two-persona screenshots; persona lacks several required object reads. CSI is empty, not a validated numerical average. All-record vs canonical metrics must be labeled. |
| P5-15 | Sales/Service/Finance manager dashboards render as fixed users | PARTIAL | E1 confirms all three live `SpecifiedUser` dashboards run as admin. Actual persona browser rendering/refresh and report ties remain. Dedicated group is empty; RunReports alone does not establish source-report access. See §3. |
| P5-16 | At least three joined report types usable in builder | PARTIAL | VehicleTestDriveList, ContactLoyaltyList and ServiceCaseList source exist; E4 reports implementation. Need builder screenshots and parent/child rows, including outer joins. ContactWithCampaignMembers is additional, not a substitute for the three specified joins. |
| P5-17 | Child-first seed reset, purge, reload, <=4.0 MB; original acceptance run on ng-dev | BLOCKED | E6 is a planner, not an executor. Source CSVs absent; dependency/approval checks incomplete. Original ng-dev evidence requirement conflicts with current ng-demo-only restriction. No access to ng-dev, and no substitute reset on ng-demo. |
| P5-18 | Reset refuses without a fresh snapshot | PARTIAL | E2/E6 refusal tests pass (wrong org/stale/future/incomplete/etc.). Need integration with a real executor and complete external-reference discovery. Current snapshot selects SEED-% but reset accepts only canonical CSV tags; future special fixtures would cause refusal. Resolve that mismatch before use. |
| P5-19 | 300-row burst, volume evidence, exact teardown/purge and return to 3.93 MB | BLOCKED | Split/resolved 200 Lead + 60 Visit + 40 Task preparation exists. No executor/storage proof; historical base is already ~4.1 MB and original 3.93 return is not met. Current plans alone do not authorize destructive execution. |
| P5-20 | Data plan marked loaded with actual version/date after P5-08/P5-09 pass | PARTIAL | E10 correctly records incomplete acceptance, but data plan header still says planning-only. Update current partial-load narrative now; mark Phase 5 complete only after every gate and evidence item closes. |

## 3. Management UAT: controlled access and exact restoration

### Baseline captured; refresh it immediately before an authorized window

Persona: `005aj00000gE0b3AAC`, profile NG_Sales, role VP_Sales
(`00Eaj00000QCxlLEAT`), ManagerId=null. Existing assignments:

| Assignment ID | Preserve |
|---|---|
| `0Paaj000016Ty3HCAS` | Profile-based permission set `0PSaj00000gE0RPGA0` |
| `0Paaj000016dBqzCAE` | NG_Lightning_Experience_Access `0PSaj00000gKc49GAC` |
| `011aj000006D0ErAAK` | PG_All_Sales group membership `00Gaj00000ZYYhUEAX` |

There is currently no membership in `PG_Northgate_Management` (`00Gaj00000ZkluDEAR`)
and no direct assignment of `PS_Management_Reports` (`0PSaj00000gUOW9GAO`). No UAT
assignment was created in this investigation.

1. Before any future create, query both exact tuples again and save the entire permission,
   group, role/profile/ManagerId baseline. If an assignment exists, reuse it and record it
   as pre-existing; never delete it during cleanup. Check pending approvals before any role change.
2. The smallest initial fixed-dashboard smoke window uses only the two named temporary grants:
   dedicated-group membership and RunReports supplement. **Do not change role or assign
   PSG_Manager automatically.** VP-role baseline is not proof of a Sales Manager persona test.
3. These two grants do **not** complete dynamic/dashboard drill-down access. A read-only
   `UserRecordAccess` probe shows the persona **owns all 100 canonical Opportunities** and
   reads them (`read=True edit=True`), and holds 104 `AccountShare` rows
   (`RowCause=ImplicitParent`), so its Opportunity-based reports return real scoped values
   (78 rows / 4,328,120 versus admin 113 / 10,587,766). It has **no** object Read on
   Vehicle__c, Service_Visit__c, Loyalty_Member__c, Staff__c, Case, Quote or Financing__c, and
   no ownership of those records, so inventory, loyalty, SLA and CSI tiles are empty for it.
   The three fixed dashboards are `SpecifiedUser` dashboards running as admin, so their tiles
   show admin-computed values without extending any record visibility to the persona.
   Resolution, options and comparison:
   `docs/planning/P5_BATCH2_ACCESS_RESOLUTION_2026-10-20.md`.
4. For full P5-14/report UAT, prepare a separately reviewed read-only report-viewer grant:
   only objects, referenced lookup targets and report fields actually needed; no Create/Edit/
   Delete, View All, Modify All, bypass, approval administration or finance write access.
   Inspect live FLS, folders and record scope before specifying the exact metadata. If private
   records are legitimately out of scope, retain that restriction. Do not reown/share canonical
   records to make both personas see everything. Use real persona sessions; admin GETs do not count.
5. Owner opens each dashboard and its source reports, refreshes in the browser within the
   authorized window, and records identity, running user, filters, aggregates and screenshots.
   Save P5 fixed-user evidence separately from dynamic two-persona scope evidence.
6. **Finally, on success, partial setup, failure, interruption or cancellation:** stop new
   writes; retain UAT evidence; delete only assignment IDs returned by this run's successful
   creates and recorded in its journal. Preserve pre-existing IDs. If a create response is
   lost, do not guess ownership from tuple alone: compare the pre-state and resolve attribution
   with the owner. If cleanup fails, stop/escalate with IDs and leave a recovery command.
7. Compare the full post-state with the captured baseline. Restore any separately authorized
   role/PSG/ManagerId change only after approval-work-item guards pass. No new approval or
   lifecycle-record creation belongs in this dashboard-only window.

### Expected results at the current clock (not frozen future assertions)

| Dashboard / report | Current comparison and remaining acceptance |
|---|---|
| Fixed Sales | Pipeline source = 113 rows / 10,587,766 Amount, excluding Closed Lost (not an open-only metric). Staff source has Amount 6,250,407; get its RowCount for the dashboard's count component. Confirm Staff Read and actual persona drill-down. |
| Fixed Service | SLA source = 13; CSI has zero scored rows. UI must match those facts; this is not 12-row SLA or nonempty CSI accuracy acceptance. |
| Fixed Finance | Prior UI showed zero candidates and empty decided/funded denominators. Fresh finance aggregate query failed (E1); owner must open the three sources and capture current filters/counts. Null rate/average means N/A, not proof of 0%. No lifecycle state is changed to manufacture metrics. |
| Executive | Live type is LoggedInUser. Compare genuine Sales Rep and manager/VP scopes, independently as authorized. Expected canonical loyalty 70 differs from current all-record report 72. Inventory and SLA discrepancies remain real acceptance gaps. |
| BAD-03 | Operational report=3; separate simulated report=11 (8 new fixtures + 3 existing aged Cases). Preserve both facts. |

### Admin field-access assignment

`PS_Case_Data_Quality_Fields` (`0PSaj00000gV45ZGAS`) is currently assigned to admin
`005aj00000feqbNAAQ` as `0Paaj000016wctoCAA`. It was added during the previous release's
INVALID_FIELD workaround, outside the originally named six-component manifest. Its scope
includes Case Create/Edit/Read, not merely read FLS. Record this scope expansion explicitly;
it is not a management-UAT assignment and must not be copied to Northgate Persona.
The prior release continued after Bulk authentication/INVALID_FIELD errors instead of stopping
for owner review. That workaround is not a precedent for future transport or permission changes.

Keep it unchanged now. After the owner captures final simulated-report evidence and reviews
who needs these fields, obtain explicit approval to remove **this exact assignment ID** or
retain it as a documented admin prerequisite. Removing it can hide fields/report access;
test that consequence before calling cleanup complete. Do not delete the permission set,
revoke unrelated admin grants, or assign it to personas as an expedient workaround.

## 4. Remaining fixture package — prepared, not load-authorized

### BAD-01: eight pairs require sixteen Contact rows

Candidate file: `data/prepared/bad01-households-20261020.csv`. It contains sixteen new
Contacts, eight pairs, with identical surname/street/postal and identical email within each
pair. Each Contact is on a different existing Account. No existing Contact address or
Account is edited. This is smaller than creating sixteen new Accounts as well.

| Pair | Parent Account tags | Exact Account IDs |
|---|---|---|
| 01 | SEED-06-007 / 008 | `001aj000045ZScXAAW` / `001aj000045ZScYAAW` |
| 02 | SEED-06-009 / 010 | `001aj000045ZScZAAW` / `001aj000045ZScaAAG` |
| 03 | SEED-06-011 / 012 | `001aj000045ZScbAAG` / `001aj000045ZSccAAG` |
| 04 | SEED-06-013 / 014 | `001aj000045ZScdAAG` / `001aj000045ZSceAAG` |
| 05 | SEED-06-015 / 016 | `001aj000045ZScfAAG` / `001aj000045ZScgAAG` |
| 06 | SEED-06-017 / 018 | `001aj000045ZSchAAG` / `001aj000045ZSciAAG` |
| 07 | SEED-06-019 / 020 | `001aj000045ZScjAAG` / `001aj000045ZSckAAG` |
| 08 | SEED-06-021 / 022 | `001aj000045ZSclAAG` / `001aj000045ZScmAAG` |

Parent tags/IDs were rechecked read-only. Tags are `SEED-99-DUP-01-A/B` through
`SEED-99-DUP-08-A/B`; all emails use reserved `.test` domains. Candidate incremental
storage is about 32 KB, excluding native duplicate audit rows and other automation.

Loading is blocked by storage and the exact-count boundary: these are additional Contacts,
whereas the original plan budgeted BAD-01 inside 185 canonical Contacts. The eight added
BAD-03 Cases are also outside the original canonical artifact. Do not silently call
2,085+30+16+8 (=2,139) the original 2,115 envelope. Owner must resolve how supplemental
fixtures are accounted for while preserving originals; literal whole-org exact counts
cannot be met simply by filtering these extras out of verification.

### SEED-98: retain the existing 24 Contact / 6 Trade-In preparation

Use E7 only, not the unmapped legacy CSV or the mixed-object `98-legacy.csv`. Contact
defect counts: phone=10, postal=8, email=6 (three case-insensitive pairs). Existing preparation
has no AccountId on Contacts; those orphan-free standalone Contacts do not require new parents.
If account-linked Contacts become a separate requirement, stop and approve an exact mapping.

| Trade tag | Opportunity / Contact tags | Exact Opportunity / Contact IDs |
|---|---|---|
| SEED-98-VIN-001 | SEED-09-001 / SEED-07-001 | `006aj00000fUIsjAAG` / `003aj00002W3EfhAAF` |
| SEED-98-VIN-002 | SEED-09-002 / SEED-07-004 | `006aj00000fUIskAAG` / `003aj00002W3EfkAAF` |
| SEED-98-VIN-003 | SEED-09-003 / SEED-07-006 | `006aj00000fUIslAAG` / `003aj00002W3EfmAAF` |
| SEED-98-VIN-004 | SEED-09-004 / SEED-07-009 | `006aj00000fUIsmAAG` / `003aj00002W3EfpAAF` |
| SEED-98-VIN-005 | SEED-09-005 / SEED-07-010 | `006aj00000fUIsnAAG` / `003aj00002W3EfqAAF` |
| SEED-98-VIN-006 | SEED-09-006 / SEED-07-011 | `006aj00000fUIsoAAG` / `003aj00002W3EfrAAF` |

These are a proposal, not owner-approved relationships. Recheck existence, same Account,
Prospecting status, no new Quote/Trade-In/Financing/Delivery and no pending approval directly
before loading. Requested Trade-Ins can block future quote creation; do not attach them to
completed deals. Preserve CP2/Quote Builder behavior. Estimated storage: 60 KB plus side effects.

### Shared load controls, in this order

1. Obtain exact data, relationship, count-accounting and storage approval. Freeze canonical
   artifacts/IDs and affected-parent state; verify zero existing candidate tags/email collisions.
2. Owner confirms both Contact duplicate rules in Setup (E1 records the failed fresh query).
   Prior Release 1 evidence reports standard rule preserved and custom Email+LastName Allow/
   Alert/Report. These rules do not themselves prove household street matching; that requires
   the independent pair check. Do not deactivate either rule.
3. Capture actual loader identity, effective bypass permission, all grants and all hierarchy
   setting rows. E1 currently has all three org flags false. Admin's existing PS_Demo_Admin
   may already provide Bypass_Automation; capture it instead of revoking it blindly afterward.
4. Install/verify restoration and an interruption recovery journal before enabling any bypass.
   Grant PS_Bypass_Load only if necessary and explicitly approved, saving its new ID. Use the
   minimum proven flags. The existing wrapper toggles only org Bypass_Triggers and does not
   itself grant/revoke every permission; do not describe it as a complete special-load executor.
5. Confirm duplicate API behavior on the first approved pair, serially, against the inserted
   first member. Use native Allow/Report behavior if proven. A custom bypass permission does
   not bypass duplicate rules; do not silently suppress DuplicateRuleHeader behavior or assume
   a record inserted with a suppression header generated a duplicate audit hit.
6. Load one object/type at a time, stop on any unexpected error, journal every submitted row
   and response ID/job. The installed bulk insert command is `sf data import bulk`, not
   `sf data create bulk`. `sf data update bulk` has no `--external-id`; upsert does.
   All future commands must explicitly use `--target-org ng-demo`. Previous Bulk auth errors
   are unresolved; do not retry or switch to REST writes without owner approval.
7. In guaranteed cleanup, restore captured flags exactly, remove only newly created bypass
   assignments, and verify actual effective permissions. An existing admin bypass grant
   remains part of its baseline; prove actual non-bypass persona behavior separately.
8. Verify actual defect values and 10/8/6/6 tags, eight household pairs across distinct
   Accounts, native duplicate-rule evidence, no collateral records, exact parent relationships,
   unchanged business invariants and post-load storage. No acceptance based on tags alone.

## 5. Storage gate: a hard stop, not a proposed waiver

The original <=4.0 MB rule remains unchanged. `/limits` gives Max=5/Remaining=1, which
cannot resolve an exact 4.0 threshold. The owner's latest exact reported reading is ~4.1 MB,
before the need for remaining fixtures/ledger records. Request Setup → Storage Usage, with
org identity, timestamp and per-object breakdown, then reconcile against actual ownership
and source/fixture pools. Also resolve the missing canonical source without altering live data.

BAD-01 + SEED-98 add at least 92 KB (~0.09 MB); native duplicate/automation/ledger records
can add more. Starting at ~4.1 MB projects ~4.19 MB or higher, not <=4.0 MB. Burst adds
approximately 560 KB under the data plan's per-object convention (conservatively 600 KB);
there is no demonstrated post-burst return to the original 3.93 MB.

**There is currently no evidenced, permitted reduction sufficient to meet the gate.**
Previous UAT cleanup estimates were approximate and their record inventory was inconsistent;
do not treat them as an exact deletion manifest or a demonstrated solution. No canonical,
historical, UAT-evidence or unrelated records are deletion candidates under this plan.
Emptying an org-wide Recycle Bin, buying more capacity, changing the denominator, moving data
to another org, raising the threshold or narrowing the counted population does not establish
the original <=4.0 MB acceptance.

Defensible disposition: keep P5-03/load/burst gates BLOCKED until exact evidence proves
enough compliant capacity. If exact usage confirms the conflict persists and no permitted
remedy exists, the owner must explicitly resolve the requirements conflict. An exception
would be a separately documented change, not completion against the original criteria.
Report-only/UAT preparation may continue independently; no further fixture/ledger load is released.

## 6. P5-05 ledger: recoverable evidence versus unavailable history

| Requirement | Recoverable now | Still missing / required decision |
|---|---|---|
| Batch identity/object/version/anchor | E3: 37 native jobs, exact IDs/objects, version SEED-2026.10.01, anchor 2026-10-01 | The version/anchor is associated from source/load context, not a native storage measurement. |
| Submitted/inserted/updated/failed counts | E3: per-job results and hashes; 2,085 distinct inserted canonical IDs; 403 successful updates and 142 failed attempts retained | Separate logical object steps, retries and actual execution batches. Never relabel successful upserts as inserts. |
| Start and finish timestamps | Native createdDate and systemModstamp survive in E3 | systemModstamp is final job modification, not a proven completion time. Wrapper filename and record CreatedDate cannot fill this gap. |
| Historical storage after every batch | None in E3 (`null` for every job) | Seek original dated Storage Usage captures/logs. Current /limits or estimated row sizes cannot reconstruct historical measurements. |
| One Salesforce row per actual batch | Current 20 Mixed placeholders, inserted=0 | 37 jobs cannot honestly fit 20 one-to-one placeholders. Do not overwrite, merge, delete placeholders or add SEED-EXEC rows without a separately approved accounting model and storage budget. |
| Latest scoped REST work | Six successful Opportunity updates and eight Case creates documented in E2/E1 | No Bulk job exists for these operations. Preserve per-record responses and label the transport correctly. A permission-set deployment/assignment is not a data-ingest batch. |

Smallest next step is a local per-job reconciliation specification referencing E3, with null
history explicitly retained, plus an exact future telemetry contract. Existing fields are
Batch_Number, Object, Inserted_Count, Failed_Count, Loaded_At, version, status and 1,000-character
Notes; there are no dedicated update/anchor/storage fields. Decide field/Notes mappings and
size limits before any schema or DML proposal. A forward loader can record job IDs/counts,
observed completion time, source hashes, anchor and timestamped storage **when genuinely observed**.
It cannot retroactively satisfy missing historical measurements. Keep strict P5-05 BLOCKED
if the source evidence is unavailable; do not reload canonical records to manufacture history.

## 7. Report, dashboard and data-quality closure gaps

Original scenario names are authoritative: BAD-02 = 35 stale Leads; BAD-04 = 12 overdue
visits; BAD-07 = revoked-consent campaign Contacts; BAD-08 = six stalled Opportunities.
Earlier conversation called the last two fixes BAD-04/BAD-02 respectively. Preserve their
completed work but use original IDs in the acceptance matrix to avoid dropping stale Leads.

1. **Stalled Opportunity report — CLOSED 2026-10-20 (Batch 1).** The report had no
   `timeFrameFilter` and inherited the report type's default THIS_FISCAL_QUARTER Close Date
   range, returning zero while six records were correct. Batch 1 added an explicit
   `timeFrameFilter` (`CLOSE_DATE` + `INTERVAL_CUSTOM`, no bounds), matching the sibling
   Opportunity reports. Check-only `0Afaj00000oUyI5CAK`; deployment `0Afaj00000oUOg2CAG`;
   deployed report now returns 6 rows with ids equal to the direct SOQL set. No Opportunity,
   CloseDate or `Stage_Last_Changed__c` value changed. Remaining: none for this report;
   the report's own acceptance still needs a browser screenshot and a label note that it
   reports all Close Dates rather than a fiscal quarter.
2. **Service SLA 12 vs 13:** the report truthfully returns 13. `SEED-18-040` became past-due
   at the October 19 boundary; this is not a need to loosen/tighten status filters again.
   Owner may separately approve a business-valid future reschedule of this exact row, after
   inspecting related work and the next clock boundary. If not approved, retain 13 and the
   open 12-row acceptance gap. Never exclude its tag or freeze TODAY to conceal it.
3. **BAD-03 operational aging:** eight new Cases have LastModifiedDate 2026-10-20T23:42Z.
   Keep the operational LAST_UPDATE filter and the separately labeled 11-row simulation.
   Recheck after the actual report boundary in early November; any later update restarts aging.
   Waiting is necessary but does not guarantee a global count of eight: three historical Cases
   already qualify and other Cases will age. Record eight-fixture acceptance separately from
   the real operational total; do not suppress historical Cases to force the original count.
4. **35 stale Leads:** E1 gives zero under real activity/creation aging, not 35. The source's
   intended age distribution cannot backdate system fields. Waiting alone will not prove
   exactly 35. Prepare a supported, separately reviewed activity/fixture plan or keep this
   time-dependent original criterion open; no audit-field or reporting-definition workaround.
5. **Inventory:** all 120 are >120 days. No report-only change can make that true count 12.
   An exact acquisition-date correction would affect age-based CP2 eligibility and needs an
   isolated price-impact comparison and explicit data authorization. Existing quote/approval
   totals must stay unchanged; no repricing/reload is bundled into a reporting release.
6. **Duplicate/email audit:** update candidate/report logic to prove surname+street+postal,
   distinct Accounts and actual duplicate-rule hits; email acceptance is six fixture rows
   across three case-insensitive pairs. Source report labels alone do not implement detection.
7. **Consent:** the accepted fixture report returns six; previous global count was 28 campaign
   memberships. Verify distinct Contacts, revoked Consent and Campaign links independently.
   Preserve all historical memberships; a fixture selector is not a global privacy monitor.
8. **Other BAD scenarios:** eight negative-equity records are confirmed; canonical stacked
   Quotes give zero versus expected four. Twelve No_Show rows are not proof that exactly six
   lack follow-up Tasks. Correlate IDs/WhoId/WhatId/subjects before proposing any data change.
   Do not resave existing Quotes through Quote Builder or remove historical Tasks.
9. **CSI/finance/loyalty:** empty CSI and finance denominators are legitimate empty states,
   not nonempty numeric accuracy evidence. Canonical loyalty is 70, live all-record report 72;
   show both scopes honestly and validate balances (currently zero). No invented CSI scores
   or financing transitions are included in this plan.
10. **Full verification:** reconcile original gate scopes, missing-tag handling, canonical vs
    supplemental counts and verifier/report predicate drift. The current findings helper
    still uses CreatedDate/no-comments for Cases and a global consent count; it does not yet
    encode the owner's accepted scoped demonstrations. Keep original criteria visible.
    `docs/REPORTS.md`, referenced by the original plan, is absent; add a small actual report
    inventory as part of evidence closure, not a new reporting framework.

## 8. Burst/reset readiness — non-destructive planning only

Reuse E6 and prepared split burst files. Do not run a reset, purge, burst load or full
canonical re-upsert under this task. Do not run existing snapshot/count helpers until their
missing `data/csv/` prerequisite is restored and verified.

Required readiness sequence:

1. Recover original canonical source hashes and capture **current** post-release values;
   old CSV reloads could undo BAD-02 stamps and other authorized corrections. Maintain
   explicit canonical, legacy, BAD-01, BAD-03, burst and UAT ID manifests, not a broad LIKE delete.
2. Build a read-only, complete dependency graph from live lookup/MD relationships, including
   Task/Event polymorphic links, Quote/PBE/OLI, CampaignMember, loyalty MD, Feed/Files and
   approvals. Include references **from protected non-SEED records to planned reset IDs**.
   A missing `externalReferences` property is not a clean dependency scan.
3. Export fresh same-org snapshots of every affected row/link, permissions/bypass baseline,
   metadata/source hashes, storage reading and approval state. Validate completeness and a
   <=1-hour age. Hash and journal the exact scope; refuse stale/future/truncated/mismatched data.
4. Topologically sort real dependencies; reversing the loader list is not sufficient. In
   particular Service Visits reference Cases: Visit-before-Case load-order reversal must not
   cause Case deletion before its dependent Visits. Exclude Staff and all protected rows.
5. Reconcile the snapshot/reset mismatch: snapshot currently includes all SEED tags, while
   reset rejects anything outside canonical CSV tags; BAD-03 tags are outside SEED entirely.
   Refuse mixed scopes until the manifest contract is explicit. Preserve existing refusal tests.
6. An executor does not yet exist. Specify stop-on-partial failure, exact-ID responses, captured
   restoration before toggles, no automatic retry, no org-wide purge and a manual recovery
   journal. Do not implement or invoke destructive execution without a separately reviewed scope.
7. Burst isolation: 200 Leads / 60 Visits / 40 Tasks, dedicated SEED-77-BURST tags, refreshed
   future dates and live parent IDs; account for automation-generated Tasks/Cases/counters.
   Bypass may reduce side effects only with explicit approval and an exact restoration contract.
8. Validate baseline/burst/report counts and peak budget before any load; volume screenshots
   are temporary data, not permanent envelope increases. Teardown includes only captured burst
   IDs and separately approved proven burst-generated dependents, child-first; purge only those
   IDs. Compare protected rows/counters before/after and demonstrate the original storage return.
9. Full reset acceptance specifically names ng-dev. Keep that criterion BLOCKED under the
   ng-demo-only rule. Request an owner decision; do not access another org or destroy the stable
   demo as an unauthorized substitute. Neither refusal tests nor a dry-run is execution acceptance.

## 9. Owner walkthrough evidence and Phase 2 follow-through

- E8 preserves owner-attested Sales Rep access to Loyalty/Deliveries, reports, DealDesk and
  CP2 quote 00000069. Screenshots were not attached; do not present attestation as archived images.
- Empty Leads was traced to private ownership/record scope, not a cosmetic list-view bug.
  Preserve OWD/owners and complete the genuine rep routing/conversion test instead of exposing
  every canonical Lead. Dashboard zeros need source denominators, not CSS/LWC redesign.
- Manager Approvals-app/layout failures are historical diagnosis; later manager approval and
  rep evidence take precedence. Do not reopen accepted approval/pricing work or grant Approval
  Admin simply to use the new Approvals app. Keep existing Quote/approval evidence records.
- Broad LWC styling, list-view redesign and UI modernization belong in a separate release.
  Missing report access, wrong date filters and false numerical interpretations remain P5 issues.
- **Phase 2 browser UAT is still mandatory and unsigned.** Use
  `docs/planning/P2_BROWSER_UAT_PROCEDURE_2026-10-20.md` in a separate owner-started window:
  ten fresh Leads, true rep routing/qualification, one conversion into new records, Flow booking
  success/conflict/boundary, stage/tasks/counters/reservation and email evidence. Do not reuse
  the old ng-dev template literally, run p2_setup as bypassed admin, or convert into canonical
  Accounts/Contacts. Budget new UAT records and preserve them unless cleanup is separately approved.

## 10. Smallest release batches and dependencies

Categories: **R** read-only/local preparation; **M** exact-file metadata deployment;
**U** browser/temporary access; **D** data writes; **B** bypass; **X** destructive operations;
**C** owner resolution of an acceptance conflict. Only R is authorized now.

| Order / batch | Exact scope and dependencies | Risks / validation / authorization |
|---|---|---|
| 0 — current preparation | This matrix/raw evidence, BAD-01 candidate CSV, reuse SEED-98/burst plans; recover missing-source provenance and obtain Storage Usage | R now. No regeneration or broad tests. Owner restores original CSV artifacts from a trusted backup and supplies storage/rule/finance evidence. |
| 1 — report-only correction | **DONE 2026-10-20.** Explicit all-date CloseDate filter on Stalled_Quoting_Opportunities only; independent of storage | Completed: check-only `0Afaj00000oUyI5CAK`, deployment `0Afaj00000oUOg2CAG`, report 6 rows = SOQL 6 rows. No Opportunity/CloseDate change, no other metadata touched. Browser screenshot and label note still outstanding. |
| 2 — controlled dashboard window | Fixed Sales/Service/Finance smoke with the two named temporary grants, capture current ties and exact restoration; then a separately specified read-only viewer supplement if needed for dynamic two-persona scope | **Instructions prepared, not executed:** `docs/planning/P5_BATCH2_MANAGEMENT_UAT_2026-10-20.md`. Future U; M only for reviewed missing reads/FLS. Expect empty components: the persona has no record-level access on any checked object. No role switch, PSG assignment, admin FLS-set copying, record creation or broad sharing implicitly authorized. Capture user context and failed/empty results truthfully. |
| 3 — storage/count/ledger decisions | Exact storage breakdown; canonical/source recovery; supplemental fixture count contract; 37-job vs 20-row ledger and unavailable historic measurements | R now, C required to unblock. No loads while >4.0 MB. A documented exception is not original acceptance. No broad cleanup proposal. |
| 4 — BAD-01 + SEED-98 fixture window | At most 16 BAD-01 Contacts, then 24 legacy Contacts and 6 Trade-Ins; exact parent maps, duplicate behavior and captured bypass restoration | Future D+B after batch 3, with storage capacity for >=92 KB plus side effects. Serial duplicate pairs, journal outcomes, stop on errors; read-only postcheck of all 8 pairs/30 defects and restored access. |
| 5 — remaining finding corrections | Owner-selected exact Service SLA date correction; separately reviewed inventory CP2 impact and stale/stacked/no-follow-up fixture gaps; only demonstrated report changes | R diagnosis can proceed; D/M requires exact manifest and storage/CP2 prerequisites. No canonical regeneration or quote repricing. BAD-03 remains time-dependent. |
| 6 — truthful ledger and strict acceptance | Local per-job contract first; future actual ledger writes only after exact model/storage approval. Complete integrity, original 14 gates, eight findings, report builder and dashboard evidence | R now; D/M/C if required later. Missing historic measurements stay unknown; storage/ledger failures keep P5 non-green. |
| 7 — reset/burst acceptance | Finish isolated snapshot/dependency/refusal/executor specification; original ng-dev-run conflict and 3.93 MB return must be resolved | R planning now; B+D+X and org-boundary C separately required for any execution. Full reset is not bundled with fixture loads. |
| 8 — closure / Phase 2 follow-through | Version/load/status docs and P5 sign-off only after all original rows close. Coordinate separate genuine P2 browser window and exact persona restoration | R closure preparation now; U/D for P2 separately. No Git commit/push or UI modernization in these batches. |

## 11. One coordinated owner approval request

Please approve **the next bounded execution window: batch 2 only**—fixed-dashboard browser
UAT with only the two named temporary assignments and guaranteed exact-ID restoration, per
`docs/planning/P5_BATCH2_MANAGEMENT_UAT_2026-10-20.md`. Batch 1 is complete (check-only
`0Afaj00000oUyI5CAK`, deployment `0Afaj00000oUOg2CAG`, report 6 rows = SOQL 6 rows).

This is not authorization for the read-only viewer supplement, role/PSG changes, admin
field-access assignment removal, persona-readable data grants, data loads, bypass or reset;
any missing access stops that portion and is reported, not worked around. Expect empty
dashboard components for the persona: `UserRecordAccess` shows no record-level access on any
checked object, so this window can prove access and rendering, not report values.

For the same handoff, supply (a) a current Storage Usage screenshot/breakdown, (b) trusted
original canonical CSV artifacts, (c) Setup confirmation of the two Contact rules, and
(d) current finance source-report counts/date filters. Then resolve the storage/count/ledger
conflicts before authorizing batches 4 onward. The admin assignment retention/removal decision
and separate Phase 2 browser window remain explicit follow-ups. No response is interpreted as
a waiver of <=4.0 MB, unavailable ledger history, exact expected counts or reset-org acceptance.

## 12. Validation of this planning change

Live validation was limited to read-only deployment reports, ten report GETs, four dashboard
GETs and targeted SOQL. No Apex suite, check-only, deployment or gate script was rerun. The
duplicate-rule and finance aggregate checks stopped on the exact errors in E1; manual owner
steps are provided there. Canonical helper runs were skipped because their source CSV directory
is absent. Local CSV shape/pair/parent/tag checks and documentation diff checks are recorded in
the continuation after execution. No commit, push or Salesforce mutation occurred.
