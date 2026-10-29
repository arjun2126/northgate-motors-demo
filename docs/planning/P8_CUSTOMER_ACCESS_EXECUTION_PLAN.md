# Two-customer provisioning and access plan — approval gated

**Current deployed broker (§71):** exact final package deployed `0Afaj00000pPottCAC` (34/34,
zero errors). Do not request/repeat its deployment. Customer Vehicle/Model/ledger CRUD and native
Visit Create/Edit/Delete remain denied; no per-customer Vehicle/ledger shares are required or
authorized by setup. Broker checks current ownership AND separate service consent on every
request and reuses capacity/intake. Reviewer set 0PSaj00000hErrhGAC exists UNASSIGNED and ledger
is EMPTY. The next approval packet must name the internal reviewer separately from A/B and
enumerate exact reviewed rows/mailboxes/assignments/memberships/own-data visibility. Evidence and
shortest sequence: `evidence/P8/BROKER_DEPLOYMENT/RESULT.md`. No setup action is implied here.

No user, permission, membership, share or business-data change is authorized by this document.
Evidence: `evidence/P8/OPERATIONAL_PREPARATION/verification.json` plus raw `live/` and `profile/`.

## Verified prerequisites / exact identities

| Persona | Account | Contact | Technical Account owner |
|---|---|---|---|
| A | 001aj000049ZoXNAA0 | 003aj00002Xl4IfAAJ | 005aj00000gE0b3AAC |
| B | 001aj000049ZoXOAA0 | 003aj00002Xl4IgAAJ | 005aj00000gE0b3AAC |

Both Accounts already have that owner. Owner active, Salesforce license, VP Sales role
`00Eaj00000QCxlLEAT`, PortalType None. No ownership transfer/internal-role assignment needed.
Customer Community Plus: 5 total, 0 used. Hardened profile `NG_Owner_Portal_User`
`00eaj00000UBi7iAAD` unassigned; its profile-owned PermissionSet `0PSaj00000h8ikhGAA`
has only Account/Contact Read, 33 object/483 field/23 system denies intact, both email-management
flags false, Case Read/Create/Edit off, ApiEnabled false. EnableNotifications remains platform-required
true (Send Outbound Messages); do not disable it or reopen the resolved profile correction.

`PS_Owner_Portal_Foundation` (`0PSaj00000h8ikiGAA`) grants self-context Apex,
`Access_Northgate_Owner_Portal`, Account/Contact Read and Contact.AccountId Read.
`PS_Owner_Portal_Batch_B` (`0PSaj00000hABxVGAW`) grants Batch B controller, Case Read/Create
(NOT Edit), selected Case write FLS and Visit/Member/Transaction Read/FLS. It is deployed/unassigned,
despite historical LOCAL labels. It grants no Vehicle or appointment Create. Standard Status,
IsClosed/IsConverted and similar nonpermissionable fields must not receive invented FLS rows.

Both existing Apex bodies match local source. Foundation demands active PowerCustomerSuccess,
exact Plus license, custom permission, own Contact/Account and the exact Live Network on each
request. Batch B adds Contact predicates and USER_MODE queries/DML. Native direct records must
also be isolated; these checks are not a substitute for record-sharing and native-write controls.

## A. Provision identities (requires identity and assignment approvals separately)

1. Owner supplies two distinct controlled test mailboxes, globally unique usernames, desired
   aliases/nicknames, activation/reset delivery choice, testing operators and timezone. Current
   synthetic .test Contact email is not a deliverable invitation address. Do not silently rewrite
   Contact.Email; specify User.Email separately where supported. A required Contact change needs
   explicit data approval. Do not put passwords, reset links, tokens or session IDs in source.
2. Requery license availability, owner role and exact Contact.AccountId. Contact → Enable Customer
   User using supported native UI. Select Customer Community Plus and NG_Owner_Portal_User, ordinary
   lowest available customer role (no manager/executive role, superuser or delegated admin). No
   internal persona-switch script, no VP as customer, no role reuse or old Account transfer.
3. Create exactly A/B only after approval; record resulting UserId/UserType/license/Profile/Contact
   and generated external roles. No welcome email or password reset until owner approves recipients
   and delivery. Native creation can generate roles/sharing and system emails; capture these inherent
   effects in the approved scope. Do not assume a no-email checkbox exists without checking the UI.
4. Only under assignment approval add Foundation plus the reviewed data capability set. **Do not
   assign Batch B as a read-only pilot:** it includes Case Create. For a read-only-first pilot,
   prepare/validate a separate read-only subset of Batch B before seeking its deployment/assignment
   approval; do not mutate the existing set to disguise writes. The recommended full-feature sequence
   instead completes native-write guards before assigning the existing Batch B set.
5. Site membership: native Administration → Members, add only the dedicated Foundation permission
   set as the site membership criterion (if UI offers permission-set membership), then A/B qualify by
   their individually approved assignment. Existing admin group remains untouched. Do not use both
   whole-profile and permission-set membership: criteria are additive and revocation could be masked.
   Capture NetworkMemberGroup/NetworkMember after save and confirm no other users qualify. The
   custom permission is an endpoint gate, not automatically Network membership or sharing authority.
6. Check email deliverability and native welcome/reset settings with the owner. Do not change org-wide
   email policy, sender address, network invitations, self-registration or login/SSO settings to get
   an email through. Use standard normal login/reset; do not store admin-generated credentials.

## B. Exact native record grants (requires sharing approval and tested lifecycle)

| Object / record scope | Future minimum grant | Required guard/revocation |
|---|---|---|
| Own Contact | Own Contact Read only | Never same-Account all-Contacts; reparent/relink requires review |
| Own Account | Read; child Case/Contact/Opportunity access None | Check actual native implicit rights; no business Account-wide data |
| Own Case | ContactId equals user.ContactId, Read only | Queue-owned Case create must gain own share before successful tracking; Contact/owner changes reconcile |
| CaseComment | Own Case parent and IsPublished=true | No internal notes; prove native/UI API visibility, not only Apex filtering |
| Own Visit | Contact__c equals caller Contact, Read | No Vehicle-wide history; linked foreign Case masked and natively inaccessible |
| Own Member | Contact__c equals caller Contact, Read | No Account-wide membership shares; Contact changes revoke stale grant |
| Transactions | Parent-controlled via own Member, Read only | No accrual/redemption/financial relationship FLS; parent change cannot widen customer scope |
| Vehicle / ledger / Model | **No native customer CRUD or record shares**; whitelisted broker DTO only | Current ownership/conflict/expiry/revocation checks per request; native API stays denied |
| Rooftop | No new native customer grant; broker returns approved active service catalog labels | No manager/staff/internal fields; capacity authority remains server-side |

Private external OWD is verified; do not change it or internal inventory OWD. Proposed share reasons
and native-expiry proof gate are in `docs/architecture/P8_CONTACT_VEHICLE_OWNERSHIP.md`. For standard
Account/Contact/Case use supported explicit manual share rows, with a provenance register keyed by
record/user/reason and reconciliation that never deletes unrelated/manual owner work. Custom-object
managed share reasons require new metadata approval. Standard shares can disappear on owner/queue
transfer; don't assume persistence. Revoke losing Contact's app-owned rights in the same relationship
change transaction, then grant only the new reviewed actor. Recheck all other native grant sources:
roles/hierarchy, implicit sharing, sharing rules, groups, account relationships, superuser and admin
rights. A share removal alone cannot subtract access granted by another source.

No Account-based Sharing Set, All Customers group, territory expansion, View All, Modify All,
finance rights, API Enabled or automatic all-vehicle entitlement. Ordinary same-Account customers
must still fail foreign direct-record tests; where native implicit access cannot meet that boundary,
stop and obtain a bounded security design decision instead of relying only on Apex predicates.

## C. Native write boundary before assignment (not a demonstrated exploit)

**Broker amendment now implemented/deployed:** native appointment Create stays denied; controlled
broker write has server-derived identity, strict ownership/service-consent/ID checks, parent lock,
durable token/payload binding and capacity/intake reuse. No additional ServiceVisit external Create
permission or competing native-write path is needed. Historical appointment-trigger proposal below
does not authorize broadening native CRUD. Native Case/comment and other-source visibility checks
remain operational verification gates before write-capable customer assignments; no unverified
all-surface acceptance or additional Case guard implementation is claimed by broker deployment.

Source inspection finds Contact enforcement in the portal methods, but no Case/CaseComment trigger
guard in current source and no ServiceVisit external-caller guard. ApiEnabled=false narrows access
but is not proof that all native UI/API surfaces enforce the same relationship. Current successful
portal runAs tests are not a demonstrated foreign-ID native-write test. Do not call this a confirmed
live vulnerability or silently grant write capabilities on that assumption.

Approval package must include narrowly scoped external-actor guards: Case create derives/requires
own Contact/Account, Service record type, New/Web/Medium and Q_Service_Intake; denies foreign
Contact/Account/owner/status/financial injections. Published comments require own Case and cannot
set unpublished/internal state. Preserve legitimate internal writes and native service-intake
system DML under the external actor; do not add a blanket bypass. No Case Edit/Delete grant.
Appointment authorization runs in the authoritative native write path too, before the existing
automation bypass, and retains capacity/intake. Add actual-license direct mutation tests before
assignment; if platform controls already deny an attempted surface, record the exact result.

Revocation tests: remove custom permission and membership independently; deactivate user; change
Contact/Account/Vehicle relationship; transfer Case owner/queue; revoke service/ownership; expire
entitlement; stale browser tab, cursor and cached response must not regain access. Remove application
grants only under approved revocation scope. No stale-share cleanup of unrelated records is implied.

## D. Publication and UAT order

Keep UnderConstruction while preparing users/grants/pages under their own approvals. Actual positive
portal endpoints require Live; admin/Builder preview cannot prove acceptance. First prove scoped
native security/CRUD/FLS with approved identities without weakening the Live gate, then request
controlled publication with immediate real A/B UI/API/accessibility tests and an approved containment
plan (disable pilot user access/membership or take site offline, not destructive data cleanup).
Publication and that containment configuration are separately approved writes, not part of this plan.
Use `evidence/P8/uat/OPERATIONAL_CUSTOMER_UAT.md`. A/B have no current positive history, Cases,
loyalty or ownership; an approved minimal positive-data/evidence manifest is still required. Do not
alter old deliveries, enroll a customer or fabricate a balance merely to make an empty screen pass.
