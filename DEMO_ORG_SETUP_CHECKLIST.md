# Setup Checklist — Northgate Motors Demo Org

**Status:** PLANNING ONLY. Phase 0 items are checkable the moment the owner approves them.
Items marked **[VERIFY]** are never assumed — they are measured in the org before any build
decision depends on them.

Companions: `DEMO_ORG_MASTER_PLAN.md` (§3.5–§3.6 keep-alive/rebuild, §4 ledger, §7 releases),
`DEMO_ORG_BACKLOG.md` (P0), `DEMO_ORG_DATA_MODEL.md` (§11 decisions log).

**Guardrails that apply to every box below:** no scratch orgs · no profile edits beyond the
**narrow seamless-UX exception** (profiles hold only default app + tab visibility — DATA_MODEL
§6.5) · no deleting users · no external writes · every Setup change logged in `metadata-log/` ·
**no-workaround rule** (anything not deployable from source = click-by-click steps for the
owner → "done" → read-only verify → log; master plan §3.2-7).

**Phase 0 scope rule (v2):** Phase 0 creates **no metadata** — no users, roles, permission
sets, queues, groups, record types, picklists, layouts, validation rules or sharing settings.
Those deploy from source in P1 (anything un-deployable is clicked once and logged in
`metadata-log/`). Phase 0 = acquisition, org settings, keep-alive, licence verification,
the verify matrix, and repo/CI bootstrap.

---

## Phase 0-A — Org acquisition (two orgs)

- [ ] Sign up **two** Developer Edition orgs ("with Agentforce and Data Cloud" edition):
      `ng-dev` (build/UAT) and `ng-demo` (stable demos). Dedicated demo email aliases; real
      deliverable mailboxes behind them (activation requires email).
- [ ] Save credentials for both orgs in the password manager — **never in the repo**.
- [ ] Confirm each is a real DE org, not scratch: `sf org display --json` shows the real
      login URL, not `test.salesforce.com`.
- [ ] Create `sf` aliases: `ng-dev`, `ng-demo` (plus default project alias).
- [ ] Record both orgs in `metadata-log/ORG_INFO.md`: org ID, My Domain, edition, login URL,
      **signup date and expiry policy** (see 0-C), keep-alive owner.
- [ ] **Expiry facts to record** (Salesforce Help, checked 2026-10-07): this edition is
      deleted after **45 days without a login**; warning emails days 1–14; Support can
      reactivate days 15–44. **No Connected-App exemption is available (v2.1):** since
      Spring '26 new orgs cannot create Connected Apps (UI or Metadata API) without
      Salesforce Support, and DE orgs have no standard Support — hence 0-C is human login,
      not a Connected App.

## Phase 0-B — Org settings (safe, one-way doors flagged)

For **each** org (`ng-dev`, `ng-demo`):

- [ ] **My Domain** (`NorthgateMotors-Dev` / `NorthgateMotors-Demo` + suffix if taken) —
      required for flow URL redirects, login branding and JWT login.
- [ ] My Domain login page branding (logo + colour only — no third-party assets).
- [ ] **[VERIFY] Currency.** `Setup → Company Information → Currency`.
      - Single-currency org → set default **CAD** (recommended path, DATA_MODEL §11-2).
      - Multi-currency present (cannot be disabled) → record it, CAD default, resolve
        DATA_MODEL §11-2 as "multi-currency by reality"; do not pretend single-currency.
- [ ] **[VERIFY] Locale.** Language `English (Canada)`, date format, time zone
      `America/Toronto`, Canadian number conventions.
- [ ] **[VERIFY] Fiscal year.** Calendar year (Jan–Dec) so dashboard trends are clean.
- [ ] **[VERIFY] Business hours** — `Mon–Fri 08:00–18:00 America/Toronto` for case-age math.
- [ ] **Email deliverability = "System email only"** (the default for new orgs — do **not**
      set "No Email"). Internal users get real plus-addressed emails (activation requires
      them); seed Contacts/Leads use `.test` domains so seeded mailings never deliver.
      For the scheduled email test (P0/P2), switch to "All email" briefly, run the test,
      switch back. Log every change in `metadata-log/README.md`.
- [ ] **[VERIFY] API version pin.** Confirm the SFDX project's `sourceApiVersion`; record in
      MASTER_PLAN §7.

## Phase 0-C — Keep-alive (both orgs) — **no Connected App**

**v2.1:** the Connected-App expiry exemption is unavailable (see 0-A). Keep-alive is a
human login cadence; CI auth comes later as an External Client App (P1-22).

- [ ] **Human UI login to `ng-dev` and `ng-demo` at least every 30 days** — add both orgs
      to the owner's calendar as a recurring **30-day login reminder** (two logins per
      cycle).
- [ ] Start the **login log** in `metadata-log/ORG_INFO.md`: table of date · org · who ·
      why for every keep-alive login. First entry = the Phase 0 verification login.
- [ ] Record the standing rule in `ORG_INFO.md`: **do not assume CI/API logins reset the
      inactivity timer** — only an interactive human UI login counts until Salesforce
      documents otherwise.
- [ ] Enable **login audit** dates so logins are provable.
- [ ] Reference the **Org rebuild runbook** (MASTER_PLAN §3.6) in `ORG_INFO.md` with its
      4-hour rebuild target.
- [ ] **No Connected App is created in Phase 0** — it would fail anyway (0-A); the CI
      External Client App + JWT is backlog **P1-22**, planned, not clicked, in Phase 0.

## Phase 0-D — Licence count and persona matrix (verify + document, create nothing)

- [ ] **[VERIFY] Licence inventory.** Stop B `UserLicense` query measured **4 Salesforce
      licences (2 used, 2 free) and 6 Platform licences** per org; record Integration and
      External Identity counts (expect ≈1 / ≈5) — **measure, never assume.**
- [ ] Write `docs/security/PERMISSION_MATRIX.md` for the **7-account persona model
      (licence-corrected)** — **Login As does not lift licence limits**; Platform users
      cannot use Opportunity, Lead, Case, Quote or Campaign regardless of PSG:
      - **Salesforce #1** — Admin (`ngadmin`);
      - **Salesforce #2** — **Sales Rep** (`ngrep`, real login: lead → opportunity → quote);
      - **Salesforce #3** — **Service Advisor** (`ngsvc`, real login: Case, Service Visits);
      - **Salesforce #4** — **Persona Switcher** (`ngpersona`): role + PSG swapped by
        `scripts/persona.sh <manager|finance>` for Sales Manager and Finance demos;
      - **Platform #1** — Inventory Coordinator (`nginv`): `Vehicle__c`,
        `Vehicle_Model__c`, `Rooftop__c`, `Staff__c`;
      - **Platform #2** — Service Technician (`ngtech`): `Service_Visit__c`,
        `Vehicle__c`, Account/Contact read;
      - **Integration** — `dms.integration` (no interactive login);
      - the `Staff__c` roster mapping (14 fictional staff → 6 logins + "no login");
      - the role-hierarchy tree with roles marked *fixed user* / *persona-switcher* /
        *empty*;
      - which demo scripts need which persona (every script starts "activate persona X").
- [ ] Decision gate: if free licences < the plan's new accounts, **shrink coverage, not
      the licence rule** (Sales Rep or Service Advisor folds into Persona Switcher
      coverage) — **never exceed the licence count.**
- [ ] No users, roles or permission sets are created in Phase 0 — P1 creates them from
      source (checklist 1-A).

## Phase 0-E — Feature verification matrix (VERIFY before you build)

Each row: measure in-org, then update the buildability bucket in MASTER_PLAN §4 and append
to `docs/VERIFY_RESULTS.md` with the date. Never assume.

| # | Feature | How to verify | If present | If absent |
|---|---|---|---|---|
| 1 | Person Accounts | Setup search "Person Accounts" | **Do not enable** (one-way) — `Account.Type = Household` | Build Household as planned |
| 2 | Multi-currency | Setup → Company Information | See 0-B | Single CAD build |
| 3 | Duplicate rules on Contact/Account | Setup → Duplicate Rules | Use native matching rules | Build `DR_Contact_Email` / `DR_Account_NamePostcode` (P1) |
| 4 | Sales Cloud Einstein / Lead Scoring | Setup → Einstein | Record in ledger §4 | Not built; no invented score field |
| 5 | Field Service (`ServiceAppointment`) | Setup → Field Service | **Still prefer custom** `Service_Visit__c` — standard collision risk | Custom `Service_Visit__c` as planned |
| 6 | Omni-Channel | Setup → Omni-Channel | Small P6 add-on if truly free | Flow-based assignment (planned) |
| 7 | Knowledge | Setup → Knowledge | **Plan to build** — ~10 articles in P6 (standard in this edition) | Case templates as documents |
| 8 | Entitlements + Milestones | Setup → Entitlements | **Plan to build** in P6 (SLA skill) | Flow-based SLA stamps (fallback) |
| 9 | Service Console app | Setup → App Manager | Use for service persona demo | Custom app only |
| 10 | Experience Cloud + External Identity licences | Setup → Digital Experiences + licence count | **Small real site** in P7 (1–2 External Identity users) | Simulation only (documented) |
| 11 | **Agentforce** (service agent, Prompt Builder) | Setup → Agentforce; attempt agent creation | **Small real build** in P7 (≈150 LLM req/hr) | Simulated triage fallback, labelled |
| 12 | **Data Cloud** (10 GB, 1 data space, manual refresh) | Setup → Data Cloud | **Small real build** in P7 (ingest + identity resolution) | Ledger note only |
| 13 | Dynamic dashboards (limit = 3 — **confirmed in Salesforce Help**, DATA_MODEL §11 #8) | Create 1 dynamic dashboard, count remaining | Mark exactly **3 dynamic** (P2-11, P5-14, P6-09); rest fixed-user | Fixed-user dashboards only |
| 14 | Enterprise Territory Management | Setup search | Optional sharing demo | Sharing rules only |
| 15 | Standard Quote/CPQ | Setup → Sales → Quotes | Standard Quote (as planned) | Quote simulation fallback |
| 16 | Web-to-Lead | Setup → Web-to-Lead | Lead intake demo | Flow file-upload intake |
| 17 | Change Data Capture availability | `sf data` / setup search | Ledger note (bonus) | Ignore |
| 18 | Sandbox types on DE | `sf org list` / Setup → Sandboxes | Use for preview if present | **Never a scratch org** — `ng-demo` itself is the preview target |
| 19 | Report/folder limits | Create 1 folder per type, observe cap | Stay under cap | Consolidate folders |
| 20 | Deployment status / packaging limits | Setup → Deployment Status | Note for release strategy | Unlocked package still preferred |
| 21 | Static resource / file storage limit | `sf org list limits` → `FileStorageMB`; record cap + headroom **before** `NG_VehicleImages` (~30 × ~50 KB webp) is committed | Headroom recorded → `docs/VERIFY_RESULTS.md` | Shrink images or defer gallery (P7-01/22) |

## Phase 0-F — Repo and CI bootstrap (local + GitHub, no org metadata)

- [ ] `metadata-log/README.md` created — log format: date, change, reason, ticket/phase.
- [ ] `metadata-log/ORG_INFO.md` created (filled by 0-A/0-C; login log table present).
- [ ] `docs/VERIFY_RESULTS.md`, `docs/security/PERMISSION_MATRIX.md`,
      `docs/TECH_DEBT.md` (pre-seeded with DATA_MODEL §5.5 slot-conflict limitation)
      scaffolded.
- [ ] `.forceignore`, `sfdx-project.json` (`sourceApiVersion` = latest GA API version
      supported by the installed `sf` CLI), `config/` present and consistent.
- [ ] **Git: `git init` in the project folder** (owner approved). `.gitignore` excludes
      `.sf/`, `.sfdx/`, `node_modules/`, `data/snapshots/`, `*.log`, `.env`, `*.key`,
      `**/secrets/**`.
- [ ] **No secrets anywhere.** Grep for `password`, `token`, `client_secret`,
      `securityToken` before the first commit.
- [ ] **Private GitHub repository `arjun2126/northgate-motors-demo` created by the OWNER
      with `gh`** (never by an agent, never with an agent-handled token); remote added by
      the build agent; first commit pushed by the build agent.
- [ ] **GitHub Actions `validate.yml` skeleton committed disabled** (auth commented out,
      `workflow_dispatch` only): PR/push → `sf project deploy start --dry-run
      --test-level RunLocalTests` vs `ng-dev`. Enabled in P1 once P1-22 External Client
      App credentials exist. **No scheduled login job** — CI logins are not assumed to
      reset the expiry timer (0-C).
- [ ] `scripts/verify.sh` stub exists and prints "not yet implemented" until P4.
- [ ] `sf org list` shows **both** orgs with aliases `ng-dev`, `ng-demo`.

---

## Phase 0 execution runbook for the build agent

Instructions for the executing agent. **Do not improvise beyond this runbook.** Three stop
points; work resumes only after the owner confirms each stop.

**Standing rules (apply at every stop):**

1. Touch **only** `ng-dev` and `ng-demo`. **Never** `portfolio-demo-2026` or any other org
   alias that appears in `sf org list`.
2. Never modify `~/Documents/Coding Projects/DEMO ORG ARJUN/` or
   `~/Documents/JobSearch/` — those folders are outside this project entirely.
3. Phase 0 creates **no metadata, no data, no users**. No `project deploy start` of any
   kind (dry-run or real), no data import, no user creation.
4. **No-workaround rule (master plan §3.2-7):** anything you cannot deploy from source you
   do not work around — write exact click-by-click Setup steps for the owner, **wait for
   the owner's "done"**, then verify the result read-only and log it in
   `metadata-log/README.md`.
5. Only the five `.md` planning files and the Stop-A scaffold files may be written before
   approval; no Phase 1 work without explicit owner approval of the Phase 0 exit report.

### Stop A — Local bootstrap (no org access yet)

Build agent runs, in the project folder:

1. `git init`
2. `.gitignore` with exactly: `.sf/`, `.sfdx/`, `node_modules/`, `data/snapshots/`,
   `*.log`, `.env`, `*.key`, `**/secrets/**`
3. `sfdx-project.json` with `sourceApiVersion` = the latest GA API version supported by
   the installed `sf` CLI (check `sf --version` release notes / help output — record the
   version chosen)
4. `.forceignore` (standard force-app defaults)
5. Folder tree from MASTER_PLAN §6.1 (empty dirs get a `.gitkeep`)
6. Template files: `metadata-log/README.md` (log format + login-log table),
   `metadata-log/ORG_INFO.md` (org fields blank), `docs/VERIFY_RESULTS.md` (0-E matrix
   header)
7. `.github/workflows/validate.yml` skeleton **disabled**: valid YAML, auth steps
   commented out, `workflow_dispatch` only
8. Secret grep: `password|token|client_secret|securityToken` over all tracked files →
   `evidence/P0/secret_grep.txt`
9. First commit

**Stop A report → owner.** Then the **owner** runs (build agent must not):

```bash
gh auth status
gh repo create arjun2126/northgate-motors-demo --private
git remote add origin git@github.com:arjun2126/northgate-motors-demo.git
git push -u origin main
```

### Stop B — Org connection (owner signs up, agent connects read-only)

1. **Owner:** signs up `ng-dev` and `ng-demo` (0-A), sets My Domain (0-B first box), saves
   credentials in the password manager. **Owner enters all credentials** at the browser
   prompts.
2. **Build agent:** `sf org login web --alias ng-dev` then
   `sf org login web --alias ng-demo` (owner present at the prompt).
3. **Build agent:** read-only checks, **both orgs**, results appended to
   `docs/VERIFY_RESULTS.md`:

```bash
sf org display --verbose --target-org ng-dev          # confirm real org, not scratch; record ApiVersion
sf data query --target-org ng-dev --result-format csv \
  --query "SELECT OrganizationType, IsSandbox, DefaultLocaleSidKey, TimeZoneSidKey, LanguageLocaleKey FROM Organization"
sf data query --target-org ng-dev --result-format csv \
  --query "SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense"
sf data query --target-org ng-dev --result-format csv \
  --query "SELECT MasterLabel, TotalLicenses, UsedLicenses FROM PermissionSetLicense"
sf org list limits --target-org ng-dev                # record DataStorageMB, FileStorageMB, DailyApiRequests
sf sobject list --target-org ng-dev                   # check for: Quote, Entitlement, Knowledge__kav, ServiceAppointment, Territory2, UserServicePresence
```

4. **Owner:** signs off the Stop B report (licence counts feed 0-D; storage numbers feed
   the data plan §2 envelope).

### Stop C — Settings, re-verification, Phase 0 exit

1. **Owner:** Setup click-list in **both** orgs (0-B): locale `en_CA` (`English (Canada)`),
   time zone `America/Toronto`, currency **CAD**, calendar fiscal year, business hours
   `Mon–Fri 08:00–18:00`, email deliverability **"System email only"**.
2. **Build agent:** re-run the `SELECT … FROM Organization` query (Stop B) in both orgs and
   confirm the locale/time-zone fields match the click-list.
3. **Build agent:** log each setting as an entry in `metadata-log/README.md`
   (date · org · change · reason).
4. **Build agent:** write the **Phase 0 exit report** (0-E matrix, storage baseline,
   licence counts, keep-alive setup) and submit it to the owner.

**Phase 0 ends here. Phase 1 starts only after the owner approves the exit report.**

---

## Phase 0 exit criteria (the approval gate)

Phase 0 is done when **all** of the following are true:

1. Two real (non-scratch) DE orgs exist with aliases `ng-dev`/`ng-demo`; credentials stored
   safely; expiry policy + 45-day rule + **Spring '26 no-Connected-App restriction**
   recorded in `ORG_INFO.md`.
2. Org settings (My Domain, locale, currency, fiscal year, business hours) set and
   recorded; deliverability "System email only"; Stop C Organization re-query matches.
3. Keep-alive protocol active: 30-day login reminder scheduled, login log started in
   `ORG_INFO.md`, CI auth deferred to P1-22 (External Client App, planned not clicked),
   rebuild runbook (§3.6) referenced.
4. Licence counts measured (Stop B: 4 Salesforce [2 used, 2 free] + 6 Platform);
   `PERMISSION_MATRIX.md` written for the 7-account persona model (Admin, Sales Rep,
   Service Advisor, Persona Switcher, Inventory Coordinator, Service Technician,
   `dms.integration`) — **no users created yet**.
5. §0-E verification matrix fully answered with evidence; MASTER_PLAN §4 buckets updated
   (including Agentforce/Data Cloud/Knowledge/Entitlements/Experience/dynamic-dashboard
   rows).
6. Git repo initialised, private GitHub remote **`arjun2126/northgate-motors-demo`**
   created by the owner with `gh`, CI skeleton committed but **disabled**, no secrets in
   any file (secret grep output attached).
7. `metadata-log/` and `docs/` scaffolding in place; every Phase 0 change logged; Phase 0
   exit report submitted.

**Only after the owner confirms Phase 0 exit criteria does Phase 1 begin (P1 creates users,
roles, PS/PSG, record types, picklists, stages, layouts, VRs, sharing settings — deployed
from source, P1-01..P1-22).**

---

## Quick-reference: what Phase 0 must NOT do

| Never | Why |
|---|---|
| Create a scratch org | Hard constraint from owner |
| Touch any org other than `ng-dev`/`ng-demo` (e.g. `portfolio-demo-2026`) | Only these two orgs belong to this project |
| Modify `DEMO ORG ARJUN` or `JobSearch` folders | Out of scope; five `.md` files + scaffold only |
| Create users, roles, permission sets, queues, groups | Phase 0 creates no identity metadata — P1 deploys from source (M9) |
| Create record types, picklists, layouts, apps, tabs, VRs, OWD changes | Same: P1 from source; anything click-only goes through `metadata-log/` in P1 |
| Create a Connected App in Phase 0 | Spring '26 restriction (0-A); CI External Client App is P1-22 |
| Edit a profile for access (object/FLS/record types), or clone a profile | Permission sets only — profiles drift across a permanent org. **Exception:** the four `NG_*` profiles hold only default app + tab visibility (DATA_MODEL §6.5) |
| Enable Person Accounts | One-way door |
| Set email deliverability to "No Email" or a sending state | Default is "System email only"; activation needs system email; tests toggle briefly then back |
| Import any real person's data | Privacy rule |
| Delete users | Historical records orphan; disable instead |
| Push metadata before `metadata-log/` exists | Audit trail first |
| Deploy validation rules "disabled" | v2: VRs are always active; bypass is the custom permission + custom setting (DATA_MODEL §9) |
| Assume a feature is available | §0-E verify-first rule |
| Assume CI/API logins reset the expiry timer | Only human UI login counts (0-C) |
| Exceed the measured licence count | DE licences are hard limits; Login As does not lift them (0-D) |
