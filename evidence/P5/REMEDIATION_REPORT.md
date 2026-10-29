# Northgate Motors — Remediation Report

Date: 2026-10-19
Target org: `ng-demo` (`00Daj00001Ae3iWEAR`)
Scope: remaining test failures, UI layout gaps, CP2/Product2 verification, Phase 5 data gates,
persona/queue readiness, and final handoff.

Real deployment completed on 2026-10-19: deploy `0Afaj00000oHtT8CAK`, status `Succeeded`,
13/13 components, `checkOnly=false`. No data change, no commit, and no push was performed.

## 1. Verdict

| Area | Verdict | Basis |
|---|---|---|
| Focused regression suite | **PASS** | 64/64 post-deploy preservation tests; `QuoteBuilderControllerTest` 13/13 |
| Full org Apex suite | **PASS** | 189/189 tests, 100% pass, 85% org-wide coverage, run `707aj00001MTeI1` |
| Category C FLS gap | **FIXED / DEPLOYED / VERIFIED** | Live `PS_Sales_Rep` has `Opportunity.AccountId` read and edit |
| Categories A/B/D test gaps | **FIXED IN SOURCE / VALIDATED** | 56/56 in combined check-only; source test classes not deployed |
| UI custom-object layouts | **FIXED / DEPLOYED / VERIFIED** | 12/12 live layouts match source field sets |
| Product2 / PricebookEntry | **VERIFIED** | 30 vehicle products, 0 suffix, 30 active nonzero PBE, names match 30 models |
| CP2 pricing engine | **VERIFIED READ-ONLY** | Kestrel 50615 → 43022.75; Q-0058 55829 → 49827.38 |
| Phase 5 seeded data gates | **14/14 PASS** | Fresh read-only replication; evidence `verify_gates.txt` |
| Full §2.1 data envelope | **NOT SATISFIED** | SEED-98 legacy batch deferred (30 records); reported, not a regression |
| PAGE-001 record pages | **NO DEFECT / INACTIVE** | Live `Northgate_Sales` app has no Delivery or Loyalty override |
| DATA-001 quote pricing | **OPEN / OWNER DECISION** | 18 open quotes proposed for backfill; 42 terminal frozen |
| DATA-002 won opps without delivery | **NO DEFECT / SAMPLE DATA** | 18 records are standard Salesforce sample opportunities |
| PERSONA-001 demo users | **OPEN / OWNER ACTION** | One switchable sales-side user; no free Salesforce licenses |
| Permission Set Groups | **DEPLOYED / VERIFIED** | 4/4, `0Afaj00000oIT8PCAW`; composition matches source |
| QUEUE-001 queue membership | **DEPLOYED / PERSONA PENDING** | 3/3, `0Afaj00000oI4JjCAK`; role members live, no users in roles yet |
| Production deployment of fixes | **PASS** | `0Afaj00000oHtT8CAK`, 13/13, `checkOnly=false` |

## 2. Issue-by-issue results

### TEST-A — Bypass_Automation test context (5 failures)

Status: **FIXED IN SOURCE / VALIDATED IN CHECK-ONLY**. The focused suite passes 56/56. The
tests now run under the intended non-bypass persona context, so guard and validation-rule
assertions execute.

Affected tests (previously failing):
- `QuoteTradeInGuardTest.guard_true_appraisedOnly_blocked`
- `QuoteTradeInGuardTest.guard_true_noChild_blocked`
- `QuoteTriggerEnforcementTest.tradeInRequired_appraisedOnly_blocked`
- `QuoteTriggerEnforcementTest.tradeInRequired_noChild_blocked`
- `FinancingStatusServiceTest.nonDraftWithoutTerm_isStillBlocked`

The source test-class edits were not part of the 13-component deployment manifest. The live
org test classes pass without them, so this is a source-alignment item, not a demo blocker.

### TEST-B — Demo role/persona gap (7 failures)

Status: **FIXED IN SOURCE / VALIDATED IN CHECK-ONLY**.
`Sales_Rep`, `Sales_Manager_Downtown`, and `VP_Sales` roles exist in `ng-demo`.
`DiscountApprovalTest` passes 7/7 in check-only validation, including the new
`unauthorizedUser_cannotApproveAssignedStep` test. The VP assertion is deterministic
(oldest active VP by `CreatedDate, Id`), not a hard-coded user Id. The post-deploy run
executed the live six-test version and passed 6/6.

### TEST-C — `Opportunity.AccountId` FLS (2 failures)

Status: **FIXED / DEPLOYED / VERIFIED**.
Root cause: `Opportunity.AccountId` is permissionable, but `PS_Sales_Rep` had no
`FieldPermissions` row for it. `WITH USER_MODE` therefore raised
`System.QueryException: No such column 'AccountId' on entity 'Opportunity'`.

Fix: added `<fieldPermissions>` for `Opportunity.AccountId` (`editable=true`,
`readable=true`) to `force-app/main/default/permissionsets/PS_Sales_Rep.permissionset-meta.xml`.

Validation: check-only deploy `0Afaj00000oHJSsCAO` and combined package
`0Afaj00000oHjojCAC` passed. After the real deployment, the live permission set returns
`PermissionsRead=true` and `PermissionsEdit=true` for `Opportunity.AccountId`.
`QuoteBuilderControllerTest` passed 13/13 post-deploy.

### TEST-D — Hard-coded ng-dev IDs (4 failures)

Status: **FIXED IN SOURCE / VALIDATED IN CHECK-ONLY**.
`LeadRoutingHandlerTest` now resolves roles, queues, and users dynamically.
The class passes 6/6 in the combined check-only suite. Source test-class edits were not
deployed.

### UI-L01 to UI-L12 — Minimal custom-object layouts

Status: **FIXED / DEPLOYED / VERIFIED**.

Live org records for `Vehicle__c` and `Service_Visit__c` use the master record type, so
the generic layouts were the pages actually in use. Those layouts exposed only Name and a
few standard fields. The following source layouts were completed and validated:

| Layout | Live fields before | Source fields after |
|---|---:|---:|
| `Vehicle__c-Vehicle Layout` | 5 | 26 |
| `Vehicle__c-New Layout` | 22 | 23 |
| `Vehicle__c-Used Layout` | 22 | 23 |
| `Vehicle_Model__c-Vehicle Model Layout` | 4 | 17 |
| `Trade_In__c-Trade-In Layout` | 5 | 22 |
| `Rooftop__c-Rooftop Layout` | 4 | 14 |
| `Consent__c-Consent Layout` | 5 | 13 |
| `Staff__c-Staff Layout` | 4 | 12 |
| `Service_Visit__c-Service Visit Layout` | 7 | 26 |
| `Test_Drive__c-Test Drive Layout` | 7 | 21 |
| `Loyalty_Transaction__c-Loyalty Transaction Layout` | 5 | 14 |
| `Data_Load_Batch__c-Data Load Batch Layout` | 4 | 14 |

Validation: check-only deploy `0Afaj00000oHOQyCAO`, status `Succeeded`, 13/13 components.
Post-deploy comparison shows all 12 live layouts have exactly the source field sets, with
no missing or extra fields.

`Delivery__c`, `Loyalty_Member__c`, and `Financing__c` layouts already contained all custom
fields and were not changed. `Account`, `Lead`, `Case`, and `Opportunity` layouts already
contain every custom field.

### PAGE-001 — Empty Delivery and Loyalty record pages

Status: **NO DEFECT / INACTIVE PAGES**.

Fresh live retrievals confirm both pages are empty shells: `Delivery_Record_Page` is 426
bytes and `Loyalty_Member_Record_Page` is 438 bytes, each with only the `header` region and
`flexipage:recordHomeTemplateDesktop`.

The live `Northgate_Sales` application has exactly three `actionOverrides`:
`Financing__c`, `Opportunity`, and `Quote`. It has no Delivery or Loyalty override.
Therefore neither empty page is active in the demo app, and no user sees it. No change was
made. If the owner later wants these pages active, author the regions first; deleting the
unused pages is also safe but not required.

### DATA-001 — Seeded Quotes have no computed pricing

Status: **OPEN / OWNER DECISION**. No DML was run.

Measured state:
- 60 Quotes total; 60 have `Adjusted_Subtotal__c = null`.
- Status mix: Accepted 19, Rejected 12, Denied 11, Draft 10, Presented 8.
- Open (Draft/Presented) = 18; terminal (Accepted/Rejected/Denied) = 42.
- 5 Quotes link to an Opportunity with `Vehicle__c` (Q-0056 through Q-0060, all Accepted).
- Only Q-0058 has QuoteLineItem products that match the Opportunity vehicle; it prices
  deterministically at 55829 → 49827.38 with two rules.
- The other four vehicle-linked quotes carry a different product from the Opportunity
  vehicle. CP2 returns `BLOCKER_BASIS_AMBIGUOUS`, so they need a data fix, not a backfill.
- The remaining 55 quotes have no Opportunity vehicle. CP2 returns a deterministic result
  equal to Subtotal with zero rules applied.

Dry run (`scripts/quote_pricing_backfill_dryrun.apex`, read-only):
- `eligible_backfill=18` (all open, deterministic).
- `frozen_historical=38`.
- `blockers=4` (all historical).
- `unchanged_open=0`.

Proposed rule: backfill only the 18 open quotes; freeze all 42 terminal quotes. A guarded
apply script exists at `scripts/quote_pricing_backfill_apply.apex` with `EXECUTE = false`.
It is idempotent and updates only quotes whose `Adjusted_Subtotal__c` is null. It writes
both `Adjusted_Subtotal__c` and `Rule_Applied_Count__c` from the CP2 result.

Owner decision required: approve the 18-quote open backfill, or accept null pricing for
the existing demo records. The four historical vehicle mismatches are separate data fixes
and should not be changed silently.

### DATA-002 — 18 non-seeded Closed Won opportunities without delivery

Status: **NO DEFECT / SAMPLE DATA**.

A fresh child query confirms 30 Closed Won opportunities: 12 seeded household purchases
with a Delivery child and 18 without. The 18 match standard Salesforce sample data, not
Northgate seed data:
`Burlington Textiles Weaving Plant Generator`, `Edge Emergency Generator`,
`Edge Installation`, `Edge SLA`, `Express Logistics Standby Generator`,
`GenePoint SLA`, `GenePoint Standby Generator`, `Grand Hotels Emergency Generators`,
`Grand Hotels Generator Installations`, `Grand Hotels SLA`,
`United Oil Emergency Generators`, `United Oil Installations` (two records),
`United Oil Refinery Generators`, `United Oil SLA`, `United Oil Standby Generators`,
`University of AZ Portable Generators`, and `University of AZ SLA`.

They carry no `SEED_TAG`, no household account, and no vehicle. They do not fail Phase 5
Gate 4, which is scoped to seeded records. Leave them in place; optionally exclude
non-seeded records from demo reports. No cleanup is required.

### PERSONA-001 — Missing demo users

Status: **OPEN / OWNER ACTION**.

Live facts:
- Salesforce licenses: total 4, used 4 (`arjun.ngdemo`, `ngpersona.ngdemo`, the `epic.*`
  system user, and `roger_major@icloud.com`). No free Salesforce license.
- Salesforce Platform licenses: total 6, used 0. Platform users cannot access standard CRM
  objects such as Lead, Opportunity, Quote, or Case.
- The only active non-admin user with a role is `ngpersona.ngdemo@northgate.demo`
  (profile `NG_Sales`, role `VP_Sales`).
- `ngpersona` currently has `NG_Lightning_Experience_Access` and its profile-owned
  permission set only. It does not have `PS_Sales_Rep`.
- `PS_Sales_Rep`, `PS_Sales_Manager`, `PS_Finance_Officer`, and `PS_Service_Advisor`
  exist live. `PSG_Rep`, `PSG_Manager`, `PSG_Finance`, and `PSG_Service` do not.

Minimum viable plan:
- Admin: `arjun.ngdemo` (already `PS_Demo_Admin`).
- Sales rep, sales manager, finance officer, and VP: reuse `ngpersona` and switch its role
  and PSG with `scripts/persona.sh`. Do not create users; no Salesforce license is free.
- Inventory and service personas: blocked by licensing. A Platform user can work with
  custom objects only; Service Advisor needs Case, Contact, and Service Visit. Either free
  a Salesforce license or accept that service/inventory are admin-demoed for now.

`scripts/persona.sh` was corrected to default to `ng-demo`, use the live username
`ngpersona.ngdemo@northgate.demo`, support a `rep` persona, and fail with deployment
guidance when the PSG is missing. It was not executed.

### QUEUE-001 — Empty queues and public group

Status: **QUEUE METADATA DEPLOYED / PERSONA PENDING**.

Deployed on 2026-10-19 with deploy `0Afaj00000oI4JjCAK`, `Succeeded`, 3/3 components.
Live role membership now is:
- `Q_Finance_Approvals` -> `Finance_Manager`.
- `Q_Inbound_Leads` -> `Sales_Rep`.
- `Q_Service_Intake` -> `Service_Advisor`.

The three `GroupMember` rows created by the deployment point to the matching role groups,
not to users. Pre/post queue comparison confirms `doesIncludeBosses`,
`doesSendEmailToMembers`, name, and `queueSobject` are unchanged. `Q_VP_Sales_Approvals`
remains absent and is not referenced.

Operational gap: no active user holds `Finance_Manager`, `Sales_Rep`, or `Service_Advisor`.
The queues resolve but remain empty until personas are assigned. `PG_All_Sales` is still
empty, so dashboard sharing still reaches nobody.

### CP2 / Product2 rollout

Status: **VERIFIED**.
- Product2 family `Vehicles`: 30 records.
- Product names containing `(Trim)`: 0.
- Active standard PricebookEntry for `Vehicles`: 30, zero-price: 0.
- Product names and `Vehicle_Model__c` names match exactly in both directions (0 missing).
- Active `Vehicle_Trim` PricebookEntry count: 30.

### Phase 5 release gates

Status: **14/14 PASS on seeded scope**.
Fresh read-only replication replaced the stale 2026-10-18 evidence. Gate 10 confirms 2085
canonical records (1835 clean + 250 activities). The full 2115-record envelope remains
unsatisfied because the 30-record SEED-98 legacy batch is deferred; this is reported, not a
new failure.

### Post-deploy verification (2026-10-19)

Real deployment `0Afaj00000oHtT8CAK` succeeded with 13/13 components, 0 errors,
`checkOnly=false`, start `2026-10-19T13:22:38Z`, complete `2026-10-19T13:22:42Z`.

Verified after deployment:

- Live `PS_Sales_Rep` has `Opportunity.AccountId` with read and edit enabled.
- All 12 live layouts contain exactly the source field sets; no field was added or removed
  by retrieval or deployment.
- `QuoteBuilderControllerTest` passed 13/13 (100%).
- `QuotePricingServiceTest`, `FinancingStatusServiceTest`, `DiscountApprovalTest`,
  `DeliveryCloseServiceTest`, and `LoyaltyEnrolmentServiceTest` passed 64/64 (100%).
- Full org suite passed 189/189 (100%), 85% org-wide coverage, run `707aj00001MTeI1`.
  The run used live org test classes; source-only test edits were not deployed.
- CP2 read-only probes are unchanged: Kestrel `50615` to `43022.75`; Q-0058 `55829` to
  `49827.38`.
- Record counts are unchanged: 62 Financing, 12 Delivery, 70 Loyalty Member, 60 Quote,
  131 Opportunity. All three approval processes remain active.
- The five Lightning record pages were last modified before the deployment; none was
  included in the manifest or changed by it.
- The live `Northgate_Sales` app still has only the Financing, Opportunity, and Quote
  record-page overrides.

The package source also lists `Vehicle_Model__c.Name` field permission and `QuoteLineItem`
object permissions. Salesforce did not persist either entry. `Vehicle_Model__c.Name` is a
standard Name field with `permissionable=false`, and the org returns zero `QuoteLineItem`
rows from `ObjectPermissions`. These are no-ops in this org; the sales-persona Quote Builder
tests pass, so no functional gap was observed.

### Configuration metadata deployment (2026-10-19)

Org ID verified before deployment: `00Daj00001Ae3iWEAR`. Pre-deployment queue metadata was
retrieved to `rollback/ng-demo-2026-10-19-pre-config/` with SHA-256 hashes.

Deployment 1: Permission Set Groups, deploy `0Afaj00000oIT8PCAW`, `Succeeded`, 4/4
components, 0 failures.

Deployment 2: Queue definitions, deploy `0Afaj00000oI4JjCAK`, `Succeeded`, 3/3 components,
0 failures.

Post-deployment evidence:
- `PSG_Finance` -> `PS_Finance_Officer`.
- `PSG_Manager` -> `PS_Sales_Manager`.
- `PSG_Rep` -> `PS_Sales_Rep`.
- `PSG_Service` -> `PS_Service_Advisor`.
- All four PSGs have status `Updated`.
- `Q_Finance_Approvals` -> `Finance_Manager`.
- `Q_Inbound_Leads` -> `Sales_Rep`.
- `Q_Service_Intake` -> `Service_Advisor`.
- Three role-based `GroupMember` rows exist for the queues; they reference role groups,
  not users.
- Pre/post queue properties are unchanged: `doesIncludeBosses`, `doesSendEmailToMembers`,
  name, and `queueSobject`.
- The three approval processes remain active; `Financing_Exception_Approval` still routes
  to `Q_Finance_Approvals`.
- PSG assignments: 0. `ngpersona` role: still `VP_Sales`. `PG_All_Sales` members: 0.
- Quotes: 60 total, 60 null `Adjusted_Subtotal__c`, unchanged.

No persona change, user role/permission change, manual GroupMember creation, Quote DML,
commit, or push was performed.

## 3. Prior deployments verified live

| Deploy ID | Status | Components |
|---|---|---|
| `0Afaj00000oEbMHCA0` | Succeeded, `checkOnly=false` | 7/7 |
| `0Afaj00000oEV3yCAG` | Succeeded, `checkOnly=false` | 2/2 |

## 4. Deployed package

Manifest: `manifest/remediation-deploy.xml`.

Contents:
- `PS_Sales_Rep` permission set (`Opportunity.AccountId` FLS).
- Twelve completed custom-object layouts listed in §2.

Deployment result: `0Afaj00000oHtT8CAK`, `Succeeded`, 13/13 components, 0 errors,
`checkOnly=false`.

Command used:

```bash
sf project deploy start --target-org ng-demo --manifest manifest/remediation-deploy.xml --wait 30
```

Validation manifest with tests: `manifest/remediation-validate.xml`.
Validation result: 19/19 components, 56/56 tests, deploy `0Afaj00000oHjojCAC`.

## 5. Evidence files

- `evidence/P5/deployment_real_2026-10-19.txt` — real deploy output, `0Afaj00000oHtT8CAK`.
- `evidence/P5/deployment_real_report.json` — structured deploy result, 13/13.
- `evidence/P5/deploy_source_hashes.txt` — pre-deploy source hash check, all OK.
- `evidence/P5/pre_deploy_rollback_hashes.txt` — rollback snapshot hashes.
- `evidence/P5/post_deploy_permissions.txt` — live `Opportunity.AccountId` FLS.
- `evidence/P5/post_deploy_permissions_detail.txt` — live permission-set query details.
- `evidence/P5/post_deploy_fls_and_layouts.txt` — clean FLS, describe, and layout evidence.
- `evidence/P5/post_deploy_retrieve.txt` — post-deploy metadata retrieval.
- `evidence/P5/post_deploy_quote_builder_test.txt` — `QuoteBuilderControllerTest` 13/13.
- `evidence/P5/post_deploy_preservation_tests.txt` — five-class regression 64/64.
- `evidence/P5/post_deploy_cp2_probe.txt` — post-deploy CP2 probes.
- `evidence/P5/post_deploy_preservation_checks.txt` — counts, approvals, page timestamps.
- `evidence/P5/remediation_package_validation.txt` — combined check-only deploy, 56/56.
- `evidence/P5/category_c_regression.txt` — focused regression run.
- `evidence/P5/layout_validation.txt` — 10-layout check-only deploy.
- `evidence/P5/verify_gates.txt` — fresh 14-gate replication.
- `evidence/P5/cp2_product_verification.txt` — Product2/PBE counts.
- `evidence/P5/cp2_pricing_probe.txt` — read-only pricing probes.
- `evidence/P5/quote_pricing_data_audit.txt` — quote pricing data state.
- `evidence/FINAL/full_suite.txt` and `evidence/FINAL/full_suite/` — 189/189 full Apex run.
- `evidence/FINAL/quote_backfill_dryrun.txt` — read-only CP2 evaluation of all 60 quotes.
- `evidence/FINAL/quote_backfill_apply_dry.txt` — guarded apply script, `EXECUTE=false`.
- `evidence/FINAL/won_opps_delivery.json` — 30 won opportunities and Delivery children.
- `evidence/FINAL/retrieve_live_app.txt` — live `Northgate_Sales` app retrieval.
- `evidence/FINAL/retrieve_live_pages.txt` — live Delivery/Loyalty page retrieval.
- `evidence/FINAL/retrieve_live_queues.txt` — live queue retrieval, no role members.
- `evidence/FINAL/psg_checkonly.txt` — PSG check-only, 4/4, `0Afaj00000oILCTCA4`.
- `evidence/FINAL/queue_manifest_checkonly_v2.txt` — queue check-only, 3/3,
  `0Afaj00000oIPxdCAG`.
- `evidence/FINAL/deploy_psg_2026-10-19.txt` — PSG deploy output, 4/4.
- `evidence/FINAL/deploy_queues_2026-10-19.txt` — queue deploy output, 3/3.
- `evidence/FINAL/deploy_psg_report.json` — PSG deploy report, `Succeeded`.
- `evidence/FINAL/deploy_queue_report.json` — queue deploy report, `Succeeded`.
- `evidence/FINAL/post_deploy_psg.json` — live PSG status and IDs.
- `evidence/FINAL/post_deploy_psg_components.json` — PSG-to-permission-set composition.
- `evidence/FINAL/post_deploy_queue_groupmembers.json` — role-based queue members.
- `evidence/FINAL/post_deploy_queue_member_groups.json` — role group resolution.
- `evidence/FINAL/post_deploy_approval_processes.json` — three active approvals.
- `evidence/FINAL/config_deployment_2026-10-19.txt` — consolidated deployment evidence.
- `verification/ng-demo-2026-10-19-post-config/` — retrieved PSGs, queues, approvals.
- `rollback/ng-demo-2026-10-19-pre-remediation/` — pre-deploy rollback snapshot.
- `verification/ng-demo-2026-10-19-post-remediation/` — post-deploy retrieved metadata.

## 6. Skipped / not claimed

- No quote-pricing backfill was executed; all 60 quotes still have null
  `Adjusted_Subtotal__c`.
- No persona user was created, no role or permission-set assignment was changed, and
  `scripts/persona.sh` was not run.
- Configuration metadata was deployed (4 PSGs, 3 queues). No persona was assigned, no
  public-group member was added, and no Quote data was changed. The deployment created
  three role-based `GroupMember` rows for the queues; these reference role groups, not users.
- No flexipage was changed for `Delivery_Record_Page` or `Loyalty_Member_Record_Page`.
- No historical Closed Won record was changed.
- Source-only test-class changes were not part of the 13-component manifest; the full-suite
  run used the live test classes already in `ng-demo`.
- `scripts/verify.sh` was not run because `node_modules` is absent; gates were replicated
  read-only in Python with the same queries and canonical CSV manifest.
- No Git commit or push. The working tree remains dirty with prior remediation changes and
  untracked deployment CSVs.

## 7. Ordered owner actions

1. **Permission set groups — DONE.** Deploy `0Afaj00000oIT8PCAW`, `Succeeded`, 4/4.
   Live composition verified.

2. **Queue definitions — DONE.** Deploy `0Afaj00000oI4JjCAK`, `Succeeded`, 3/3.
   Role membership verified; no users are in those roles yet.

3. **Switch the sales-side persona.** Run one of these, then verify with the matching
   record list or approval step:

   ```bash
   scripts/persona.sh rep
   scripts/persona.sh manager
   scripts/persona.sh finance
   scripts/persona.sh vp
   ```

4. **Share the dashboards with the demo persona.** `PG_All_Sales` is empty, so dashboard
   folder sharing currently reaches nobody. Add `ngpersona` (and any later demo user) to
   the public group in Setup, or create the `GroupMember` row explicitly.

5. **Decide on the quote-pricing backfill.** Review
   `evidence/FINAL/quote_backfill_dryrun.txt`. If approved, change `EXECUTE` to `true` in
   `scripts/quote_pricing_backfill_apply.apex` and run it. It updates 18 open quotes and
   leaves 42 terminal quotes untouched. Re-run the script to confirm it is a no-op.

   ```bash
   sf apex run --target-org ng-demo \
     --file scripts/quote_pricing_backfill_apply.apex
   ```

6. **Decide on the four historical vehicle mismatches** (Q-0056, Q-0057, Q-0059, Q-0060).
   These are Accepted quotes whose line-item products do not match the Opportunity vehicle.
   Correcting them changes historical records, so this needs explicit owner approval and a
   separate data-fix plan. No change was made.

7. **Optional cleanup.** Delete the two inactive empty FlexiPages, or leave them; they are
   not active in `Northgate_Sales`. Exclude non-seeded sample opportunities from demo
   reports if the 18 standard records are distracting; do not delete them.

## 8. UAT and handoff

Recommended demo UAT after persona assignment and dashboard sharing:

1. Log in as `ngpersona` with the `rep` persona. Open a seeded opportunity, use the Quote
   Builder, save a quote, and confirm the adjusted subtotal and rule count are populated.
2. Switch to `manager`. Submit a quote above the 5% threshold and confirm it routes to the
   manager approval step.
3. Switch to `finance`. Open a sub-prime Financing record, submit
   `Financing_Exception_Approval`, and confirm the work item lands on
   `Q_Finance_Approvals` (not an empty queue).
4. Switch to `vp`. Confirm the discount approval path and VP visibility.
5. As admin, open a seeded Delivery record and close it with the checklist complete.
6. Confirm a Loyalty Member record shows tier, points, and transaction history.

Handoff notes:
- The org is `ng-demo` only. Do not run any command against `ng-dev`.
- The working tree is dirty from prior remediation work; no commit or push was made.
- `expect` the full Apex suite to take roughly 8 minutes (`Test Setup` dominates).
- The 18-quote open backfill is the main unresolved data decision. The four historical
  vehicle mismatches are a separate decision. Everything else is verified, an owner
  metadata action, or documented sample data.
