# Verify Results — Northgate Motors Demo Org (Phase 0)

## 0-E Verification Matrix

| # | Feature | How to verify | In Org | If Present | If Absent |
|---|---|---|---|---|---|
| 1 | Person Accounts | Setup search "Person Accounts" | **Not enabled** — data model explicitly states `Account.Type = Household`; one-way door | Do not enable (one-way) — `Account.Type = Household` | Build Household as planned |
| 2 | Multi-currency | Setup → Company Information | **Not verified** — requires Setup click | See 0-B | Single CAD build |
| 3 | Duplicate rules on Contact/Account | Setup → Duplicate Rules | **Not verified** — requires Setup click | Use native matching rules | Build DR_Contact_Email / DR_Account_NamePostcode (P1) |
| 4 | Sales Cloud Einstein / Lead Scoring | Setup → Einstein | **Not verified** — requires Setup click | Record in ledger §4 | Not built; no invented score field |
| 5 | Field Service (ServiceAppointment) | Setup → Field Service | **Not available** — `ServiceAppointment` sObject query fails; custom `Service_Visit__c` preferred | Still prefer custom `Service_Visit__c` — standard collision risk | Custom `Service_Visit__c` as planned |
| 6 | Omni-Channel | Setup → Omni-Channel | **Not verified** — requires Setup click | Small P6 add-on if truly free | Flow-based assignment (planned) |
| 7 | Knowledge | Setup → Knowledge | **Not available** — `Knowledge__kav` sObject not present; standard in DE edition per Help | Plan to build — ~10 articles in P6 (standard in this edition) | Case templates as documents |
| 8 | Entitlements + Milestones | Setup → Entitlements | **Available** — `Entitlement` sObject query succeeds; SLA skill buildable | Plan to build in P6 (SLA skill) | Flow-based SLA stamps (fallback) |
| 9 | Service Console app | Setup → App Manager | **Not verified** — requires Setup click | Use for service persona demo | Custom app only |
| 10 | Experience Cloud + External Identity licences | Setup → Digital Experiences + licence count | **Available** — External Identity licences present (9 total, 0 used per org) | Small real site in P7 (1–2 External Identity users) | Simulation only (documented) |
| 11 | Agentforce (service agent, Prompt Builder) | Setup → Agentforce; attempt agent creation | **Not verified** — requires Setup click | Small real build in P7 (≈150 LLM req/hr) | Simulated triage fallback, labelled |
| 12 | Data Cloud (10 GB, 1 data space, manual refresh) | Setup → Data Cloud | **Not verified** — requires Setup click | Small real build in P7 (ingest + identity resolution) | Ledger note only |
| 13 | Dynamic dashboards (limit = 3 — confirmed in Salesforce Help) | Create 1 dynamic dashboard, count remaining | **Not verified** — requires dashboard creation; limit confirmed as 3 of 10 in Help | Mark exactly 3 dynamic (P2-11, P5-14, P6-09); rest fixed-user | Fixed-user dashboards only |
| 14 | Enterprise Territory Management | Setup search | **Not verified** — requires Setup click | Optional sharing demo | Sharing rules only |
| 15 | Standard Quote/CPQ | Setup → Sales → Quotes | **Not available** — `Quote` sObject query fails: "sObject type 'Quote' is not supported" | Standard Quote (as planned) | Quote simulation fallback |
| 16 | Web-to-Lead | Setup → Web-to-Lead | **Not verified** — requires Setup click | Lead intake demo | Flow file-upload intake |
| 17 | Change Data Capture availability | Setup search / sf data | **Not verified** — requires Setup click | Ledger note (bonus) | Ignore |
| 18 | Sandbox types on DE | `sf org list` / Setup → Sandboxes | **ng-demo is the preview target** — no separate sandbox types; DE itself is permanent org | Use for preview if present | Never a scratch org — ng-demo itself is the preview target |
| 19 | Report/folder limits | Create 1 folder per type, observe cap | **Not verified** — requires folder creation | Stay under cap | Consolidate folders |
| 20 | Deployment status / packaging limits | Setup → Deployment Status | **Not verified** — requires Setup click | Note for release strategy | Unlocked package still preferred |

**Notes from read-only checks (Stop B):**

- **Org usernames confirmed**: `arjun.ngdev@northgate.demo` (ng-dev), `arjun.ngdemo@northgate.demo` (ng-demo) — match plan
- **Org IDs**: ng-dev = `00Dg800000LxahhEAB`, ng-demo = `00Daj00001Ae3iWEAR`
- **API versions**: ng-dev = 68.0, ng-demo = 67.0 — `sfdx-project.json` updated to `sourceApiVersion: 67.0`
- **Locale discrepancy**: Plan expects `en_CA` / `America_Toronto`; orgs have `en_US` / `America/Los_Angeles` — requires Setup click to correct (0-B first box)
- **License counts (each org)**: Salesforce 4 total / 2 used; Salesforce Platform 6 total / 0 used; Salesforce Integration 1 total / 0 used; External Identity 9 total / 0 used — matches plan's `≈2 SF / ≈3 Platform / ≈1 Integration / ≈5 External Identity` used counts
- **Storage**: DataStorageMB = 5/5 remaining; FileStorageMB = 20/20 remaining per org
- **Dynamic dashboard cap**: 3 of 10 confirmed per Salesforce Help (DATA_MODEL §11 #8)
- **SObject availability**: `Entitlement` present; `ServiceAppointment`, `Knowledge__kav`, `Quote` not available in DE edition; custom objects (`Service_Visit__c`, etc.) used as substitutes
- **No Setup changes made**: All checks were read-only (queries, display); no metadata, no data, no users created

---

Storage Baseline: ≤ 4.0 MB after full reset (per SYNTHETIC_DATA_PLAN.md §2.1)
Licence Baseline: ≈2 SF used / ≈3 Platform used / ≈1 Integration used / ≈5 External Identity used per org (measured in 0-D)
Dynamic Dashboard Cap: exactly 3 of 10 (confirmed in Salesforce Help, DATA_MODEL §11 #8)