# Build Status — Northgate Motors demo org

Target org: **ng-dev only** (`arjun.ngdev@northgate.demo`). Never touch ng-demo or other orgs.
CLI: @salesforce/cli 2.153.5 (upgraded 2026-10-08; 2.140.6 could not resolve `.object`/`.set`/`.customSetting` source files). sourceApiVersion 67.0, org API 68.0.

## Done

### Phase 0 (all) — commit `d741df2`
P0-01, P0-02, P0-03, P0-04, P0-05, P0-06, P0-07, P0-08, P0-09, P0-10, P0-11, P0-12.

### Phase 1 step 1 — commit `b307107` (deploys `0Afg800000GLbUqCAL`, `0Afg800000GL9zzCAD`, `0Afg800000GM4beCAD`)
- **P1-01** Core custom objects: 13/13 in ng-dev, counts match DATA_MODEL §2.
- **P1-02** Field set: 189 custom fields, all types/scale/requiredness per DATA_MODEL §3; `Seed_Tag__c` (ExtID+Unique) on all 13 custom + 11 standard objects + Activity (covers Task/Event). Verified via Tooling API `FieldDefinition` counts.
- **P1-03** Relationships: only custom MD is `Loyalty_Transaction__c → Loyalty_Member__c` (Cascade); `Vehicle__c → Vehicle_Model__c` required lookup (Restrict); all lookups carry `relationshipName` (unique per target) + `deleteConstraint Restrict` where required.
- **P1-13 (partial)** `Automation_Settings__c` hierarchy setting (Protected, 3 bypass checkboxes) deployed. Still missing: `Bypass_Automation` custom permission + bypass demo.
- **P1-11 (partial)** `PS_Demo_Admin` deployed (13 objectPerms + 185 fieldPerms) and assigned to arjun.ngdev@northgate.demo. Required/MD-field FLS (16 entries) omitted — Metadata API rejects FLS on required fields; they are implicitly accessible. Other 5 sets pending.
- **P1-04** picklist API values all `Title_Case_With_Underscores` (`Certified_Pre-Owned` → `Certified_Pre_Owned` via 2-pass deploy; verified in org); `Term_Months__c` is Number ✓. Evidence `evidence/P1/picklists.txt`.

### Phase 1 step 2 (P1-05) — commit `4c013dc`
- **P1-05** 13 record types deployed and verified (Lead 2, Account 3, Opp 2, Case 3, Vehicle 2, Service_Visit 1) + `NG_Lead_Process` / `NG_Sales_Process` / `NG_Support_Process` + `OpportunityStage` standard value set cut to exactly the 8 DATA_MODEL §7 stages (verified via describe). New stages added through StandardValueSet (`standardValue` elements); StageName-field and BusinessProcess-only routes rejected by server. Owner screenshots still needed → `evidence/P1/record_types/`.

### Phase 1 step 3 (P1-06 + P1-02 follow-up) — commit `3100366`
- **P1-02 follow-up** DATA_MODEL §8 standard fields deployed (24): Lead Rooftop/Assigned_Batch; Contact Household_Role/Lifetime_Vehicles_Owned; Account Household_Size/Preferred_Rooftop; Opportunity 12 (§7); Case Service_Type/Escalated_On/Vehicle; Quote Rule_Applied_Count/Prepared_By; Product2 Category. Days_In_Stage = `NOW() - Stage_Last_Changed__c`. PS FLS extended +24 (209 total).
- **P1-06** 13 layouts deployed and verified (≥1 per RT). Finance-gated: `Invoice_Cost__c` excluded from Vehicle sales layouts. Owner previews still needed → `evidence/P1/layouts/`.

## Next
**P1-07** -- DONE (commit pending): 13 tabs, 4 apps, 4 profiles; evidence evidence/P1/apps_tabs_profiles.txt; owner landing screenshots pending.

Then in backlog order: P1-08 roles (likely click-only: Role is not deployable metadata), P1-09 OWD, P1-10 queues, P1-11 remaining sets, P1-12 groups, P1-13 custom permission, P1-14 sharing, P1-15 users, P1-16 VRs, P1-17 dup rules, P1-18 CMDTs, P1-19 matrix, P1-20 VinValidator, P1-21 persona script, P1-22 External Client App -> M1 gate.

## Blocked
- None (CLI upgrade removed the source-format blocker).

## Click steps waiting (owner)
- None yet. Expected: P1-15 user creation review, P1-22 External Client App creation/sign-off, Setup screenshots for evidence (roles, OWD, layouts, apps), M1 gate sign-off.
