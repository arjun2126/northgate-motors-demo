# Phase 8 — dependency-correct preparation and starting point

**Current release/local closeout (§64):** exact Batch B Quick Deploy `0Afaj00000pIP10CAG`
Succeeded 10/10, 0 errors (reused 9/9 tests, 86.667% coverage). Both email flags now false, prior
profile denies intact; preservation checks show no user/assignment/member/share/business changes.
Batch C six-bundle UI/docs prepared locally; check-only `0Afaj00000pJzGvCAK` Succeeded (6/6,
0 errors, 0 Apex tests), local tests 19/19. No Batch C deployment or real-customer UAT/acceptance.
Ownership, two Plus users, memberships/shares, page placement, publication and actual testing remain
separate decisions. Current evidence: `evidence/P8/BATCH_B_DEPLOYMENT/P8_BATCH_B_DEPLOYMENT_2026-10-27.md`
and `evidence/P8/BATCH_C/P8_BATCH_C_LOCAL_2026-10-27.md`. Older statuses below are historical.

**Latest Batch B local closeout (§63):** final changed scope `0Afaj00000pIGp0CAG` Succeeded,
10 components, 9/9 tests, 0 errors, 86.667% controller coverage; UI-state tests 12/12. Dashboard,
history/mileage, Cases/comments and loyalty implemented/scoped-tested. Vehicles/appointments remain
ownership-blocked. Explicit EmailAdministration/EmailTemplateManagement false entries are supported
and effective in validation; live true-flag persona has template Create entitlement. Profile remains
unassigned; no new deployment, user/share/site changes or Batch C. Exact status/scopes:
`evidence/P8/BATCH_B_COMPLETION/P8_BATCH_B_COMPLETION_2026-10-27.md`.

**Latest profile-only deployment (§62):** `0Afaj00000pJTk5CAG`, Succeeded 1/1, 0 errors/tests.
Effective denies: objects 33/33, fields 483/483, system permissions 23/23; Case Create/Edit off,
license-required EnableNotifications on. Two email capability flags remain true; no further
changes, keep profile unassigned pending owner disposition. No Batch B deployment/publication.
Evidence: `evidence/P8/PROFILE_SECURITY_DEPLOYMENT/P8_PROFILE_SECURITY_DEPLOYMENT_2026-10-27.md`.

**Latest bounded remediation (§61, 2026-10-27 UTC):** profile-only explicit-deny check-only
`0Afaj00000pJ0QMCA0` succeeded; combined `0Afaj00000pILVGCA4` passes 12/12 tests at 78.761%
Batch B coverage. Case issue was invalid external-owner fixture, not a demonstrated query leak;
fixture corrected with persisted-Contact assertions. Current-source all-system-denies strengthening
run `0Afaj00000pIz4VCAS` completed Succeeded: 10 components, 12/12 tests, 0 errors, 78.761% coverage.
No deployment; live profile still unassigned/Case Edit, ownership
unmodified. Current evidence: `evidence/P8/BLOCKER_REMEDIATION/P8_BLOCKER_REMEDIATION_2026-10-27.md`.

**Latest authorized deployment/Batch B (§60):** foundation Quick Deploy `0Afaj00000pGvwECAS`
succeeded, five components, reused 7/7 validation tests and 89.19% coverage. **Live profile
least-privilege REFUTED** (Case Create/Edit/default grants); keep unassigned. No external users,
memberships/shares or publication. Independent Batch B local work started without further
start approval; nine components compile, UI-state tests 7/7, but check-only `0Afaj00000pGPzbCAG`
fails Case-isolation count assertion (2/3 tests, 69.027%). Stop affected work pending diagnosis;
vehicle ownership decision still blocks P8-05/07. No Batch B deployment. Current evidence:
`evidence/P8/FOUNDATION_DEPLOYMENT/P8_FOUNDATION_DEPLOYMENT_2026-10-26.md` and
`evidence/P8/BATCH_B/P8_BATCH_B_LOCAL_2026-10-26.md`. Earlier entries below are historical.

**Latest successful validation (§59):** `0Afaj00000pHlunCAC`, five components, 7/7 tests pass,
0 component/test errors, controller coverage **89.19% (33/37)**. Only test exception assertion
changed this turn; production/profile/permissions/seam unchanged. Coverage blocker resolved;
no deployment or live-site acceptance. Evidence:
`evidence/P8/FINAL_ASSERTION_CORRECTION/P8_03_FINAL_ASSERTION_CORRECTION_2026-10-26.md`.

**Latest compilation repair (§58):** `0Afaj00000pGnaUCAS`: 0 component errors, coverage **81.08%**,
6/7 tests pass. Positive path reaches own IDs/foreign USER_MODE denial; forbidden Contact write
raises TypeException rather than DmlException. Stop pending test-only exact-exception assertion
correction; no production security change needed for this failure. No deployment/profile changes.
Evidence: `evidence/P8/COMPILATION_REPAIR/P8_03_COMPILATION_REPAIR_2026-10-26.md`.

**Latest positive-path work (§57):** private environment-fact seam retains actual authorization
and USER_MODE reads; two-user permission/isolation tests added. Single five-component check-only
`0Afaj00000pHga9CAC` fails with 10 test compiler errors (read-only Network constructor fields and
enum/string assertion). Tests never ran; no new coverage. Stop pending test-only compile correction
approval. No deployment/profile changes. Evidence/proposed diff:
`evidence/P8/POSITIVE_PATH_TESTABILITY/P8_03_POSITIVE_PATH_TESTABILITY_2026-10-26.md`.

**Latest test-only correction (§56):** `0Afaj00000pG0cJCAS`, same five components: 6/6 tests pass,
0 component/test errors, still failed 37.5% controller coverage. Real external runAs completes;
no permission, null Network and early endpoint denial now verified. Protected paths remain
unreached. Controller/profile unchanged. Next decision is positive-path permission/site-context
testability, not another query fix. Evidence:
`evidence/P8/TEST_QUERY_CORRECTION/P8_03_TEST_QUERY_CORRECTION_2026-10-26.md`.

**Latest single five-component validation (§55):** `0Afaj00000pGXlqCAG`: 5 tests pass, 1 fails,
0 component errors, 37.5% coverage. Hardened-profile test-user creation succeeds and external
runAs is reached; first User→Profile relationship query fails. Stop pending test-only fixture
query-correction approval, no retries. Controller/profile unchanged. Evidence:
`evidence/P8/FIVE_COMPONENT_VALIDATION/P8_03_FIVE_COMPONENT_VALIDATION_2026-10-26.md`.

**Latest investigation (§54):** exact four-component check-only `0Afaj00000pHSowCAG` fails:
5 tests pass, new real external-user fixture fails with standard external-profile creation disabled
(`FIELD_INTEGRITY_EXCEPTION`, ProfileId). Controller still 37.5%. Production/profile unchanged;
stop pending owner approval for five-component check-only including the unchanged hardened custom
profile as the fixture profile. No setting changes, deployment or permission/membership assignments.
Evidence: `evidence/P8/EXTERNAL_USER_INVESTIGATION/P8_03_EXTERNAL_USER_INVESTIGATION_2026-10-26.md`.

**Latest P8-03 test repair:** check-only `0Afaj00000pHKg5CAG`, 5/5 tests passed, 0 component/test
errors, still failed at 37.5% controller coverage. Only tests changed (null-boundary/early-denial
assertions); production controller/profile unchanged. No production defect established; stop
pending explicit production testability-refactor/security-test-plan approval. No deployment.
Handoff §53; `evidence/P8/COVERAGE_REPAIR/P8_03_COVERAGE_REPAIR_2026-10-26.md`.

**Site creation executed 2026-10-26:** the login-only Customer Service (Aura) site **Northgate Owner
Portal** / `owners` now exists in ng-demo, unpublished (`Network 0DBaj000006bf3xGAA`,
`Status=UnderConstruction`, `FirstActivationDate=null`), self-registration off, with a
Salesforce-generated guest profile (`00eaj00000UB3CcAAL`) holding zero object permissions and no
custom Apex access (standard site page/FLS defaults only, inert without object permission). Evidence: `evidence/P8/SITE_CREATION/P8_01_SITE_CREATION_2026-10-26.md`; handoff §51.
P8-01 is **not fully accepted** until the hardened profile, users/membership, narrow shares and
negative access tests exist.

**Focused foundation update:** read-only P8-01–P8-03 verification now recommends Customer Service
(Aura), Customer Community Plus, Contact-specific native record shares and LWC/with-sharing Apex.
Architecture is finalized for local preparation, not live implementation/acceptance. External OWD
is Private; owner-enabled Networks is verified true, with one unpublished site and no users.
Four local context/security definitions compile in check-only and 3/3 tests pass, but validation
`0Afaj00000pGEeLCAW` fails at 37.5% controller coverage (75% required). Hardened Plus profile
`NG_Owner_Portal_User` is locally prepared; profile check-only `0Afaj00000pFlPSCA0` succeeds
(1 component, 0 errors, 0 tests). Nothing deployed. Coverage repair needs owner approval.
Exact results: handoff §52 and
`evidence/P8/PROFILE_PREP/P8_02_03_SECURITY_FOUNDATION_2026-10-26.md`.
Ownership/provisioning decisions remain incomplete. Current bounded scope:
`P8_FOUNDATION_LOCAL_PREPARATION.md`. Original decision/history:
`PHASE8_FOUNDATION_DECISION_2026-10-26.md`; evidence:
`evidence/P8/FOUNDATION_PREREQUISITES_2026-10-26.md`.

## Brief and current authorization

Build a real authenticated Northgate Owner Portal using **Experience Cloud + custom LWC/Apex**
so an approved customer sees only their permitted vehicles, service history, appointments, Cases
and read-only loyalty information. Preserve all existing CRM/CP2/approvals/service/loyalty/
inventory behavior. Current authorization covers local hardened-profile preparation and scoped
check-only validation, not deployment or live permission/user/sharing changes. Prior separate
approvals created the two synthetic customer pairs and unpublished site; no further org writes.

All eleven original backlog IDs below are retained. Phase 8 extends P7-18's intended seed, but
that seed was not delivered in Phase 7. Networks is now enabled and the site scaffold exists,
but no external users or customer login/history/appointment functionality exists.
Phase 7 metadata is deployed but not fully owner-accepted; its exceptions remain indexed in
PHASE7_FINAL_STATUS_2026-10-26.md. No new Flow or React/Multi-Framework implementation is proposed.

## Starting facts and decisions before implementation

- ng-demo only, ID 00Daj00001Ae3iWEAR; never access ng-dev or create a scratch org.
- Networks is owner-enabled; Agent Platform and Data Cloud remain disabled. Agentforce/Data Cloud
  runtime gaps remain Phase 7 obligations, not automatic prerequisites to an independent portal.
- Last measured external licenses: Customer Community, Customer Community Plus and Partner
  Community each five total/zero used; External Identity nine/zero used. These counts must be
  rechecked when choosing a license; they do not prove Case/custom-object access or setup readiness.
- Four Salesforce licenses are used; operational Service/Sales identity/access remains unresolved.
  Do not reclaim administrators, alter VP responsibility or merge Sales/Finance to make space.
- Existing internal Vehicle/Loyalty models have permissive internal OWD; external OWD, object/
  field entitlements, supported Sharing Sets and record relationships require actual verification.
  No broad direct external inventory/loyalty grant or system-mode license bypass is acceptable.
- Current Vehicle source has reservation lookups, not a direct customer-ownership field. Existing
  Delivery__c has Buyer__c/Vehicle__c and completed lifecycle semantics, but that alone is not a
  complete current ownership/resale history. Reserved_By__c is not proof of ownership. Owner must
  approve the supported own-vehicle relationship and treatment of historical/ambiguous links.

Required owner decisions, before any build:

1. **D4 enablement/domain:** explicitly authorize Digital Experiences/domain/site provisioning,
   choose the smallest native site surface and record Setup-only steps. Enablement is not covered
   by final Phase 7 deployment approval. No public/guest business-data surface; recommend login-only.
   **Status 2026-10-26:** enablement done; login-only Customer Service (Aura) site created
   unpublished on the existing domain (see header and handoff §51). Publish/activation remains a
   separate decision.
2. **D3 license/identities:** choose the least-privileged suitable entitlement only after verifying actual
   per-object rights; select one/two approved synthetic Contact/Account identities and required
   account-owner/user-role prerequisites. Do not infer that External Identity grants CRM objects.
3. **D6 relationship/access contract:** define Contact-only versus approved Account-wide sharing
   for each object; verify sharing-set support or approve narrow alternative sharing per object.
   External license types can differ in role support; relationship anchoring remains mandatory
   regardless of roles. Clarify the old "no direct Vehicle/Loyalty access" wording versus required
   licensed CRUD/FLS: object entitlement, UI/API exposure and record isolation are distinct. Do not
   resolve that tension by skipping CRUD/FLS or reading unlicensed data in system mode.
4. **P7-18 seed alignment:** explicitly authorize the missing minimal real seed through the P8
   foundation/history/appointment slices while retaining P7-18 acceptance. Do not renumber/drop it
   or pretend it was delivered earlier. Actual external login/history/appointment evidence remains due.
5. **D5 fallback:** only if needed, obtain a named scope/acceptance amendment. Historical new-Flow
   fallback wording conflicts with the ratified no-new-Flow direction; do not implement it silently.
   No React substitution or paid feature expansion is selected by this plan.
6. **Release/evidence:** keep Phase 5/6/7 exceptions, approve a reviewed source baseline and exact
   metadata/data/UAT operations separately. Clean-tag/M3/M4 completion is not assumed.

## Three independently testable implementation blocks

### Block A — secure foundation and minimal own-data vertical slice (P8-01–P8-03)

After the decisions above, verify native site/template deployability and prepare the smallest
login-only scaffold. **Site scaffold now exists** (unpublished, guest profile with no business
access); the remaining Block A work is the hardened portal profile, deployed/validated controllers,
users/membership/narrow shares and real-persona negative tests.

Define per-object read/write contracts before grants/controllers. Map
authenticated User.ContactId and its verified Account on the server; never trust a caller's
Contact/Account/Vehicle/member/Case identifier as authorization. Default to denial when the
relationship or entitlement is missing/ambiguous. Use existing Apex/domain services, narrow DTOs,
bounded/keyset queries and explicit CRUD/FLS plus sharing/relationship filters.

**Independent exit:** approved external user A logs in and reads an authorized own-data slice;
external B, an unrelated same/different-Account customer as policy requires, guest and denied
identity cannot read or write A's data. Tests run as actual external license personas, not admin.
Only isolated test fixtures are implied by test authorization; real site/users/Contacts/records
need their own explicit approval. Stop on a negative-access failure; no broad grants as a fix.

### Block B — customer features with one write path at a time (P8-04–P8-09)

Efficient feature order: P8-06 own service history, P8-05 owned vehicle/photo surface, P8-07
appointment request, P8-08 Case tracking, P8-09 read-only loyalty; compose P8-04 dashboard once
the feature DTOs exist. Build shared visuals only when actual duplication appears, not as a new
framework. Keep security tests beside every new path rather than postpone them until polish.

- Reuse history pagination/DTO conventions, not an internal controller whose broader record
  scope has not been proven safe externally. No cross-customer data leaks through linked Cases,
  mileage, errors, count widgets, pickers or pagination.
- Reuse the licensed NG_VehicleImages paths/fallback contract, not a global internal inventory
  browser. The internal photo header is RecordPage-only and does not itself grant safe portal
  Vehicle access; do not expose it externally by adding a target or broad object permission.
- Appointment requests set Contact/authorized Vehicle on the server and call the existing
  capacity/intake path. Preserve Toronto-day locks, consuming states and authoritative Case queue
  routing. No new scheduling engine, Field Service product or background job is needed.
- Case list/create/status/comment must honor actual external Case entitlement and verified own-
  customer visibility. Reject arbitrary owner/contact/account/vehicle/status injection; preserve
  P6 routing/SLA behavior. If the chosen license cannot support the required path, obtain a
  specific owner decision instead of fabricating a native Case experience or silently dropping it.
- Loyalty is read-only. Do not activate accrual/redemption/expiry or reconcile historical points.
  Display stored balance/tier/transactions honestly with inactive/historical limitations; do not
  treat a ledger sum as a repaired current balance.
- Dashboard is login-state aware, composes bounded own-data results and exposes no guest data.
  Denied/unavailable data is not silently rendered as a true zero or a successful empty result.

**Independent exit:** approved customer completes the permitted appointment/Case path end-to-end,
sees only own history/vehicles/loyalty and fails foreign-ID/guest/cross-customer attempts. CP2,
approvals, delivery, service capacity and inactive loyalty/consent remain unchanged. The minimal
real P7-18 history/appointment seed can be evidenced here without absorbing the rest of Phase 8.

### Block C — polish, real-persona UAT and seam evidence (P8-10–P8-11)

Apply responsive layout, keyboard/focus/contrast and owned brand identity across the completed
features. Preserve photo licenses; no new third-party brand assets or configurator/3D scope.
Test actual desktop/mobile and error/empty/denied states. Prepare portal.md with Activate persona
first, capture real screenshots as approved external users and update EXPERIENCE_PORTAL.md with
actual native-versus-custom behavior and any explicit owner-dispositioned fallback.

**Independent exit/M4:** all eleven criteria have actual evidence or explicit owner disposition,
all per-object cross-customer negatives pass, authorized customer flow and mobile/keyboard paths
work, source/metadata/data/permissions match reviewed scope and the owner signs off. No self-
declared acceptance, fabricated screenshot or clean release tag from an uncommitted worktree.

## Exact eleven-block dependency inventory

| Block | Original requirement retained | Actual dependency / intended order |
|---|---|---|
| P8-01 | Experience Cloud scaffold; approved enablement/site/domain/metadata ledger | D4/P0-09 and missing P7-18 seed decision; first, no enablement now |
| P8-02 | External access model and negative isolation tests | P8-01 plus D3/D6, per-object licenses/CRUD/FLS/external sharing and ownership decision |
| P8-03 | Secure portal Apex controllers/tests | P8-02; explicit relationship filtering, sharing and field checks, real external runAs positives/negatives |
| P8-04 | Login-aware portal dashboard | P8-03; compose feature DTOs after the initial history/vehicle/write slices |
| P8-05 | My Vehicles/photo/detail and fallback | P8-03/P7-22; verified ownership/visibility, no broad inventory grant |
| P8-06 | Own service/Case timeline and mileage | P8-03/P6-05; verified Contact/Vehicle/Case relationship and per-object entitlement |
| P8-07 | Appointment request LWC/Apex | P8-03/P6-01; validated own Contact/Vehicle, existing capacity/intake guards, no new Flow |
| P8-08 | Case list/create/status/comment | P8-03/P6-02 and actual external Case support, safe relationship/routing/field contract |
| P8-09 | Read-only loyalty balance/tier/transactions | P8-03/P6-06; own membership, no activation/redemption/repair |
| P8-10 | Responsive/branding/accessibility | P8-04–P8-09; actual device/keyboard/contrast evidence |
| P8-11 | Activate-persona demo/UAT/seam note | Block B plus polish; real approved external identities and owner review |

## Next bounded authorization to request

Site creation and profile check-only are done. First request a bounded controller/test coverage
repair and scoped revalidation. Do not work around the failed coverage gate. Then request exact
deployment of five components: profile, controller/test, custom permission and unassigned permission
set (no site metadata). Subsequently request two approved Plus users,
membership and narrow reviewed record grants. Then submit the exact Block A data/UAT plan for
approval. Do not start implementation because this roadmap
exists. Blocks B/C, production record creation, external user grants, deployments and site
activation each retain explicit scope.
Vehicle Studio/configurator remains a separate post-Phase-8 proposal; it adds no twelfth block.
