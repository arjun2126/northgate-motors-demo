# Phase 8 operational completion register — 2026-10-27, handoff §66

**Latest §77:** service-history two-field Read FLS correction validated 0Afaj00000pTnZRCA0
(1 component, 22/22 tests), Quick Deployed 0Afaj00000pSzJNCA0. Only Mileage_At_Checkin__c and
Case__c Read=true/Edit=false added. Existing assignments/permissions/record data unchanged;
B's successful booking preserved. Per-user native write denials/scoped isolation confirmed.
B history browser retest ready, NOT performed; Phase 8 not complete. Evidence:
`evidence/P8/SERVICE_HISTORY_FLS_DEPLOYMENT/RESULT.md`.

**Latest §76:** minimal dashboard runtime set validated 0Afaj00000pTPCACA4 (1 component,
22/22 targeted tests), Quick Deployed 0Afaj00000pT3OYCA0 and assigned only to A/B. Effective
native Case/Visit write and Vehicle/Model/ledger CRUD denials plus sampled isolation confirmed;
existing membership/ledger unchanged. Portal is already Live. Security validation PARTIAL due
UserFieldAccess UNKNOWN_EXCEPTION; no retries/permission repair. Browser connection unavailable;
owner A/B UAT ready to begin, NOT run/passed. No Phase 8 completion. Evidence:
`evidence/P8/DASHBOARD_RUNTIME_DEPLOYMENT/RESULT.md`. Older Foundation-only/UnderConstruction
statements below are historical, not current operational state.

**Latest §74 — customer identities provisioned:** A 005aj00000guQE9AAM / B 005aj00000guQEAAA2,
hardened Plus profile and Foundation only, existing Foundation membership reused. Guarded native
ARO role PersonAccount/CustomerPortal with correct Account owner. Per-user effective Contact/
Account own Read and foreign denial verified; no Edit/Delete or explicit share grants. Four
synthetic ledger rows/dates unchanged. No Batch B/customer Reviewer assignment. UnderConstruction;
email receipt/password setup, Builder Home Save, controlled publication and actual customer UAT
still pending. No bookings/Cases/jobs/Git. Evidence:
`evidence/P8/CUSTOMER_PORTAL_SETUP/ARO_PROVISIONING/RESULT.md`. Older no-User status is historical.

**Current operational state (§73):** Reviewer assigned to internal Arjun only; four approved
synthetic Ownership/Service_Authorization rows Verified for A/B, valid 2026-10-27T23:06:28Z to
2026-11-03T23:06:28Z; Foundation site membership criterion added, admin criterion retained.
Contact emails retained exactly as approved lowercase. One resumed User attempt rolled back at
role check (expected Worker, actual PersonAccount); no customer Users persist, no second attempt.
Customer assignments/native-access proof and Builder Home Save remain pending. No publication,
write-UAT, scheduler or Git. Evidence `evidence/P8/CUSTOMER_PORTAL_SETUP/RESUME_RESULT.md`.
Older empty-ledger/unassigned-Reviewer statements below are historical, not current data state.

**Current §71 — DEVELOPMENT DEPLOYED:** owner-authorized exact 34-component Quick Deploy
`0Afaj00000pPottCAC` Succeeded, zero errors; reused `0Afaj00000pPiV7CAK` 43/43 tests and 98.039%
broker coverage, prior UI 25/25. P8-05/P8-07 are now deployed; no further development deployment
approval is pending for this package. Source parity, unchanged existing permission/control rows,
customer/users/memberships/shares/business fingerprints/page/navigation XML/scheduler configuration
confirmed; expected new internal metadata defaults enumerated. Native Vehicle/Model/ledger CRUD
and Visit Create remain denied to customers; ledger empty/reviewer unassigned/site unpublished.
No operational or Git actions. Remaining gates: exact two-customer/reviewer/mailbox/data/access
setup, Builder placement, controlled publication and actual A/B/native/API/guest/accessibility UAT,
then owner sign-off. Full Phase 8/M4 NOT accepted. Current evidence:
`evidence/P8/BROKER_DEPLOYMENT/RESULT.md`. Older local-only/undeployed/G2-pending statuses below
are historical and do not authorize repeating deployment or broadening operational authority.

**Current §70:** P8-05/P8-07 broker approach approved and LOCAL implementation complete. Exact
34-component candidate `manifest/p8-broker-local.xml` passes `0Afaj00000pPiV7CAK`, 43/43 Apex
tests, zero errors; local UI/state/source tests 25/25. Broker 98.039%, facade 87.857%, capacity
97.753%, intake 100% coverage. Ledger/reconciler source unchanged. Broker current authorization,
not native grants or scheduled cleanup, governs Vehicle details and booking. No external Vehicle/
Model/ledger CRUD or native Visit Create. Architecture decision is RESOLVED, not a new approval
request. Separate deployment, reviewed ownership/service-consent/identity/access data, Builder/
publication and actual-persona/accessibility UAT still pending. No live/Git operations. Exact
implementation/scope/evidence: `evidence/P8/BROKER_COMPLETION/RESULT.md`. Earlier P8-05/07
incomplete/architecture-blocked table entries below describe historical deployed state; new code
is validated locally but is not a live release or acceptance.

**Latest §69:** ledger/reconciler recovery check-only `0Afaj00000pNyKhCAK` Succeeded (24 components,
11/11 tests, zero errors; guard 92.593%, service/reconciler/trigger 100%). Reviewer fixture cause
measured and corrected with a separate test-only internal inventory builder, no customer grants.
Native maintenance modes explicitly match the already privileged internal integrity/share model;
user-facing reviewer/evidence CRUD/FLS remains enforced. No deployment/jobs/data/security changes.
P8-05/P8-07 still incomplete/fail-closed because exact-expiry native access requires a decision:
`docs/architecture/P8_NATIVE_VEHICLE_ACCESS_DECISION.md` presents one server-mediated/no-native-
CRUD alternative, not yet implemented. Earlier failed-validation gates below are historical.
Exact source/scope/results/limitations: `evidence/P8/OWNERSHIP_RECOVERY/RESULT.md`.

**Latest §68:** metadata corrections accepted in `0Afaj00000pPMPlCAO` (0 component errors),
but validation Failed: 1 successful test/5 failures at reviewer fixture Vehicle insert. No
permission broadening/test patch/retry. Independent remove-only reconciliation source drafted
(not Salesforce-validated or scheduled). Immediate native clock-expiry guarantee not established;
eventual async cleanup is not that guarantee. P8-05/P8-07 still incomplete/fail-closed, no live
deployment/data/grants/jobs/Builder/publication changes. Current exact evidence and activation
dependencies: `evidence/P8/OWNERSHIP_COMPLETION/RESULT.md`. Earlier metadata syntax errors below
are resolved, not current blockers; remaining runtime test-access failure is preserved explicitly.

**Latest §67 implementation attempt:** owner approved local ledger/P8-05/P8-07 work. Independent
ledger source only prepared; check-only `0Afaj00000pOJ7PCAW` Failed (14 component errors, zero
tests) before any customer-feature source changes. Native timed-access/hierarchy proof gates
remain unresolved; no external Vehicle grants. P8-05/P8-07 still incomplete/fail-closed. No actual
deployment, ownership/data/sharing/users/site changes. Exact errors/source/next owner actions:
`evidence/P8/OWNERSHIP_IMPLEMENTATION/OWNERSHIP_LOCAL_RESULT.md`. G1 local implementation is
now authorized; G2 deployment is NOT. Historical §66 preparation text below is retained.

**Development deliveries are not operational acceptance. Phase 8/M4 NOT owner-accepted.**
No new deployment, production code, data/user/share/permission change, Builder Save or publication
in this execution. The prior SiteDotCom investigation is not reopened; no meaningful regression
was demonstrated by that focused check. Exact binary cause remains unestablished, not a new gate.

## Verified evidence from this execution

Raw command outputs and bounded derived results:
`evidence/P8/OPERATIONAL_PREPARATION/verification.json`, `live/`, `profile/`,
`configuration_retrieve.json`, `configuration/`, `relationships.json`, `guest_assignments.json`.
Each claim below is tied to those outputs; no admin context is represented as external-persona proof.

CONFIRMED — selected raw fields:
```json
{"orgId":"00Daj00001Ae3iWEAR","guest":{"objectGrants":0,"apexClassGrants":0,"enabledSystemPermissions":[]},"hardenedProfile":{"denials":{"objects":33,"fields":483,"system":23},"violations":{"objects":[],"fields":[],"system":[]},"enabledSystemPermissions":["PermissionsEnableNotifications"],"caseGrantRow":null,"users":0},"liveApexMatchesLocal":{"OwnerPortalBatchBController":true,"OwnerPortalFoundationController":true},"localBatchCStillMatchesValidatedHashes":true,"lwcCount":6,"fixtureDeliveryIds":[],"fixtureRows":{"visits":0,"cases":0,"loyalty":0},"testsRerun":false,"forceAppChanges":false}
```
Guest's sole assignment is its profile-owned permission set, not Foundation/Batch B; standard
guest FLS defaults are inert without parent object grants. No guest custom Apex is enabled. This
is configuration evidence, not a new anonymous endpoint penetration-test pass.

CONFIRMED — live Network:
```json
{"Id":"0DBaj000006bf3xGAA","Name":"Northgate Owner Portal","Status":"UnderConstruction","FirstActivationDate":null,"SelfRegProfileId":null,"OptionsSelfRegistrationEnabled":false,"OptionsAllowInternalUserLogin":false,"OptionsGuestMemberVisibility":false,"OptionsInvitationsEnabled":false}
```
Network, CustomSite and NavigationMenu XML equal saved Batch C after-state. No binary comparison
performed. Membership remains one admin criterion/three pre-existing internal members; no Plus
users. Plus license count 5 total/0 used. A/B exact Account/Contact links and technical owner
005aj00000gE0b3AAC/VP Sales role verified. Neither fixture has ownership evidence/history/Case/loyalty.

REFUTED — live visual Builder/anonymous-route/real-persona acceptance completed. Exact blockers
and owner actions: `evidence/P8/OPERATIONAL_PREPARATION/ACCESS_LIMITATIONS.md` (disconnected Browser
MCP; local `CERTIFICATE_VERIFY_FAILED`). No TLS bypass or repeated attempts. Live Builder page
inventory, page visibility, rendered branding/login/logout and accessible layout not verified.

## Deployment/automated evidence keys (historical successful results reused)

- **A:** Foundation Quick Deploy `0Afaj00000pGvwECAS`, 5/5; validation 7/7 Apex tests,
  89.19% foundation coverage. `evidence/P8/FOUNDATION_DEPLOYMENT/`.
- **H:** Profile correction `0Afaj00000pJTk5CAG`, followed by combined Batch B two-email-deny
  correction. Effective hardening now confirmed by live readback, not by the earlier incomplete profile.
- **B:** Exact ten-component Quick Deploy `0Afaj00000pIP10CAG`, 10/10, zero errors; validation
  `0Afaj00000pIGp0CAG`, 9/9 Apex tests, 86.667% Batch B coverage. `evidence/P8/BATCH_B_DEPLOYMENT/`.
- **C:** Exact six-LWC standard deployment `0Afaj00000pOUsQCAW`, 6/6, zero errors/tests;
  check-only `0Afaj00000pJzGvCAK`, 6/6, zero errors, zero selected Apex tests. Local JS state/source/
  contrast tests 19/19 in `evidence/P8/BATCH_C/ui_tests.tap`. `evidence/P8/BATCH_C_DEPLOYMENT/`.
- Native site creation: `08Paj00001CQFPWEA5` Complete, Network above. `evidence/P8/SITE_CREATION/`.

## All original items — no acceptance criterion reduced

| ID | Implemented functionality | Actual deployment | Automated validation | Operational status / limits | Owner decision | Remaining work |
|---|---|---|---|---|---|---|
| P8-01 | Customer Service Aura scaffold, standard login, self-registration off | Site creation above | Creation job/readback, no browser substitute | Unpublished; actual Builder page inventory tool-blocked | Builder save, later publication separately | Inspect connected Builder, place Home, capture actual login/site evidence |
| P8-02 | Hardened Plus profile and Contact-specific access contract | A/H/B | Foundation/Batch B actual-license runAs and current effective profile readback | No actual customers, native share lifecycle unimplemented | Two identities, minimum grants/membership and reviewed sharing | Implement native sharing/revocation and verify actual direct-record access incl. same Account |
| P8-03 | with-sharing Foundation/Batch B, USER_MODE, real identity/license/custom permission/Live site | A/B | A 7/7; B 9/9, current live body parity | Positive real endpoint and full native write surface not accepted | Native guard/share implementation then frozen deployment | Scoped direct read/write/tampering/expiry tests; preserve Live gate |
| P8-04 | Dashboard, own Cases/next visit/stored loyalty, ownership warning | B/C | B and C; current six bundles available | Vehicle widget remains blocked; no real-persona positive widgets | Approved positive-data manifest and ownership package | Real own-data and negative widgets, screenshots |
| P8-05 | Safe ownership-unconfigured/no-photo state | B/C | Denial/state tests only, not owned feature acceptance | Owned list/detail/photo/fallback NOT complete | Proposed ledger architecture/evidence and subsequent implementation/deploy/data approvals | Policy/DTO/owned LWC, native read revocation proof, real photo/fallback checks |
| P8-06 | Own Contact visits, dated mileage, linked own Cases, bounded pagination | B/C | B actual-license fixtures + C local UI | A/B have no visits; no previous-owner/Vehicle-wide history allowed | Positive data/visibility scope | Live own/foreign, paging and mileage evidence |
| P8-07 | Disabled eligibility step and server no-write guard | B/C | Fail-closed guard tests; existing capacity evidence reused | Booking wizard/create NOT complete | Ownership AND service authority, guard implementation, write-UAT | USER_MODE request + native guard, preserve capacity/intake, concurrency/retry/expiry tests |
| P8-08 | Contact-filtered Cases/public comments, Service queue create without Case Edit | B/C | B 9/9 includes own create/routing and foreign isolation | Queue share/revocation and native mutation guarantees need proof | Guard/share package and Case/comment test writes | Native/API own/foreign, internal-note hiding, routing/readback and public comments |
| P8-09 | Stored member/tier/points/transactions read-only | B/C | B relationship tests + C UI | A/B no members; no accrual/redemption permission or new ledger activity | Reviewed own-data/visibility fixture scope | Live own/foreign direct record, duplicate-member, FLS and paging checks |
| P8-10 | Responsive native lists/table, focus/labels/validation, text brand/palette | C | 19/19 LOCAL state/source/contrast; not DOM/AT proof | Actual viewport/keyboard/AT/zoom/rendered contrast/brand review outstanding | Builder/brand review, later actual-persona session | Capture 320/768/1440px, zoom/AT/focus evidence on actual published build |
| P8-11 | Activate-persona demo, matrix/register/seam/exceptions and executable operational runbook | Local documentation; no Salesforce deployment needed | Local reference/scope checks only | All real-persona UAT NOT RUN; M4 not passed | Publish/test scope and eventual owner sign-off | Execute approved runbook, preserve failures/exceptions, sign-off register |

## One consolidated owner decision packet — distinct authorities, ordered dependencies

Review and approve/decline each category independently; approval of one is NOT authority for others.

| Gate | Exact proposed scope | Dependency / owner input |
|---|---|---|
| G0 Read-only tool access | Connect ng-demo Builder browser; inspect Home/page list/login/nav/theme/logout/guest settings with no Save | Browser MCP Connect; normal trusted-browser route check. No site enablement or binary re-investigation |
| G1 Architecture + local implementation | One Contact_Vehicle_Relationship__c ledger with fields/invariants in ownership design; ownership separate from service consent; narrow native-share lifecycle and Case/comment/appointment external-write guards; owned-list/photo/wizard integration and scoped tests/check-only | Owner approves schema/security design and authoritative evidence policy. Native temporal revocation/direct-API proof is mandatory; no premature schema/data grant |
| G2 Meaningful metadata deployment | Only the implemented/validated G1 package and permission/share-reason extensions, from force-app source | Exact manifest/hash/results must be reviewed when available. **No new deploy-ready manifest or validation ID exists yet.** Do not repeat A/B/C |
| G3 Identity + assignment + membership | Exactly A/B on existing two Contacts, NG_Owner_Portal_User, Foundation + reviewed feature grants; Foundation-only membership criterion; no internal-role or Account transfers | Two controlled mailboxes/usernames/nicknames and invitation/reset choice; assignment only after native-write boundary proven. Each category explicitly approved |
| G4 Data + sharing | Only an owner-signed row manifest for reviewed ownership/service authority, own Contact/Account/Case/Visit/Member/transactions/reference records and exact per-user grants/revokes | Owner supplies/approves Vehicle IDs/evidence/effective dates and minimal positive test records. No automatic use of old Deliveries or blank Buyer repair. Exact insert effects/counts preview before writes |
| G5 Builder Save / branding | One ownerPortalHome on existing authenticated Home, one native My portal menu entry, standard login/reset/logout; removal only of enumerated irrelevant template widgets after read-only inventory | G0 inventory and explicit save/menu/visibility approval. No guessed standalone child pages; five child LWCs not Builder-exposed |
| G6 Publication + controlled write-UAT | Publish/activate only after permissions/native access/guest/placement gates; run actual A/B login/security/API/booking/Case/comment/accessibility tests with approved test limits and containment actions | G1–G5 proof; live Foundation requires Live Network. No claim that UnderConstruction preview can pass positive endpoint UAT |
| G7 Acceptance | Owner signs actual results and retained exceptions, or records partial acceptance explicitly | No auto-M4/Phase 8 sign-off from code deployment |

There is no authorization to implement significant new schema/security architecture from this register
alone. All other permitted preparation is complete; no live action is waiting on a speculative fix.
Selected design is concrete, but native timed-revocation and direct-surface behavior must be proven
in the approved implementation stage, not waved through as an assumed Salesforce capability.

## Linked execution materials and change scope

- `docs/architecture/P8_CONTACT_VEHICLE_OWNERSHIP.md`: exact proposed schema, evidence, permissions,
  authorization, tests and no-backfill migration plan.
- `docs/planning/P8_PORTAL_PLACEMENT_PLAN.md`: single-page composition, section navigation,
  standard login/logout, responsive/error/brand plan; no invented live page IDs/routes.
- `docs/planning/P8_CUSTOMER_ACCESS_EXECUTION_PLAN.md`: supported A/B provisioning, email,
  membership, native sharing/revocation and native-write proof sequence.
- `evidence/P8/uat/OPERATIONAL_CUSTOMER_UAT.md`: one executable manual customer script; every
  operational row NOT RUN pending relevant authority, identities, records and Live site.
- `docs/planning/NORTHGATE_COMPREHENSIVE_TESTING_HANDOFF.md`: next-stage boundary, not a new audit.
- `scripts/tests/capture_p8_operational_readiness.py`: read-only script executed successfully;
  evidence only, not a deployment/provisioning runner.

No force-app/manifest changes: existing successful tests/check-only/deployments not rerun. Local
document/reference/evidence checks do not pass browser/persona acceptance. Git dirty state is
recorded read-only in evidence/git_status*. No staging, commits, pushes or cleanup. Preserve every
Phase 1–7 acceptance exception, unassigned page, inactive capability and Planning territory state.
Northgate Vehicle Studio remains a post-Phase-8 enhancement, not implemented or brought into scope.

CONFIRMED — final raw `evidence/P8/OPERATIONAL_PREPARATION/git_final_summary.json` fields:
```json
{"porcelainCounts":{" M":64," D":8,"??":4081},"stagedEntries":0,"priorSnapshotEntriesPreserved":true}
```
Complete changed/prepared file list and local-only scope/reference results:
`evidence/P8/OPERATIONAL_PREPARATION/preparation_checks.json`. No new app test/check-only ID.
