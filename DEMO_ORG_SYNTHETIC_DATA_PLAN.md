# Synthetic Data Plan — Northgate Motors

**Status:** LOADED WITH DOCUMENTED EXCEPTIONS in `ng-demo`; Phase 5 was owner-accepted with
documented exceptions on October 23, 2026. Exact count/storage and historical provenance
exceptions remain; this is not unconditional original-criteria acceptance.

Recorded seed version: `SEED-2026.10.01`; anchor: `2026-10-01`. The initial seed load is
recorded on `2026-10-18`; cleanup and the 30-row legacy supplement were executed on
`2026-10-21` (`docs/planning/P5_EXECUTION_REPORT_2026-10-21.md`). No reload was performed
for the `2026-10-23` executive-reporting activation. Exact canonical/live count ties,
precise storage evidence and historical ledger/marker reconciliation remain exceptions;
this status is not a claim that every original acceptance criterion passed. See the
P5-01 through P5-20 closure candidate in `DEMO_ORG_BACKLOG.md` and
`docs/planning/P5_TO_P6_HANDOFF_2026-10-23.md`. Historical `SEED_VERSION.txt` load/status
markers have not been rewritten to manufacture provenance.

Companions: `DEMO_ORG_MASTER_PLAN.md` (§3.5 keep-alive, §8 reset, §10 docs),
`DEMO_ORG_DATA_MODEL.md` (fields, §5.6 automation map), `DEMO_ORG_BACKLOG.md` (P5-*).

---

## 1. Principles

1. **Storage-budgeted.** Developer Edition data storage is 5 MB, ≈2 KB per record
   (activities ≈1 KB, campaigns ≈8 KB). Every record is budgeted in §2 before it is
   generated. Nothing loads above 4.0 MB; ~1 MB is kept as live-demo headroom.
2. **Business-real, schema-valid.** Seeded data passes every release-gate check (§9a).
   Deliberately bad data exists only where a demo needs it: business-bad rows in `SEED-99`
   (§7) and schema-invalid rows in the legacy-import batch `SEED-98` (§7.1), the latter
   loaded with bypass on and never mixed into clean batches.
3. **Fully resettable.** Every row carries **one field: `Seed_Tag__c`** (Text 80,
   External ID, Unique, not mapped during Lead conversion) — on custom and standard
   objects alike (data model §4). Reset = delete by tag, purge Recycle Bin, reload.
4. **Deterministic and reproducible.** Generator seeded from a fixed seed; the anchor date
   is a parameter stored in `SEED_VERSION.txt` (`ANCHOR_DATE=YYYY-MM-DD`), so regenerating
   on any day with the same anchor reproduces identical rows.
5. **Time-spread, not time-stamped-today.** Dates spread over a rolling 18-month window
   ending at `ANCHOR_DATE`, so funnel velocity, ageing and trend reports have history.
6. **Vehicles are the spine.** Load order starts with rooftops, models and vehicles.
7. **Fictional only.** Invented makes/models (Aurelia, Cascadia, Meridian, Vantage,
   Halcyon, Kestrel), invented lenders (Northgate Financial, Maple Trust, Cascade Credit
   Union), invented people, reserved `.test` email domains, fictional postal codes.
8. **Idempotent loads.** Upsert on `Seed_Tag__c` (§4) — a re-run after partial failure
   repairs, never duplicates.

---

## 2. Storage budget (the controlling constraint)

Developer Edition: **5 MB data storage ≈ 2 KB/record** (Task/Event ≈1 KB, Campaign
≈8 KB), roughly 2,500 records. Budget: **≤ 4.0 MB**, leaving **≈1 MB headroom** for live
demo work (users creating test drives, cases, quotes on camera).

### 2.1 Envelope (final loaded counts)

| # | Object | Count | KB/ea | KB | Notes |
|---|---|---|---|---|---|
| 1 | `Rooftop__c` | 4 | 2 | 8 | |
| 2 | `Vehicle_Model__c` | 30 | 2 | 60 | 6 makes × 5 trims |
| 3 | `Vehicle__c` | 120 | 2 | 240 | Split §2.2 |
| 4 | Product2 | 60 | 2 | 120 | 30 trims + 5 packages + 25 accessories (matches `data/scripts/generate.ts`; PBE row stays 1:1) |
| 5 | PricebookEntry | 60 | 2 | 120 | 1 PBE per Product (unchanged) |
| 6 | Account | 150 | 2 | 300 | incl. 8 BAD-01 duplicate households |
| 7 | Contact | 185 | 2 | 370 | ~1.9 per household; incl. BAD-01 contacts |
| 8 | Lead | 130 | 2 | 260 | Unconverted only — see §2.3 |
| 9 | Opportunity | 100 | 2 | 200 | Split §2.4; 12 Closed Won unchanged |
| 10 | OpportunityLineItem | 100 | 2 | 200 | |
| 11 | Quote | 60 | 2 | 120 | incl. 4 BAD-09 stacked-discount quotes |
| 12 | QuoteLineItem | 80 | 2 | 160 | |
| 13 | `Trade_In__c` | 45 | 2 | 90 | |
| 14 | `Financing__c` | 60 | 2 | 120 | |
| 15 | `Delivery__c` | 12 | 2 | 24 | 1:1 with Closed Won opptys per §2.4 (matches `data/scripts/generate.ts`) |
| 16 | `Test_Drive__c` | 70 | 2 | 140 | |
| 17 | `Service_Visit__c` | 140 | 2 | 280 | Split §2.5 |
| 18 | Case | 60 | 2 | 120 | |
| 19 | `Loyalty_Member__c` | 70 | 2 | 140 | Split §2.6 |
| 20 | `Loyalty_Transaction__c` | 110 | 2 | 220 | |
| 21 | `Consent__c` | 90 | 2 | 180 | |
| 22 | `Staff__c` | 14 | 2 | 28 | |
| 23 | Campaign | 5 | 8 | 40 | 8 KB each |
| 24 | CampaignMember | 60 | 2 | 120 | |
| 25 | `Data_Load_Batch__c` | 20 | 2 | 40 | Loader-written ledger |
| | **Clean subtotal (`SEED-01..76`)** | **1,835** | | **3,700** | |
| 26 | Legacy import `SEED-98` | 30 | 2 | 60 | Schema-invalid on purpose — §7.1 |
| | **Non-activity total** | **1,865** | | **3,760** | incl. campaigns (40 KB) |
| 27 | Task + Event | 250 | 1 | 250 | Activities ≈1 KB |
| | **TOTAL** | **2,115** | | **4,010 KB = 3.92 MB** | of 5 MB |
| | **Headroom** | | | **1,110 KB = 1.08 MB** | live demos + burst |

Arithmetic (single consistent convention: 2 KB per non-campaign record, 8 KB per Campaign record, 1 KB per activity):

- Clean non-campaign records 1,830 × 2 KB = 3,660
- Campaign 5 × 8 KB = 40
- Clean subtotal (campaigns + non-campaigns) = 3,660 + 40 = **3,700 KB** (1,835 records)
- SEED-98 legacy 30 × 2 KB = 60
- Non-activity total = 3,700 + 60 = **3,760 KB** (1,865 records)
- Activities 250 × 1 KB = 250
- **TOTAL = 3,760 + 250 = 4,010 KB = 3.92 MB** (2,115 records)
- **Headroom = 5,120 − 4,010 = 1,110 KB = 1.08 MB** (using 5 MB = 5,120 KB convention; matches original plan's `5,120 - 4,026 = 1,094 KB` formula)

BAD-99 rows are inside the envelope object counts; only `SEED-98` (30) is additional.

### 2.2 Vehicle split (120)

| Status | Count | Purpose |
|---|---|---|
| `Available` | 70 | Live inventory, ageing reports |
| `Reserved` | 14 | Pipeline |
| `Sold` | 18 | History |
| `Delivered` | 8 | Closed-won anchor |
| `In_Appraisal` | 5 | Trade-in flow |
| `In_Transit` | 3 | Arrival workflow |
| `On_Hold` | 2 | Edge state |

Condition split: New 45% / Certified_Pre-Owned 25% / Used 30%.
Aged >60 days: ~15 (≈12%) so `Is_Aged_60__c` reports are non-trivial; 12 of them >120
days (BAD-06).

### 2.3 Lead split (130) — no `Converted` rows

| Status | Count |
|---|---|
| `Open` | 45 |
| `Working` | 32 |
| `Qualified` | 28 |
| `Unqualified` | 25 |

**Decision:** converted leads are never seeded (Salesforce conversion writes
irreversible link fields that a load cannot fake). The 30 conversions the old plan wanted
exist as **Account + Contact + Opportunity triples tagged `SEED-07-CONV-*`** —
indistinguishable in reports from real conversions, minus the Lead row.

Source mix: Web 35% / Walk_In 20% / Referral 15% / Social 15% / Event 10% / Phone 5%.
Age spread: 18 months back from `ANCHOR_DATE`, with 35 of 130 deliberately stale
(BAD-02). Lead routing demo: ~80% of leads match their rooftop's Ontario FSA prefix
(downtown `M*`, North `L4H*`, Airport `L5V*`, Service Centre `L1G*`).

### 2.4 Opportunity split (100)

| Stage | Count |
|---|---|
| `Prospecting` | 10 |
| `Qualification` | 12 |
| `Test_Drive` | 12 |
| `Appraisal` | 9 |
| `Quoting` | 11 |
| `Financing` | 11 |
| `Closed Won` | 12 |
| `Closed Lost` | 23 |

Win rate ≈ 21% of closed (12 of 35) — realistic and enough for funnel reports.
Won opportunities all have a `Completed` `Delivery__c`, a financing row (or
`Self_Funded` with amount 0), ≥1 quote, and `Delivery_Completed__c = TRUE`.

### 2.5 Service visits (140)

Status mix: Completed 70 / Scheduled 35 / Checked_In 10 / In_Progress 8 /
Requested 8 / No_Show 5 / Cancelled 4. Twelve are overdue (past, still `Scheduled` —
BAD-04). Advisor distribution across the 14 `Staff__c` rows follows staffing:
Downtown-heavy.

### 2.6 Loyalty (70 members)

Bronze 39 / Silver 18 / Gold 9 / Platinum 4 (55/25/13/7%).
Members drawn from contacts with ≥1 won opportunity or ≥2 service visits — loyalty is
earned, not assigned at random. ~110 transactions, ≈1.6 per member.

### 2.7 Burst set (volume screenshots only)

A separate, disposable data set — **not part of the envelope**, loaded on demand:

| Burst object | Records |
|---|---|
| Lead | +200 |
| `Service_Visit__c` | +60 |
| Task | +40 |
| **Total** | **+300 (≈+600 KB)** |

Protocol: load burst → take the volume screenshot → `sf data delete bulk` by
`SEED-77-BURST-*` tag → **empty Recycle Bin** → Storage Usage check back to 3.93 MB.
Peak during burst ≈ 4.5 MB — never above 5 MB. Never presented as permanent data.

---

## 3. Distributions and realism rules

| Dimension | Rule |
|---|---|
| Names | Seeded from a bundled fictional first/last list (~120 first, ~120 last). No real people. |
| Emails | `first.last@` + reserved domains (`example.test`, `northgate-demo.test`). **Never deliverable.** |
| Phone | Durham/GTA area codes **416 / 905 / 289**, fictional `555-01xx` block: e.g. `+1 416-555-0142` |
| Postal codes | Valid format, reserved example blocks; FSA prefix drives lead→rooftop routing |
| Addresses | Fictional street names |
| Currency | CAD everywhere; prices cluster by segment (Entry $24–34k, Mainstream $34–52k, Premium $52–88k) |
| MSRP vs list | List price within ±8% of MSRP; used vehicles derive from year/odometer decay curve |
| Odometer | New <50 km; CPO 15k–45k; Used 60k–190k, correlated with year |
| VINs | §5: unique, ISO 3779 check-digit valid; `Is_VIN_Valid__c` set by Apex `VinValidator` |
| Dates | Won opps spread over 18 months before `ANCHOR_DATE`; open opps weighted to last 90 days |
| Follow-through | A contact with a won opp has a later service visit; a contact with a trade-in has financing ≥70% of the time |
| Lead routing | Ontario FSA prefixes only (all four rooftops are in Ontario): `M*` downtown, `L4H*` North, `L5V*` Airport, `L1G*` Service Centre; ~80% match rate, 20% deliberate mismatch for the exception report |
| Staff attribution | Every opportunity/service visit points at a `Staff__c` row, never a User |
| Names unique-ish | ≤3 contacts share a full name (duplicate-rule demos) |

---

## 4. Load method and order

**v2 loader: bulk upsert, not tree import.** `sf data import tree` inserts only and
duplicates records when re-run after a partial failure. The loader is:

```
sf data upsert bulk <Object> --file data/csv/NN-<object>.csv --external-id Seed_Tag__c
```

per object, in dependency order — **re-runnable by design**: an upsert with the same
`Seed_Tag__c` updates instead of inserting.

| # | Object(s) | Depends on | Notes |
|---|---|---|---|
| 1 | `Rooftop__c` | — | |
| 2 | `Vehicle_Model__c` | — | |
| 3 | Product2, Pricebook2, PricebookEntry | — | |
| 4 | `Staff__c` | 1 | |
| 5 | `Vehicle__c` | 1, 2 | parent refs by external-ID relationship |
| 6 | Account | 1 | |
| 7 | Contact | 6 | |
| 8 | Lead | 1 | unconverted only |
| 9 | Opportunity | 5, 6, 7 | |
| 10 | OpportunityLineItem | 3, 9 | |
| 11 | Quote + QuoteLineItem | 7, 9 | |
| 12 | `Trade_In__c` | 9, 7 | |
| 13 | `Financing__c` | 9, 7, 5 | |
| 14 | `Delivery__c` | 9, 5, 7 | |
| 15 | `Test_Drive__c` | 5, 7, 9 | |
| 16 | Case | 6, 7, 5 | |
| 17 | `Service_Visit__c` | 5, 7, 16, 4 | advisor/technician → Staff |
| 18 | Campaign + CampaignMember | 7, 8 | |
| 19 | `Loyalty_Member__c` | 7 | |
| 20 | `Loyalty_Transaction__c` | 19, 9, 17 | |
| 21 | `Consent__c` | 7 | |
| 22 | Task + Event | 7, 9, 17 | |
| 23 | `Data_Load_Batch__c` | all | written by loader |
| 77 | Burst set | 1–22 | `SEED-77-BURST-*`, disposable (§2.7) |
| 98 | Legacy import | 1–22 | `SEED-98-*`, **bypass on**, schema-invalid (§7.1) |
| 99 | Business-bad batch | 1–22 | `SEED-99-*`, business-bad (§7) |

**Parent references (v2.1, decision #7 closed).** Child CSVs carry parent `Seed_Tag__c`
values in **external-ID relationship columns** (e.g. a `Vehicle__r.Seed_Tag__c` column),
so the load needs **no separate ID-resolution pass** — `resolve.ts` is retired from the
plan. Standard-object references that have no seed key (`OwnerId`, `ReportToId`) are
mapped by **username**: a fixed persona username → Id map resolved once at load start in
`load.ts` (usernames are stable, §6.1 of the data model). Native
`sf data upsert bulk` with relationship columns is the closed decision; **SFDMU remains
an optional later upgrade only** — and only if the Bulk API turns out to reject
relationship columns for a given object, verified at P5-02.

**Bypass during load.** The loader runs as the admin with `Bypass_Automation`
(custom permission via `PS_Bypass_Load`) granted beforehand: flows skip via
`Automation_Settings__c.Bypass_Flows__c`, triggers skip via `Bypass_Triggers__c`, VRs
skip via the `NOT($Permission.Bypass_Automation)` guard (data model §9). Bypass is
**revoked immediately after the load** and its state logged in
`metadata-log/README.md`. Never edit a validation rule to load.

---

## 5. VIN generation (ISO 3779)

For each of the 120 vehicles:

1. **WMI** (positions 1–3): `NGD` (invented, non-reserved — real WMIs never used).
2. **VDS** (positions 4–9): deterministic pseudo-random from the seeded PRNG, charset
   `A-H J-N P R-Z 0-9` (excludes I, O, Q).
3. **Check digit** (position 9): ISO 3779 transliteration, weights
   `8,7,6,5,4,3,2,10,0,9,8,7,6,5,4,3,2`, modulo 11, `X` for 10.
4. **VIS** (positions 10–17): model-year code (§6), plant `A` + sequence.

`VIN__c` is a **Unique field** — duplicate prevention is zero-query, no VR needed.
Check-digit validity is computed in Apex (`VinValidator`, data model §5.6) into
`Is_VIN_Valid__c`; the VR `VR_Vehicle_VIN17` checks only length/charset (formula size
limits rule out a mod-11 formula).

Fixture file `data/fixtures/invalid_vins.json` holds 10 malformed VINs (16 chars,
contains `I`/`O`, bad check digit) — used only by validation tests, never loaded into
inventory. Six variants of these live in `Trade_In__c.Trade_VIN__c` (free text) as part
of `SEED-98` (§7.1).

---

## 6. Model-year code table

| Years | VIS position 10 code |
|---|---|
| 2010 A, 2011 B, 2012 C, 2013 D, 2014 E, 2015 F, 2016 G, 2017 H, 2018 J, 2019 K, 2020 L, 2021 M, 2022 N, 2023 P, 2024 R, 2025 S, 2026 T, 2027 V | as listed |

(ISO 3779 omits I, O, Q, U, Z; 30-year cycle.)

---

## 7. Deliberately bad data — two batches

### 7.1 `SEED-99` — business-bad (schema-valid, counts inside the envelope)

Loaded last, separably resettable. Every scenario survives the storage budget:

| ID | Scenario | Count | Inside | Demo purpose |
|---|---|---|---|---|
| BAD-01 | Duplicate households (same surname, street, different account) | 8 pairs | Account/Contact | Duplicate rules |
| BAD-02 | Stale open leads (no activity > 60 days) | 35 | Lead | Lead velocity, SLA |
| BAD-03 | Opened-and-ignored cases (no comment in 14 days) | 8 | Case | Case-aging report |
| BAD-04 | Overdue service visits (past, still `Scheduled`) | 12 | `Service_Visit__c` | SLA breach dashboard |
| BAD-05 | Negative-equity trade-ins (appraisal < payoff) | 8 | `Trade_In__c` | Finance edge case |
| BAD-06 | Aged inventory > 120 days | 12 | `Vehicle__c` | Floor-plan cost report |
| BAD-07 | Revoked-consent contacts still on a campaign | 6 | `Consent__c`/CampaignMember | Privacy guard demo |
| BAD-08 | Opportunity stuck in `Quoting` > 45 days | 6 | Opportunity | Pipeline hygiene |
| BAD-09 | Quotes with >1 stacked discount rule | 4 | Quote | CPQ guard (`Max_Applies__c`) |
| BAD-10 | Test drive `No_Show` with no follow-up task | 6 | `Test_Drive__c`/Task | Process-gap flow |

### 7.2 `SEED-98` — legacy import (schema-invalid, 30 records, bypass on)

Models the "someone imported an old spreadsheet" mess that every DQ dashboard needs.
Loaded with bypass granted, then revoked. **These 30 records are the only
schema-invalid rows ever loaded** (30 × 2 KB = 60 KB, inside §2.1).

| Defect | Count | Object | Why it must bypass |
|---|---|---|---|
| Malformed phone (`416-5550`, `n/a`, missing) | 10 | Contact | Phone format VR/normalisation |
| Missing postal code | 8 | Contact (address) | Required-address expectation |
| Invalid VIN in `Trade_VIN__c` (16 chars, contains `O`) | 6 | `Trade_In__c` | Free-text field, but DQ report targets it |
| Mixed-case duplicate emails (`Dana@test` vs `dana@test`) | 6 | Contact | Duplicate rule |

`SEED-98` is documented in `docs/DATA_QUALITY.md` as an intentional fixture with its
tag range, so nobody "fixes" it by deleting it.

### 7.3 DQ report split

| Report class | Rule | Examples |
|---|---|---|
| **Release gates (must be 0)** | Asserted by `scripts/verify.sh` before any demo | §9a list |
| **Demo findings (expected > 0)** | Carries the expected count in its filter; drift is the alarm | §9b list |

Schema-invalid rows outside `SEED-98` (bad VINs, negative prices, missing required
fields) are **never** loaded — test fixtures only, asserting the VRs catch them.

---

## 8. Refresh and reset

| Mode | What | When |
|---|---|---|
| **Full reset** | Delete all rows `Seed_Tag__c LIKE 'SEED-%'`, child-first → **purge Recycle Bin** → reload all batches | Between demo campaigns |
| **Batch reset** | Delete only `SEED-99-%`, `SEED-98-%`, or one object's range | Before a specific presentation |
| **Surgical replace** | Delete + reload one object (e.g. all `Vehicle__c`) | Fresh inventory scenario |
| **Burst teardown** | Delete `SEED-77-%` → purge Recycle Bin | Immediately after volume screenshots |
| **No touch** | Users, roles, PS/PSG, queues, reports, dashboards, templates, custom metadata, custom settings, record types, sharing rules, `Staff__c` (unless re-seeded deliberately) | Never reset |

Process:

1. Grant bypass (`PS_Bypass_Load` → `Bypass_Automation`) to the loader admin.
2. `scripts/reset.sh <scope>` → `sf data delete bulk` filtered by seed tag, child-first.
3. **Empty the Recycle Bin** (hard delete) — deleted rows otherwise linger 15 days and
   keep counting toward the 5 MB.
4. Loader re-runs affected batches in §4 order (upsert = idempotent).
5. **Revoke bypass.**
6. `Data_Load_Batch__c` rows updated (`Reset_At__c`, `Status__c`).
7. `scripts/verify.sh` runs §9 gates and prints PASS/FAIL.
8. **Storage Usage check** (Setup → Storage Usage or `/limits` REST resource): must read
   ≤ 4.0 MB after a full reset, ≤ 4.6 MB during a burst. Record the number in
   `data/SEED_VERSION.txt`.
9. Append line to `data/SEED_VERSION.txt` (includes `ANCHOR_DATE` used).

Rollback = "reset to last known good `SEED_VERSION.txt` entry" — the same procedure;
reset is delete-then-reload, never in-place mutation.

---

## 9. Data quality gates

### 9a. Release gates — must return 0 (automated in `scripts/verify.sh`)

| # | Check |
|---|---|
| 1 | 0 vehicles where `Is_VIN_Valid__c = false` |
| 2 | 0 duplicate `VIN__c` (Unique field is the primary guard) |
| 3 | 0 opportunities with `Amount ≤ 0` past `Prospecting` |
| 4 | 0 `Closed Won` opportunities where `Delivery_Completed__c = false` |
| 5 | 0 `Financing__c` with `Annual_Rate__c` outside 0–25 or term outside {36,48,60,72,84,96} |
| 6 | 0 loyalty members with `Points_Balance__c < 0` |
| 7 | 0 `Completed` service visits with `Total_Cost__c = 0` |
| 8 | 0 rows in seeded objects missing `Seed_Tag__c` |
| 9 | Every `Data_Load_Batch__c` row `Status__c ∈ {Loaded, Partial}` with matching counts |
| 10 | Record counts match §2.1 exactly (±0; activities ±2) |
| 11 | 0 leads/contacts with an email outside `*.test` domains |
| 12 | 0 consent rows `Revoked` without `Revoked_On__c` |
| 13 | Storage Usage ≤ 4.0 MB after full reset |
| 14 | 0 records in `SEED-98-*` outside the 30-record legacy batch |

### 9b. Demo findings — expected > 0 (drift is the alarm)

| # | Check | Expected |
|---|---|---|
| 15 | Stale open leads > 60 days (BAD-02) | 35 |
| 16 | Cases ignored > 14 days (BAD-03) | 8 |
| 17 | Overdue service visits (BAD-04) | 12 |
| 18 | Aged inventory > 120 days (BAD-06) | 12 |
| 19 | Revoked-consent-on-campaign contacts (BAD-07) | 6 |
| 20 | Opportunities stalled in `Quoting` > 45 days (BAD-08) | 6 |
| 21 | `SEED-98` defect rows by type (phones 10 / postal 8 / VIN 6 / emails 6) | 30 total |
| 22 | Duplicate-rule hits on BAD-01 households | 8 |

Gates 1–14 gate every demo; 15–22 are asserted at expected counts so accidental deletion
of the bad fixtures is caught too. Report smoke test: all reports in
`docs/REPORTS.md` return rows except the documented empty exceptions.

---

## 10. File layout

```
data/
├── SEED_VERSION.txt            ← SEED_VERSION, ANCHOR_DATE=YYYY-MM-DD, storage reading
├── README.md                   ← how to generate, load, reset
├── csv/                        ← one CSV per object (the upsert artifacts, committed)
│   ├── 01-rooftops.csv
│   ├── 02-models.csv
│   ├── 03-products.csv
│   ├── 04-staff.csv
│   ├── 05-vehicles.csv
│   ├── 06-accounts.csv
│   ├── 07-contacts.csv
│   ├── 08-leads.csv
│   ├── 09-opportunities.csv
│   ├── 10-opptylineitems.csv
│   ├── 11-quotes.csv
│   ├── 12-tradeins.csv
│   ├── 13-financing.csv
│   ├── 14-deliveries.csv
│   ├── 15-testdrives.csv
│   ├── 16-cases.csv
│   ├── 17-servicevisits.csv
│   ├── 18-campaigns.csv
│   ├── 19-loyaltymembers.csv
│   ├── 20-loyaltytxns.csv
│   ├── 21-consents.csv
│   ├── 22-activities.csv
│   ├── 77-burst.csv            ← disposable (§2.7)
│   ├── 98-legacy.csv           ← SEED-98, loaded with bypass (§7.2)
│   └── 99-bad-data.csv         ← SEED-99 (§7.1)
├── scripts/
│   ├── generate.ts             ← deterministic PRNG → all CSVs (Node 22, TypeScript)
│   ├── load.ts                 ← §4 order: upsert bulk per object, relationship columns, bypass handling
│   ├── verify.ts               ← §9 gates (called by scripts/verify.sh)
│   └── tests/
│       ├── vin.test.ts         ← check-digit correctness
│       ├── determinism.test.ts ← same seed + ANCHOR_DATE → byte-identical output
│       └── counts.test.ts      ← volumes match §2.1
├── fixtures/
│   ├── invalid_vins.json       ← test-only, never loaded
│   └── names.ts                ← fictional name lists
└── snapshots/                  ← pre-reset exports (gitignored)
```

CSVs are checked in (they are the artifact the demo depends on); regeneration with the
same `ANCHOR_DATE` produces no diff.

---

## 11. Privacy and safety statement

- No real person's name, email, phone, or address appears anywhere.
- No real VIN, no real WMI, no real licence plate.
- No data sourced from any external dataset — 100% generated.
- No production customer data is ever imported, even if a real org becomes available later.
- Email domains are reserved `.test`/`.example` so seeded mailings can never deliver.
- Internal usernames use real plus-addressed inbox addresses (activation requires
  deliverable email); seed Contacts/Leads use `.test` domains only (master plan §3.5,
  checklist 0-C).

---

## 12. Acceptance criteria for this document's execution

When (and only when) the owner approves the plan:

1. `npm run data:generate` produces all CSVs for the stored `ANCHOR_DATE`.
2. `npm run data:test` passes — VIN validity, determinism, counts vs §2.1.
3. Load completes with zero errors via `sf data upsert bulk` in §4 order; bypass revoked
   afterwards and logged.
4. **Re-running the load produces identical counts** (idempotency proof — upsert, not
   insert).
5. `npm run data:verify` passes all §9a gates and asserts all §9b expected counts.
6. Storage Usage reads ≤ 4.0 MB after a full reset; burst protocol (§2.7) returns to it.
7. Full reset + reload reproduces byte-identical CSVs and identical record counts;
   `SEED_VERSION.txt` and `Data_Load_Batch__c` updated.
