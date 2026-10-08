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
- **P1-04 (pending fix)** picklist API values are `Title_Case_With_Underscores` except `Vehicle__c.Condition__c.Certified_Pre-Owned` (hyphen). `Term_Months__c` is Number ✓.

## Next
**P1-04** — rename `Certified_Pre-Owned` → `Certified_Pre_Owned`, dry-run, deploy, evidence `evidence/P1/picklists.txt`, commit.

Then in backlog order: P1-05 record types, P1-06 layouts, P1-07 apps/tabs/profiles, P1-08 roles, P1-09 OWD, P1-10 queues, P1-11 remaining sets, P1-12 groups, P1-13 custom permission, P1-14 sharing, P1-15 users, P1-16 VRs, P1-17 dup rules, P1-18 CMDTs, P1-19 matrix, P1-20 VinValidator, P1-21 persona script, P1-22 External Client App → M1 gate.

## Blocked
- None (CLI upgrade removed the source-format blocker).

## Click steps waiting (owner)
- None yet. Expected: P1-15 user creation review, P1-22 External Client App creation/sign-off, Setup screenshots for evidence (roles, OWD, layouts, apps), M1 gate sign-off.
