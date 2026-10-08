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

### Phase 1 step 4 (P1-08) — commit pending
- **P1-08** Role hierarchy deployed from source: `force-app/main/default/roles/*.role-meta.xml` (11 roles, DATA_MODEL §6.1). Verified: SOQL on UserRole matches source for all 11; org has exactly 11 roles. Sample roles deleted (CFO, SVP Sales & Marketing, VP North American Sales, Director Channel Sales, Channel Sales Team, earlier sample children); zero users affected. Sample `CEO` kept as root. Owner Setup screenshot pending → `evidence/P1/roles.png`. Evidence `evidence/P1/roles.txt`.

### Phase 1 step 5 (P1-09) — commit pending
- **P1-09** OWD set from source per §6.3: Account/Contact/Lead/Opportunity/Case Private, Quote ControlledByParent, Vehicle/Rooftop/Vehicle_Model ReadWrite, Financing/Service_Visit Private. Standard objects use `<sharingModel>` in `objects/<Std>/<Std>.object-meta.xml` (Settings/SharingSettings rejected). Recalc async (~2 min). Deviation: Loyalty_Transaction ControlledByParent (MD child). Evidence `evidence/P1/owd.txt`.

### Phase 1 step 6 (P1-10) — commit pending
- **P1-10** Queues from source: Inbound Leads (Lead), Service Intake (Case), Finance Approvals (Financing__c). Verified by SOQL. Evidence `evidence/P1/queues.txt`.

### Phase 1 step 7 (P1-11) — commit pending
- **P1-11** 4 of 6 permission sets from source (DATA_MODEL 6.2): PS_Sales_Rep, PS_Sales_Manager, PS_Finance_Officer, PS_Service_Advisor (+ existing PS_Demo_Admin). FLS check passes: rep has no grant on Financing__c.Annual_Rate__c or Vehicle__c.Invoice_Cost__c. Required/MD fields not granted (server limit). Evidence `evidence/P1/fls_matrix.txt`.
- **Deferred:** PS_Bypass_Load → needs P1-13 custom permission `Bypass_Automation` first.
- **Pending user assignments (P1-15):** PS_Sales_Rep→ngrep, PS_Service_Advisor→ngsvc.

## Next
**P1-12** — permission set groups `PSG_Rep`, `PSG_Manager`, `PSG_Finance`, `PSG_Service` from source (`permissionsetgroups/*.permissionsetgroup-meta.xml`). PSG_Demo? Not in spec; only these four.

## Gates and rules
- **Source-first rule:** anything that can be Metadata API metadata is deployed from `force-app/`. Records are never created through the API for metadata (e.g., UserRole). Only data (users, assignments, seed records) may be created via records, and each such case is listed in the phase evidence.
- **ng-demo gate:** Delete sample roles in ng-demo before deploying roles.
- **Known retrieve gap:** `sf project retrieve start --metadata <type>` returns "Nothing retrieved" for Role, CustomObject, and StandardValueSet on ng-dev. Verify with SOQL/Tooling API until resolved.

## Blocked
- None (CLI upgrade removed the source-format blocker).

## Click steps waiting (owner)
- None yet. Expected: P1-15 user creation review, P1-22 External Client App creation/sign-off, Setup screenshots for evidence (roles, OWD, layouts, apps), M1 gate sign-off.
