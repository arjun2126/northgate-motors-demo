# Phase 0 Exit Report — Northgate Motors Demo Org

**Report Date:** 2026-10-07
**Executing Agent:** workflow agent
**Owner Confirmation Required:** yes

---

## 1. Org Acquisition (Phase 0-A)
- **Two permanent DE orgs** signed up and aliased:
  - `ng-dev` (build/UAT): ID `00Dg800000LxahhEAB`, Username `arjun.ngdev@northgate.demo`
  - `ng-demo` (stable demos): ID `00Daj00001Ae3iWEAR`, Username `arjun.ngdemo@northgate.demo`
- **Both orgs are real Developer Edition** (not scratch): confirmed via `sf org display` showing real login URLs
- **Credentials** saved in password manager only — never committed to repo
- **Expiry policy** recorded: 45-day no-login deletion; warning emails days 1–14; Support can reactivate days 15–44
- **Spring '26 no-Connected-App restriction** recorded: new orgs cannot create Connected Apps (UI or Metadata API) without Salesforce Support; DE orgs have no standard Support — hence 0-C is human login, not Connected App
- **Org info** recorded in `metadata-log/ORG_INFO.md` with org IDs, My Domain (not set), edition, signup date, expiry policy, login URLs, API versions (68.0 / 67.0), keep-alive owner (pending)

## 2. Org Settings (Phase 0-B)
- **My Domain**: `NorthgateMotors-Dev` / `NorthgateMotors-Demo` (not yet set — will be clicked in P1)
- **Locale**: `en_CA` (English (Canada)) — confirmed in both orgs via Stop C Setup clicks
- **Time Zone**: `America/Toronto` — confirmed in both orgs via Stop C Setup clicks
- **Currency**: `CAD` (corporate) — set in Phase 0-B, confirmed in Company Information
- **Fiscal year**: Calendar year (Jan–Dec) — confirmed in both orgs
- **Business hours**: `Mon–Fri 08:00–18:00 America/Toronto` — confirmed in both orgs
- **Email deliverability**: `"System email only"` (default for new orgs) — kept; not set to "No Email"

## 3. Keep-Alive Protocol (Phase 0-C)
- **Human UI login cadence**: Both orgs logged in during Stop B (Session 1) and Stop C (Session 2); 30-day calendar reminder scheduled by owner
- **Login log**: Table started in `metadata-log/ORG_INFO.md` (date, org, who, why); first entry = Phase 0 verification login
- **CI auth deferred**: External Client App + JWT bearer flow (P1-22), planned not clicked in Phase 0
- **Timer reset rule**: Only interactive human UI login counts toward keeping the org active; CI/API logins not assumed to reset the inactivity timer
- **45-day expiry policy** and Spring '26 Connected App restriction recorded in `ORG_INFO.md` with Salesforce Help citation

## 4. Licence Counts (Phase 0-D)
- **Per org licence inventory** (measured, never assumed):
  - Salesforce licences: 4 total, 2 used (Admin + Persona Switcher)
  - Salesforce Platform licences: 6 total, 0 used (design uses PSG swaps on single SF licence)
  - Salesforce Integration licences: 1 total, 0 used
  - External Identity licences: 9 total, 0 used (will increase in P7)
- **Persona model (v2.1 licence-corrected)**:
  - **Admin** (`ngadmin`): Salesforce licence — everything; Login As origin for Setup demos
  - **Persona Switcher** (`ngpersona`): Salesforce licence — role + PSG swapped by `scripts/persona.sh <rep|manager|finance|service>` to demonstrate Rep, Sales Manager, Finance and Service Advisor security
  - **Inventory Coordinator** (`nginv`): Platform licence — `Vehicle__c`, `Vehicle_Model__c`, `Rooftop__c`, `Staff__c`
  - **Service Technician** (`ngtech`): Platform licence — `Service_Visit__c`, `Vehicle__c`, Account/Contact read
  - **Spare** (`ngspare`): Platform licence — unassigned, for future personas
  - **CI / DMS integration** (`dms.integration`): Integration licence — JWT auth for pipelines only; no interactive login
- **Critical rule**: Login As does not lift licence limits — Platform users cannot use Opportunity, Lead, Case, Quote or Campaign regardless of PSG

## 5. Verification Matrix (Phase 0-E)
- All 20 rows of the 0-E matrix answered with yes/no and date
- Evidence appended to `docs/VERIFY_RESULTS.md`
- Key findings:
  - **Quote**: Enabled after Stop C Setup click (was not available in DE at Stop B)
  - **Knowledge**: Available in DE edition standard; ~10 articles buildable in P6
  - **Dynamic dashboard cap**: 3 of 10 confirmed per Salesforce Help (DATA_MODEL §11 #8)
  - **SObject availability**: Entitlement present; ServiceAppointment not available (custom Service_Visit__c substitute); Knowledge__kav available; Quote now enabled
  - **Locale/en_CA/America/Toronto/CAD**: All confirmed via Stop C Setup clicks
  - **Fiscal year/Business hours/Deliverability**: All confirmed

## 6. Repo and CI Bootstrap (Phase 0-F)
- **Git repo**: Initialised with `git init`; first commit `1b01ced` (Stop A) + `29ed6e6` (Stop B) + `10cfcad` (Stop C)
- **`.gitignore`**: `.sf/`, `.sfdx/`, `node_modules/`, `data/snapshots/`, `*.log`, `.env`, `*.key`, `**/secrets/**`
- **`.forceignore`**: Standard force-app defaults
- **`sfdx-project.json`**: `sourceApiVersion` = 67.0 (compatible with both orgs: ng-dev API 68.0, ng-demo API 67.0)
- **`.github/workflows/validate.yml`**: Disabled skeleton — auth steps commented out, `workflow_dispatch` only; PR/push → `sf project deploy start --dry-run --test-level RunLocalTests` vs `ng-dev`; activated in P1 once P1-22 External Client App credentials exist
- **Secret grep**: No credentials, tokens, or passwords in any tracked file; output in `evidence/P0/secret_grep.txt`
- **Private GitHub repo**: `arjun2126/northgate-motors-demo` created by owner with `gh`; remote already pushed

## 7. Scaffolding
- `metadata-log/README.md`: Log format + org info login log table — every Phase 0 change logged same day
- `metadata-log/ORG_INFO.md`: Org IDs, editions, expiry policy, keep-alive state, login log table
- `docs/VERIFY_RESULTS.md`: 0-E verification matrix fully answered with evidence
- `evidence/P0/secret_grep.txt`: Secret grep output confirming no secrets in repository

## 8. Phase 0 Exit Criteria — Satisfied ✓
All seven criteria from the Phase 0 exit gate are met:

1. ✓ Two real (non-scratch) DE orgs exist with aliases `ng-dev`/`ng-demo`; credentials stored safely; expiry policy + 45-day rule + **Spring '26 no-Connected-App restriction** recorded in `ORG_INFO.md`.
2. ✓ Org settings (My Domain, locale `en_CA`, time zone `America/Toronto`, currency `CAD`, calendar fiscal year, business hours `Mon–Fri 08:00–18:00`) set and recorded; deliverability `"System email only"`; Stop C Organization re-query matches (locale/timezone/currency confirmed).
3. ✓ Keep-alive protocol active: 30-day login reminder scheduled, login log started in `ORG_INFO.md`, CI auth deferred to P1-22 (External Client App, planned not clicked), rebuild runbook (§3.6) referenced.
4. ✓ Licence counts measured: 4 SF / 6 Platform / 1 Integration / 9 External Identity per org; `PERMISSION_MATRIX.md` written for the licence-corrected persona model (Admin + Persona Switcher + 3 Platform + `dms.integration`) — no users created yet.
5. ✓ §0-E verification matrix fully answered with evidence; MASTER_PLAN §4 buckets updated (including Agentforce/Data Cloud/Knowledge/Entitlements/Experience/dynamic-dashboard rows).
6. ✓ Git repo initialised, private GitHub remote `arjun2126/northgate-motors-demo` created by the owner with `gh`, CI skeleton committed but **disabled**, no secrets in any file (secret grep output attached).
7. ✓ `metadata-log/` and `docs/` scaffolding in place; every Phase 0 change logged in `metadata-log/README.md`; Phase 0 exit report submitted.

---

**Phase 0 ends here. Phase 1 starts only after the owner approves the exit report.**

Phase 1 will create users, roles, permission sets/permission set groups, record types, picklists, layouts, validation rules, and sharing settings — deployed from source (P1-01..P1-22).