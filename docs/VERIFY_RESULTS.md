# Verify Results — Northgate Motors Demo Org (Phase 0)

## 0-E Verification Matrix

| # | Feature | How to verify | In Org | If Present | If Absent |
|---|---|---|---|---|---|
| 1 | Person Accounts | Setup search "Person Accounts" | **Not enabled** — data model explicitly states `Account.Type = Household`; one-way door | Do not enable (one-way) — `Account.Type = Household` | Build Household as planned |
| 2 | Multi-currency | Setup → Company Information | **Not verified** — requires Setup click (currency set in Phase 0-B) | See 0-B | Single CAD build |
| 3 | Duplicate rules on Contact/Account | Setup → Duplicate Rules | **Not verified** — requires Setup click | Use native matching rules | Build DR_Contact_Email / DR_Account_NamePostcode (P1) |
| 4 | Sales Cloud Einstein / Lead Scoring | Setup → Einstein | **Not verified** — requires Setup click | Record in ledger §4 | Not built; no invented score field |
| 5 | Field Service (ServiceAppointment) | Setup → Field Service | **Not available** — `ServiceAppointment` sObject query fails; custom `Service_Visit__c` preferred | Still prefer custom `Service_Visit__c` — standard collision risk | Custom `Service_Visit__c` as planned |
| 6 | Omni-Channel | Setup → Omni-Channel | **Not verified** — requires Setup click | Small P6 add-on if truly free | Flow-based assignment (planned) |
| 7 | Knowledge | Setup → Knowledge | **Available in DE** — standard in this edition; ~10 articles buildable in P6 | Plan to build — ~10 articles in P6 (standard in this edition) | Case templates as documents |
| 8 | Entitlements + Milestones | Setup → Entitlements | **Available** — `Entitlement` sObject query succeeds; SLA skill buildable | Plan to build in P6 (SLA skill) | Flow-based SLA stamps (fallback) |
| 9 | Service Console app | Setup → App Manager | **Not verified** — requires Setup click | Use for service persona demo | Custom app only |
| 10 | Experience Cloud + external licenses | Read-only ng-demo settings/license inventory, 2026-10-26 | **CONFIRMED** Networks disabled/no Site. Community/Plus/Partner each 5 total/0 used; External Identity 9/0 | Owner chooses/enables approved site and per-object license/security model before P7-18 build | No automatic simulation or enablement |
| 11 | Agentforce and Prompt Builder | Read-only ng-demo settings/metadata, 2026-10-26 | **CONFIRMED** Prompt platform enabled; Agent Platform/Copilot/Bots disabled. Draft template check-only 1/1; runtime/quota not verified | Owner capability/identity/usage decisions required for actual agent demo | No new Flow fallback without explicit amendment |
| 12 | Data Cloud | Read-only ng-demo settings/object inventory, 2026-10-26 | **CONFIRMED** CustomerDataPlatform disabled, stream count 0, DataSpace not exposed; historical 10 GB/credit assumption unverified | Owner enables/provisions approved space/limits/source before native ingestion | No custom duplicate data-model substitute |
| 13 | Dynamic dashboards (limit = 3 — confirmed in Salesforce Help) | Create 1 dynamic dashboard, count remaining | **Not verified** — requires dashboard creation; limit confirmed as 3 of 10 in Help | Mark exactly 3 dynamic (P2-11, P5-14, P6-09); rest fixed-user | Fixed-user dashboards only |
| 14 | Enterprise Territory Management / Sales Territories | Settings/authorized deployment/read-only SOQL, ng-demo only | **CONFIRMED — 2026-10-26 UTC:** NG_Rooftops deployed in Planning, shared type/four siblings with Read/None/None/None persisted, zero Account/User associations | Assignment/identity/activation and actual tree/persona acceptance still need approval/evidence | No substitute without owner disposition |
| 15 | Standard Quote/CPQ | Setup → Sales → Quotes | **Enabled** — Quote sObject now present after Setup click; Standard Quote (as planned) | Standard Quote (as planned) | Quote simulation fallback |
| 16 | Web-to-Lead | Setup → Web-to-Lead | **Not verified** — requires Setup click | Lead intake demo | Flow file-upload intake |
| 17 | Change Data Capture availability | Setup search / sf data | **Not verified** — requires Setup click | Ledger note (bonus) | Ignore |
| 18 | Sandbox types on DE | `sf org list` / Setup → Sandboxes | **ng-demo is the preview target** — no separate sandbox types; DE itself is permanent org | Use for preview if present | Never a scratch org — ng-demo itself is the preview target |
| 19 | Report/folder limits | Create 1 folder per type, observe cap | **Not verified** — requires folder creation | Stay under cap | Consolidate folders |
| 20 | Deployment status / packaging limits | Setup → Deployment Status | **Not verified** — requires Setup click | Note for release strategy | Unlocked package still preferred |

**Notes from read-only checks (Stop B) and Setup clicks (Stop C):**

- **Later P7-12 update, ng-demo only (2026-10-26 UTC):** owner enabled Sales Territories;
  agent performed read-only verification. Raw settings/query evidence and remaining actions:
  `evidence/P7/P7_12_READ_ONLY_REVERIFICATION.md`. Other historical matrix rows were not re-audited.

- **Org usernames confirmed**: `arjun.ngdev@northgate.demo` (ng-dev), `arjun.ngdemo@northgate.demo` (ng-demo) — match plan
- **Org IDs**: ng-dev = `00Dg800000LxahhEAB`, ng-demo = `00Daj00001Ae3iWEAR`
- **API versions**: ng-dev = 68.0, ng-demo = 67.0 — `sfdx-project.json` updated to `sourceApiVersion: 67.0`
- **Locale**: `en_CA` confirmed in both orgs (Setup click applied at Stop C) ✓
- **TimeZone**: `America/Toronto` confirmed in both orgs (Setup click applied at Stop C) ✓
- **Currency**: CAD set (per 0-B, recorded in Company Information) ✓
- **Fiscal year**: Calendar year (Jan–Dec) confirmed ✓
- **Business hours**: `Mon–Fri 08:00–18:00 America/Toronto` confirmed ✓
- **Email deliverability**: "System email only" (default, kept) ✓
- **Quote sObject**: Now enabled after Setup click at Stop C — was "not available" in DE at Stop B, now present ✓
- **Knowledge**: Available in DE edition; ~10 articles buildable in P6 ✓
- **Dynamic dashboard cap**: 3 of 10 confirmed per Salesforce Help (DATA_MODEL §11 #8)
- **SObject availability**: `Entitlement` present; `ServiceAppointment` not available (custom `Service_Visit__c` substitute); `Knowledge__kav` available; `Quote` now enabled after Setup click
- **No Setup changes made beyond Stop C clicks**: All checks were read-only or click-based; logged in metadata-log

---

Storage Baseline: ≤ 4.0 MB after full reset (per SYNTHETIC_DATA_PLAN.md §2.1)
Licence Baseline: 4 SF licences per org (2 used, 2 free — Admin + Persona Switcher); ≈3 Platform licences per org (0 used, design uses PSG swaps on single SF licence); ≈1 Integration licence per org (0 used); ≈5 External Identity licences per org (9 total, 0 used per org)
Dynamic Dashboard Cap: exactly 3 of 10 (confirmed in Salesforce Help, DATA_MODEL §11 #8)
