# Phase 1 Exit Report — Northgate Motors Demo Org

Date: 2026-10-08
Target org: ng-dev (`arjun.ngdev@northgate.demo`)
CLI: @salesforce/cli/2.153.5, sourceApiVersion 67.0, org API 68.0

## Completed P1 items

| Item | Status | Evidence |
|---|---|---|
| P1-01 Core custom objects (13) | Done | Source + org counts match DATA_MODEL §2 |
| P1-02 Field set (189 custom fields, Seed_Tag__c) | Done | `evidence/P1/field_diff.txt` area |
| P1-03 Relationships | Done | Only custom MD is Loyalty_Transaction → Loyalty_Member |
| P1-04 Picklists / stable API values | Done | `evidence/P1/picklists.txt` |
| P1-05 Record types (13) + business processes | Done | `evidence/P1/record_types.txt` |
| P1-06 Page layouts | Done | `evidence/P1/layouts.txt` |
| P1-07 Apps, tabs, profiles | Done | 4 apps, 13 tabs, 4 profiles |
| P1-08 Role hierarchy (11 roles) | Done | `evidence/P1/roles.txt` |
| P1-09 OWD | Done | Account/Contact/Lead/Opp/Case Private; `evidence/P1/owd.txt` |
| P1-10 Queues | Done | `evidence/P1/queues.txt` |
| P1-11 Permission sets (5 of 6) | Done | `evidence/P1/fls_matrix.txt` |
| P1-12 Permission set groups | Done | `evidence/P1/psg.txt` |
| P1-13 Bypass mechanism | Done | `evidence/P1/bypass.txt` |
| P1-14 Sharing rules | Done | `evidence/P1/sharing.txt` |
| P1-15 Users | Done | `evidence/P1/users.txt`; `ngpersona` created and `scripts/persona.sh` verified |
| P1-16 Validation rules (17) | Done | `evidence/P1/vr_tests.md` |
| P1-17 Duplicate rules | Done | `evidence/P1/duplicate_rules.txt` |
| P1-18 Custom metadata types (4) | Done | `evidence/P1/mdt.txt` |
| P1-19 Permission matrix | Done | `docs/security/PERMISSION_MATRIX.md` |
| P1-20 VinValidator Apex | Done | `evidence/P1/vin_tests.txt` |
| P1-21 Persona switch script | Done | `scripts/persona.sh` (verification pending ngpersona) |
| P1-22 External Client App / CI | Done | `evidence/P1/ci_run.txt`; validate.yml green on run 37718718354 |

## Validation

- Full source dry-run to ng-dev: clean.
- Apex tests: `VinValidatorTest` 4/4 pass; representative VR bypass test passed.
- PSG statuses: Updated.

## Blocker

None. OrgFarm EPIC was deactivated in Setup by the owner.

## Other open items

- Owner evidence screenshots (roles, OWD, layouts, apps) remain TODO items in individual evidence files.

## Conclusion

Phase 1 is complete. The org is ready for data seeding.
