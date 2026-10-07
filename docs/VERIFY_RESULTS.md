# Verify Results — Northgate Motors Demo Org (Phase 0)

## 0-E Verification Matrix

| # | Feature | How to verify | In Org | If Present | If Absent |
|---|---|---|---|---|---|
| 1 | Person Accounts | Setup search "Person Accounts" | | Do not enable (one-way) — Account.Type = Household | Build Household as planned |
| 2 | Multi-currency | Setup → Company Information | | See 0-B | Single CAD build |
| 3 | Duplicate rules on Contact/Account | Setup → Duplicate Rules | | Use native matching rules | Build DR_Contact_Email / DR_Account_NamePostcode (P1) |
| 4 | Sales Cloud Einstein / Lead Scoring | Setup → Einstein | | Record in ledger §4 | Not built; no invented score field |
| 5 | Field Service (ServiceAppointment) | Setup → Field Service | | Still prefer custom Service_Visit__c — standard collision risk | Custom Service_Visit__c as planned |
| 6 | Omni-Channel | Setup → Omni-Channel | | Small P6 add-on if truly free | Flow-based assignment (planned) |
| 7 | Knowledge | Setup → Knowledge | | Plan to build — ~10 articles in P6 (standard in this edition) | Case templates as documents |
| 8 | Entitlements + Milestones | Setup → Entitlements | | Plan to build in P6 (SLA skill) | Flow-based SLA stamps (fallback) |
| 9 | Service Console app | Setup → App Manager | | Use for service persona demo | Custom app only |
| 10 | Experience Cloud + External Identity licences | Setup → Digital Experiences + licence count | | Small real site in P7 (1–2 External Identity users) | Simulation only (documented) |
| 11 | Agentforce (service agent, Prompt Builder) | Setup → Agentforce; attempt agent creation | | Small real build in P7 (≈150 LLM req/hr) | Simulated triage fallback, labelled |
| 12 | Data Cloud (10 GB, 1 data space, manual refresh) | Setup → Data Cloud | | Small real build in P7 (ingest + identity resolution) | Ledger note only |
| 13 | Dynamic dashboards (limit = 3 — confirmed in Salesforce Help) | Create 1 dynamic dashboard, count remaining | | Mark exactly 3 dynamic (P2-11, P5-14, P6-09); rest fixed-user | Fixed-user dashboards only |
| 14 | Enterprise Territory Management | Setup search | | Optional sharing demo | Sharing rules only |
| 15 | Standard Quote/CPQ | Setup → Sales → Quotes | | Standard Quote (as planned) | Quote simulation fallback |
| 16 | Web-to-Lead | Setup → Web-to-Lead | | Lead intake demo | Flow file-upload intake |
| 17 | Change Data Capture availability | Setup search / sf data | | Ledger note (bonus) | Ignore |
| 18 | Sandbox types on DE | sf org list / Setup → Sandboxes | | Use for preview if present | Never a scratch org — ng-demo itself is the preview target |
| 19 | Report/folder limits | Create 1 folder per type, observe cap | | Stay under cap | Consolidate folders |
| 20 | Deployment status / packaging limits | Setup → Deployment Status | | Note for release strategy | Unlocked package still preferred |

**Notes:** Each row must be answered yes/no with date. Never assume. Update MASTER_PLAN §4 bucket column. Append results to `docs/VERIFY_RESULTS.md` with the date.

---

Storage Baseline: ≤ 4.0 MB after full reset (per SYNTHETIC_DATA_PLAN.md §2.1)
Licence Baseline: ≈2 SF / ≈3 Platform / ≈1 Integration / ≈5 External Identity (measured in 0-D)
Dynamic Dashboard Cap: exactly 3 of 10 (confirmed in Salesforce Help, DATA_MODEL §11 #8)