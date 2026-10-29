# Contact–Vehicle entitlement ledger — one proposed design

**Current §70:** owner-approved broker amendment implemented and check-only validated by
`0Afaj00000pPiV7CAK` (34 components, 43/43 tests). Validated ledger's 31 source/hash entries remain
unchanged. P8-05/07 local code complete; no native customer Vehicle/Model/ledger CRUD or Visit
Create. Current server checks replace native customer Vehicle grant/USER_MODE booking assumptions
below; cleanup remains defense-in-depth, not exact-expiry authorization. No deployment/data/grants/
jobs/publication. Evidence: `evidence/P8/BROKER_COMPLETION/RESULT.md`.

**Latest §69:** approved ledger/remove-only reconciler now check-only validated by
`0Afaj00000pNyKhCAK` (24 components, 11/11 tests, zero errors), not deployed or activated.
Reviewer fixture FLS/API68 mode issues corrected without customer grants. Guard 92.593%,
service/reconciler/trigger 100% coverage. No time-conditional native permission guarantee from
sharing reasons or async cleanup; P8-05/P8-07 remain fail-closed. One explicit architecture
alternative awaits decision: `P8_NATIVE_VEHICLE_ACCESS_DECISION.md`. Evidence:
`evidence/P8/OWNERSHIP_RECOVERY/RESULT.md`. Historical failed-validation notes below superseded.

**Latest §68:** User reviewer lookup SetNull and explicit sharing reason fullNames accepted by
Salesforce check-only `0Afaj00000pPMPlCAO`; tests fail at Vehicle fixture field access (1/6 passes).
Independent remove-only periodic reconciler source prepared, not validated/deployed/activated.
App-owned immediate termination deletion is drafted but not proven. Time-based async pruning has
no hard deadline; sharing reasons/recalculation do not automatically expire grants. Strict native
API expiry and unrelated-source access remain operational/security gates; no Vehicle rights added.
P8-05/P8-07 incomplete. Exact code/status/timing/activation: `evidence/P8/OWNERSHIP_COMPLETION/RESULT.md`.

**Latest §67:** owner approved this as the local implementation baseline. Independent ledger
source prepared, NOT deployed or validated: check-only `0Afaj00000pOJ7PCAW` failed before tests.
P8-05/P8-07 source remains fail-closed because native time-expiry access enforcement is not proven.
No redesign or external rights extension. The older proposed/unapproved state below is historical;
approval did not waive native access/revocation requirements. Exact partial source/error/gates:
`evidence/P8/OWNERSHIP_IMPLEMENTATION/OWNERSHIP_LOCAL_RESULT.md`.

**PROPOSED, NOT IMPLEMENTED OR APPROVED.** No ownership metadata, grants, records or migration
has been created. This supersedes the older Delivery-plus-manual-share pilot as the recommended
general design, not as an accepted implementation decision. Design approval is separate from
permission to implement, deploy or assign data. Target ng-demo only.

## 1. Existing relationships, not assumptions

Live describe/query evidence: `evidence/P8/OPERATIONAL_PREPARATION/live/describe_*.json`,
`relationships.json`, `live/delivery_evidence.json` and `verification.json`.

- Vehicle has required Vehicle_Model lookup, Rooftop and reservation Contact, but no customer
  ownership relationship. Vehicle.OwnerId is an internal record owner, not customer title.
- Delivery has required Opportunity/Vehicle and nullable Buyer Contact, status and completion
  date. Seven Completed records exist; six have no Buyer. The one Buyer/Vehicle pair belongs
  to neither A nor B and is only a review candidate, not current title proof.
- Service Visit has required Contact and Vehicle, optional Rooftop/Case. This is a servicing
  relationship, not ownership. Existing history remains filtered on Visit.Contact__c and Case.ContactId.
- Loyalty Member belongs to Contact; transactions inherit member sharing. No new ownership
  access may expose a previous customer's visits, Cases, comments or ledger.
- External OWD is Private for Vehicle, Model, Rooftop, Delivery, Visit, Case, Member, Contact,
  Account; transactions ControlledByParent. Internal Vehicle/Delivery/Member remain ReadWrite.

## 2. Single new object, no Vehicle.CurrentOwner duplication

Propose `Contact_Vehicle_Relationship__c`: independent lookup-based, internally maintained
entitlement ledger, internal/external Private, grantAccessUsingHierarchies=false. No master-detail
to Vehicle/Account (no inherited inventory/customer access and no cascade erase of evidence).
No second service-authority object: different relationship kinds use this same ledger.

| Field API name | Proposed definition / meaning |
|---|---|
| Name | AutoNumber `CVR-{000000}` |
| Contact__c | Required Lookup(Contact), restrict deletion; exact entitled customer |
| Vehicle__c | Required Lookup(Vehicle__c), restrict deletion |
| Relationship_Type__c | Required restricted Picklist `Ownership`, `Service_Authorization` |
| Status__c | Required restricted Picklist `Pending`, `Verified`, `Revoked`, `Rejected`; default Pending |
| Effective_From__c | Required DateTime, UTC storage; inclusive |
| Effective_To__c | Optional DateTime, exclusive; must be later than From |
| Revoked_At__c | DateTime; immediate denial at/after value |
| Source_Delivery__c | Optional Lookup(Delivery__c), restrict deletion; evidence pointer, never the entitlement itself |
| Evidence_Type__c | Required restricted Picklist `Reviewed_Purchase`, `Reviewed_Transfer`, `Reviewed_Service_Consent`, `Approved_Synthetic_Fixture` |
| Evidence_Reference__c | Required Text(255), internal evidence-register key, not a public document URL |
| Verified_By__c / Verified_At__c | Lookup(User) / DateTime set by controlled internal verification action, never customer input |
| Revocation_Reason__c | Text(255), required for revoke/end/transfer action; internal only |

Enable field history on Contact/Vehicle/type/status/dates/evidence/verification/revocation fields
within platform limits; preserve signed evidence register outside public assets. No legal-title
claim: this records reviewed portal entitlements. No Account lookup: derive Account from Contact
at request time to avoid duplicated/reparent-stale authority. Pending/ambiguous/missing evidence
has no grant. Verified rows' Contact/Vehicle/type/evidence cannot be edited in place: revoke and
create a new reviewed row. Deletion denied except separately approved retention work.

## 3. Eligibility and transfers

Server resolves the existing Foundation caller on EVERY request, never accepts customer identity
as authority. Active means Verified, verified evidence/reviewer present, From <= now, To null or
now < To, RevokedAt null or now < RevokedAt, Contact exactly caller. Use half-open UTC intervals.
Conflicting overlapping ownership rows fail closed; first release supports one verified owner
per vehicle at a time (no inferred spouse/fleet/co-owner access). Same-Contact duplicate overlaps
are also invalid. Lock affected Vehicle rows in a consistent order in the internal verification
transaction to serialize concurrent ledger approvals; validate bulk inserts/updates and transfers.

- Ownership grants owned-vehicle detail eligibility only.
- Booking requires BOTH a current Ownership row and a separately evidenced Service_Authorization
  row for that exact Contact/Vehicle. Ownership is not service consent; a Service_Authorization
  alone is not title or permission to read previous history. Non-owner booking is outside this
  first portal scope; it remains denied even with service authority alone.
- Service consent evidence for A/B must be explicitly approved, not derived from membership.
- A transfer transaction ends/revokes A's ownership and service grants, removes A's application
  Vehicle shares, verifies B's new evidence and grants only B's approved scope. Fail/rollback
  the entire change if revocation fails; never leave a partially granted transfer.
- Do not reparent A's visits, Cases, comments, member, ledger, reservations or old Deliveries to B.
  A's Contact-specific history remains A's private history. B gains only B's own history, not
  a Vehicle-wide timeline. Never expose original Vehicle ownership/reservation/customer fields.
- Ownership/service revocation, Contact reparenting, user deactivation, permission removal or
  site membership removal must invalidate portal context and revoke relevant native grants.
  Do not move a portal User to another Contact to model resale. No cached entitlement token.

## 4. Permissions and native sharing (mandatory proof gate)

Internal proposed `PS_Owner_Portal_Entitlement_Reviewer`: only approved staff may create Pending
rows and use a reviewed verification/revocation action. No external Create/Edit/Delete on ledger,
no evidence/reviewer field Read externally. Use platform auditing, not a customer-editable status.
External permission extension: read only Contact/Vehicle/type/status/effective/revocation fields
needed by USER_MODE entitlement predicates; only exact own Verified rows shared Read.

Vehicle extension: only Id, Name/approved identity, VIN if owner approves display, Year, Colour,
Condition, Photo, Vehicle_Model and approved model labels. No price/cost/finance, reservation,
customer-owner fields or internal staff data. Model/Rooftop lookups require narrowly approved
reference-row rights; do not grant inventory-wide Read records. No Delivery access needed by
customer: reviewer verifies evidence internally, endpoint reads sanitized ledger and Vehicle.
Expose own dated visit mileage, not a vehicle-wide previous-owner service odometer history.

Use dedicated application-owned sharing reason `Portal_Entitlement__c` on the new ledger and
Vehicle; `Portal_Contact_Access__c` on custom Visit/Member/reference objects where needed. No OWD,
territory or role expansion. Standard Account/Contact/Case require supported manual grants and
exact tracked grant/reconciliation logic; Account child Case/Contact/Opportunity access None.
Share maintenance is narrowly privileged infrastructure, not a system-mode customer data reader.

**Do not equate an expired ledger predicate with native access revocation.** Salesforce share rows
do not provide a demonstrated automatic expiry in this project. A scheduled cleanup alone cannot
prove zero stale access through native APIs. Explicit update/revoke/transfer must revoke shares
synchronously; a future-dated expiry/future activation needs a proven fail-closed native-access
lifecycle before granting Vehicle Read. This is an implementation/validation gate, not permission
to tolerate a window or weaken direct-API isolation. Until resolved, do not deploy/grant the Vehicle
permission extension; existing no-Vehicle-access state remains safe. Include scheduler-delay,
partial-failure, rollback and direct-record tests; do not invent restriction-rule support.

## 5. Exact proposed Apex/LWC integration

After architecture approval, add `OwnerPortalVehiclePolicy` (with sharing, USER_MODE) for shared
current ledger predicates and guarded Vehicle DTO reads. Add only approved methods to existing
`OwnerPortalBatchBController`: owned list/detail, eligible service selection and requestAppointment.
Keep Foundation real Live-Network/license/custom-permission/self-Contact checks unchanged.
Use bounded cursors; reject foreign/tampered IDs generically and never return evidence fields.

`ownerPortalVehicles`: eligible list/detail, Photo image with meaningful alt/fallback, verified
empty/error/denied states. Dashboard uses same policy and shows no vehicle when unverified.
`ownerPortalAppointment`: native LWC wizard Vehicle → approved rooftop/service/date → review →
submit; no new Flow. Recheck live relationship immediately before insert; derive Contact and
status Requested on server, do not accept Account/Contact/owner/status/Case selectors. Insert
Service_Visit__c in USER_MODE; no Edit/Delete grant. Preserve required Vehicle, future-start rule,
ServiceVisitCapacityGuard Toronto-day counts/row locks and ServiceIntakeCaseService queue/Case link.
Use a server-enforced idempotency contract for retried submissions; exact implementation belongs
in the reviewed change package, not an assumed platform guarantee. Never bypass trigger settings.

Native write authorization must also cover direct API/UI API mutations (not just LWC). Propose a
narrow external-actor guard in existing ServiceVisitTrigger before the automation bypass return:
only own Contact, active approved Vehicle/service relationship, approved fields/status/rooftop;
reject relationship/status/owner injection and unauthorized update/delete via CRUD and guard.
Internal service actors retain existing behavior. Do not write a replacement capacity engine.
Case/CaseComment direct-create boundary also requires reviewed guards before granting writes;
interactions with system-generated intake Cases/links must be tested, never solved with a general
static bypass or assuming system DML changes UserInfo. These are undeployed proposed changes.

## 6. Exact tests and migration contract

Future package tests: `OwnerPortalVehiclePolicyTest`, `OwnerPortalAppointmentTest`, entitlement
trigger/share lifecycle tests and targeted existing capacity/intake/portal tests affected by changes.
Use actual Plus `System.runAs` A/B and isolated same-Account third Contact in rolled-back tests.
Cover own/foreign/missing/pending/revoked/future/expired/conflicting intervals; reservation-only,
Account-only, delivery-only and service-only denial; ownership without service consent denial;
concurrent transfer/revoke; expiry and delayed maintenance native reads; source FLS loss; direct
SOQL/UI API access; financial field denial; previous-owner history inaccessible to new owner;
bulk operations/no per-row SOQL; unauthorized native create/update/delete; capacity exact boundary,
Toronto DST/local day, concurrent requests, retry/idempotency and unchanged internal intake routing.
Add LWC list/detail/photo/fallback/wizard state tests. Check-only exact changed source with affected
tests before any deployment; seek approval of frozen manifest/hash after results. No test run now.

Migration: no auto-backfill. Export a proposed evidence register containing Contact, Vehicle,
relationship kind, dates, evidence type/reference and reviewer; owner signs each row. Empty
ownership is valid. Review the one completed Delivery candidate only with current evidence; never
fill missing Buyer or assign it to A/B. A/B require separately approved synthetic vehicle/evidence,
service-consent and positive-test data scope. If none approved, keep owned/booking tests BLOCKED.
Load Pending only after data approval; verification and resulting native shares are another explicit
approved operation. Preserve immutable old Delivery/Vehicle/financial/history values. Pre/post
fingerprints, per-user access tests and a reversible revoke-by-ledger-ID plan are required.
