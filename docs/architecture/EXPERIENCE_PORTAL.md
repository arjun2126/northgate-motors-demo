# Experience Portal — Phase 8 architecture, licensing and security

**Current deployed seam (§71):** exact broker/ledger/prerequisite package deployed via Quick
Deploy `0Afaj00000pPottCAC` (34/34, zero errors), reusing 43/43 tests. P8-05/07 now deployed;
existing history/Case/loyalty and native capacity/intake retained. Current-caller broker checks
replace native Vehicle permissions; customer Vehicle/Model/ledger CRUD and Visit Create stay
denied. No scheduler activated. Users/assignments/memberships/shares/business fingerprints/pages/
navigation and existing permission rows preserved. New ledger empty/reviewer unassigned/site
UnderConstruction/never activated. No actual-customer/browser/AT/M4 acceptance. Evidence and
shortest separately approved operational sequence: `evidence/P8/BROKER_DEPLOYMENT/RESULT.md`.

**Current broker amendment (§70):** owner-approved server-mediated Vehicle/booking capability
implemented locally and validated `0Afaj00000pPiV7CAK` (34 components, 43/43 tests); UI tests
25/25. P8-05 list/details/stock photos and P8-07 eligible reviewed/idempotent requests reuse the
existing capacity/intake path. All public requests still resolve Foundation's real Live site and
exact customer identity. The minimal broker's privileged DTO/write path is the approved exception
to USER_MODE Vehicle reads/booking DML; native Vehicle/Model/ledger CRUD and Visit Create stay
denied. No generic reader/writer/share grant. Existing history/Case/loyalty USER_MODE paths and
validated ledger source retained. Source not deployed, actual-customer UAT not passed. Current
scope and native/custom seam: `evidence/P8/BROKER_COMPLETION/RESULT.md`.

**Current operational preparation (2026-10-27, handoff §66):** foundation, Batch B and Batch C
are deployed. Batch C `0Afaj00000pOUsQCAW` succeeded 6/6; all six bundles available and local hashes
still match validation. Live guest object/custom Apex grants zero; hardened profile restrictions
intact/unassigned; Plus licenses 5 total/0 used. Network remains UnderConstruction/never activated.
No meaningful site regression was demonstrated by the prior focused export check; not reopened.
Connected Builder visual inventory and trusted-browser route check remain tool-blocked, not passed.
Only Home is Builder-exposed; five children compose one page. No new source/deployment/test rerun.
Ownership proposal: `P8_CONTACT_VEHICLE_OWNERSHIP.md` (not implemented/approved), including separate
service authority and mandatory native-access revocation proof. Actual customer/native-write/sharing/
browser UAT not passed. Current register: `../planning/P8_OPERATIONAL_COMPLETION_REGISTER.md`.
This supersedes local-only/unhardened/unprovisioned-site assumptions in historical sections below;
it does not supersede their actual security requirements or infer ownership/data rights.

**Historical release state (§64):** exact ten-component Batch B Quick Deploy
`0Afaj00000pIP10CAG` Succeeded. Both email-management flags are now false; prior 33 object/483
field/23 system denies remain effective, base Case Create/Edit is off, profile unassigned. Native
site is UnderConstruction/never activated; no customer users/memberships/shares added. Batch C
six-bundle UI polish is LOCAL/check-only (`0Afaj00000pJzGvCAK`, 6/6, 0 errors, 0 Apex tests),
not deployed or placed on a site page. UAT preparation exists but actual customer acceptance
has not run. This supersedes the older planning/disabled/unhardened-state statements below.

## Actual native versus custom versus blocked — current seam

| Surface | Real implementation | Actual boundary / evidence |
|---|---|---|
| Site/login | Salesforce Customer Service (Aura) scaffold on existing Experience domain | Native site exists, unpublished. No ownerPortalHome page placement or actual customer login demonstrated |
| Customer identity | Custom with-sharing foundation resolves real caller type/license/permission, self Contact/Account and exact Live Network | USER_MODE own customer reads; SYSTEM_MODE only self identity/site metadata. Private test-injected site facts are not live-site proof |
| Dashboard/history | Custom Apex/LWC, scoped to the caller's Contact; native Case/Service_Visit records | Eligible-empty/error states honest; no broad inventory or financial data. No admin/persona-switch substitute for external UAT |
| Cases/comments | Native Case/CaseComment with custom Contact guards, USER_MODE DML and existing Service queue/type | No Case Edit needed in scoped tests; only published own comments shown. Queue-owned Case visibility still requires reviewed actual sharing |
| Loyalty | Native custom member/ledger records through read-only filtered Apex and LWC | Stored balance/tier only, no accrual/redemption/reconciliation activation or financial fields |
| Vehicles/photos | Explicit ownership-unconfigured state | No owned list/detail/photo acceptance; reservations/old Deliveries do not establish ownership; no external inventory grant |
| Appointment creation | Explicit no-write guard/disabled eligibility step | Required Vehicle relationship and approved ownership missing. Existing ServiceVisitTrigger capacity/intake remains unchanged, not a replacement engine |
| Batch C UI | Deployed responsive native lists/table, own-text branding, focus/form semantics and documentation | Prior 19 local state/source/contrast tests pass; not DOM, screen-reader, responsive screenshot or real-persona evidence |

No React, new Flow or labelled simulation fallback was implemented. Mocked Apex bindings in Node
tests and rolled-back Apex fixtures are test infrastructure only, not a customer-facing simulation.
External Community Plus users are role-capable; the historical blanket roleless statement below
does not describe this selected model. Relationship filters, actual license rights, CRUD/FLS and
record visibility are all required. Apex filtering never licenses system-mode customer reads.
The proposed ownership ledger is not implemented and grants no access. Read-only customer endpoints
remain intact. Before assigning write-capable grants, prove direct native/UI API mutation guards
and native sharing/revocation as well as portal Contact predicates; ApiEnabled=false alone is not
that proof. Do not silently use the Batch B Case-Create set as a read-only pilot capability.

Current acceptance preparation: `evidence/DEMO_SCRIPTS/portal.md`,
`evidence/P8/uat/PORTAL_UAT_MATRIX.md` and `docs/planning/P8_BATCH_C_ACCEPTANCE_EXCEPTIONS.md`.
Real A/B provisioning/access, owner-approved ownership, page placement, controlled publication
and actual-customer positive/negative UAT remain unresolved. Do not claim M4 or Batch C accepted.

**Current authorization/state (2026-10-26, handoff §60):** five-component P8 foundation deployed
by exact Quick Deploy `0Afaj00000pGvwECAS`. Site exists unpublished/UnderConstruction; no external
users/customer memberships/shares added. Live profile hardening is REFUTED (default Case Edit and
other grants remain), so no provisioning using it. Batch B local-only implementation is authorized
and started, with no Batch B deployment. Vehicles/appointments require an approved ownership
contract; read paths stay Contact-specific and USER_MODE. Nine-component Batch B check-only
fails Case-isolation assertion and coverage; no acceptance. Later disabled/planning-only statements
are historical, not permission to access ng-dev or broaden the current scope. Current evidence:
`evidence/P8/FOUNDATION_DEPLOYMENT/P8_FOUNDATION_DEPLOYMENT_2026-10-26.md` and
`evidence/P8/BATCH_B/P8_BATCH_B_LOCAL_2026-10-26.md`.

**Latest continuation:** owner-enabled Digital Experiences is verified true; site list is empty
and Customer Service template exists. Four local default-deny context/permission definitions are
prepared, not deployed or actual-user tested. No site/user/share/publication is authorized.
`docs/planning/P8_FOUNDATION_LOCAL_PREPARATION.md` defines current scope and the isolated pilot-
account provisioning decision; older disabled-state text below remains historical.

**Status:** Phase 8 amendment accepted in principle (owner, 2026-10-14); milestone **M4**. This
note is planning only — **no portal component is authorized for build.**

**P7-18 Batch 3 clarification (2026-10-26):** local work is authorized subject to the existing
pre-build licensing/security gates; Phase 8 is not authorized. Read-only ng-demo settings show
Digital Experiences disabled, Network unavailable and no Site. Customer Community/Plus/Partner
licenses each show five total/zero used, External Identity nine/zero used; license type and
per-object rights remain owner/security decisions. No site enablement, external-user creation,
sharing or activation is authorized. Current gate evidence: `docs/planning/P7_BATCH3_CAPABILITY_GATES.md`.
Only ng-demo may be verified; historical two-org wording below does not authorize ng-dev access.

**Focused P8-01–03 proposal, not a D3/D6 decision:** external Vehicle/Loyalty/Delivery/Service/Case
sharing is verified Private. Customer Community Plus and Contact-specific explicit sharing are
recommended to use reviewed Delivery evidence without inventing a Vehicle owner field. Plus is
role-capable, so the old blanket roleless assumption below is not universal. Relationship isolation
remains mandatory. Narrow object Read versus "no direct grant" wording needs owner clarification
before implementation/grants. See `docs/planning/PHASE8_FOUNDATION_DECISION_2026-10-26.md`.

**Scope of this note:** Phase 8 "Customer Experience Portal" (backlog P8-01..P8-11), built with
**Experience Cloud + custom LWC only**. Salesforce Multi-Framework / React stays a P7-18-only
conditional proposal (`docs/architecture/MF_REACT_P7-18.md`) and is **explicitly excluded** from
Phase 8.

---

## 1. Relationship to P7-18

P7-18 ("Northgate Owner Portal": service history, appointments; 1–2 External Identity users) is
the **seed** of this phase. Phase 8 **extends** it — it does not renumber, rewrite, or change
any P7-18 requirement, acceptance criterion, or evidence path. Where the two overlap, P7-18's
smaller site remains valid on its own; Phase 8 adds the dashboard, vehicles, appointment
request, loyalty, case tracking, and responsive polish on the same surface.

---

## 2. Milestone

| Milestone | Phases | Independently demoable outcome |
|---|---|---|
| **M4 — Customer experience** | P8 | An authenticated customer opens the portal and sees **only their own** dashboard, vehicles, service history, loyalty and cases, and files a service request — or, if licensing is unavailable, the clearly labelled **SIMULATION** fallback (§6) is demonstrated instead. |

---

## 3. Licensing and capability verification — required before any model is selected

**No licensing assumption is made.** Digital Experiences enablement is **not authorized**
(owner decision D4), and the external-user licence model is **not chosen** (D3). Every row below
is verified in `ng-dev`/`ng-demo` before a build decision depends on it, recorded in
`docs/VERIFY_RESULTS.md`, and marked **CONFIRMED** or **REFUTED**.

| # | Assumption to verify | Why it matters | If refuted |
|---|---|---|---|
| V1 | **Digital Experiences enabled** | Without it there is no Experience Cloud site at all | Simulation fallback (§6); P8-01/02 BLOCKED |
| V2 | **External-user licence type** supports authenticated self-service (Customer Community / Customer Community Plus / Partner) | The ~5 **External Identity** licences may not grant Community-style login + Case create | Simulation fallback (§6); re-scope to read-only or simulate |
| V3 | Number of external licences available vs portal users needed | Deployment ceiling | Shrink coverage, never exceed measured count |
| V4 | Each exposed object is reachable for external users (Case, `Service_Visit__c`, `Vehicle__c`, `Loyalty_Member__c`, `Loyalty_Transaction__c`, Contact, Account) | Object/relationship support varies | Expose only via filtered Apex, or drop the feature |
| V5 | Case is usable by external users (OWD Private + external sharing) | Case tracking (P8-08) depends on it | Case feature becomes documented limitation |
| V6 | Guest (unauthenticated) posture | Decide login-only vs mixed | Recommend **login-only**; guest access off |
| V7 | Site metadata deployability from source | No-workaround rule | Owner clicks + `metadata-log/` entry |

---

## 4. External-user access architecture (per owner decision D6)

**The security model must not rely on `with sharing` alone.** External portal users have **no
role** in the hierarchy, so role-based sharing does not reach them. Access is
**relationship-anchored**: every read/write is scoped to the logged-in user's own Contact/Account.

### 4.1 Required controls

1. **Relationship anchoring.** Each external user maps to exactly one Contact and its Account.
   Every portal query filters by that Account/Contact — ownership/relationship is the primary
   boundary, not Apex sharing semantics.
2. **Sharing model.** Confirm **per object** whether an Experience Cloud **Sharing Set** supports
   the Account → object relationship. Do **not** assume Sharing Sets cover every custom object
   or relationship (e.g. `Service_Visit__c` reached via Contact rather than Account). Where a
   Sharing Set cannot grant access, use **Apex managed sharing** (`__Share` records) or expose
   the data only through Apex that filters explicitly.
3. **CRUD/FLS checks.** Apex controllers enforce object and field permissions before query/DML
   (`Security.stripInaccessible` / `WITH SECURITY_ENFORCED`, plus CRUD checks). LWC does not
   grant access; the Apex layer does.
4. **Sensitive fields stay hidden.** `Vehicle__c.Invoice_Cost__c`, `Financing__c.Annual_Rate__c`,
   and `Trade_In__c.Appraisal_Amount__c` are never exposed to external users.
5. **Public Read/Write objects.** `Vehicle__c` and `Loyalty_Member__c` have OWD **Public
   Read/Write** (§6.3). External users must **not** receive direct object access to these;
   surface them only through Apex that filters by ownership. Misconfiguration here leaks *all*
   vehicles/loyalty rows to every customer.
6. **Guest posture.** Login-only portal; no unauthenticated data access.
7. **Cross-customer negative tests.** For every exposed object, an Apex test run as external
   user A asserts it **cannot** read or write external user B's records (§4.2).

### 4.2 Mandatory cross-customer negative tests

| Test | Assertion |
|---|---|
| Read isolation — Case | External user A cannot read external user B's Case |
| Read isolation — `Service_Visit__c` | A cannot read B's visits |
| Read isolation — `Vehicle__c` / `Loyalty_Member__c` | A cannot read B's records via any exposed path |
| Write isolation — appointment request | A cannot create a `Service_Visit__c` against B's vehicle/contact |
| Guest | Unauthenticated request returns no customer data |

A single failing negative test blocks the phase.

---

## 5. Component → data map

| Item | Component | Objects read | Objects written |
|---|---|---|---|
| P8-03 | Portal Apex controllers (with tests) | all below, scoped | — |
| P8-04 | Dashboard home LWC | Case, `Service_Visit__c`, `Vehicle__c`, `Loyalty_Member__c` | — |
| P8-05 | My Vehicles LWC | `Vehicle__c` (+ `Photo__c`) | — |
| P8-06 | Service history LWC | `Service_Visit__c`, Case | — |
| P8-07 | Appointment request LWC | `Vehicle__c`, `Rooftop__c` | `Service_Visit__c` (reuses P6-01 capacity guard) |
| P8-08 | Case tracking LWC | Case | Case |
| P8-09 | Loyalty & rewards LWC | `Loyalty_Member__c`, `Loyalty_Transaction__c` | — |

Every controller is `with sharing` **and** relationship-filtered **and** CRUD/FLS-checked (§4).

---

## 6. Simulation fallback (documented only — not implemented without approval)

If Experience Cloud or the external-user licence model is unavailable (D5), the fallback is the
one already named in `DEMO_ORG_MASTER_PLAN.md` §4.2: a **permission-set-restricted Lightning app
plus a self-service screen flow**, labelled **SIMULATION** in every artifact. The portal LWCs
(P8-04..P8-09) can be re-hosted inside that app. This fallback is **not implemented or activated**
without a separate owner approval.

---

## 7. Risks

1. **Licence mismatch** (External Identity vs Community) — highest risk; forces the fallback.
2. **OWD over-exposure** on `Vehicle__c` / `Loyalty_Member__c` for external users.
3. **Sharing Sets may not cover every object/relationship** — requires Apex managed sharing.
4. **Digital Experiences enablement is a one-way-ish org change** — not authorized now (D4).
5. **Site/sharing config is Setup-only** — no-workaround rule: owner clicks + `metadata-log/`.
6. **Scope authority drift** — `docs/verification/VERIFICATION_HANDOFF.md` scope extended to
   P8 for this phase (scoped amendment; existing records preserved).

---

## 8. References

- Backlog: `DEMO_ORG_BACKLOG.md` P8-01..P8-11 and the M4 gate.
- Master plan: `DEMO_ORG_MASTER_PLAN.md` §4.1 (Experience Cloud row), §4.2 (fallback), §12 (M4).
- Data model: `DEMO_ORG_DATA_MODEL.md` §6.3 (OWD), §6.6 (external access requirement).
- Security: `docs/security/PERMISSION_MATRIX.md` (external-user section).
- Verification: `docs/verification/VERIFICATION_HANDOFF.md` Cat I.
- React (excluded from Phase 8): `docs/architecture/MF_REACT_P7-18.md`.
- Automation direction (wizards are LWC): `docs/architecture/AUTOMATION_DIRECTION.md`.
