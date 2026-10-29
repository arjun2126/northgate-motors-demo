# P8-01–P8-03 — enabled-org continuation and bounded local preparation

**Superseding status (§60, 2026-10-26):** five-component foundation deployed via exact Quick
Deploy `0Afaj00000pGvwECAS`; live controller/test match validated source (terminal newline aside).
Profile least privilege is REFUTED: live defaults include Case Create/Edit, 35 object grants,
26 system permissions. No users assigned. Stop profile provisioning pending approved explicit-deny
repair; do not treat earlier source/check-only checks as live hardening proof. Batch B local
development separately authorized and started, not deployed; failed isolation test/69.027%
coverage and ownership policy remain gates. See handoff §60 and evidence/P8/FOUNDATION_DEPLOYMENT/
and evidence/P8/BATCH_B/. Historical preparation-only text below is not current authorization.

## Authorization and file-level sequence

**P8-02/03 continuation, 2026-10-26:** owner authorized hardened portal-profile local preparation
and scoped server check-only with relevant tests. Profile `NG_Owner_Portal_User` is prepared with
only Account/Contact Read + Contact.AccountId Read; no Case, writes, broad permissions or Apex.
Profile validation `0Afaj00000pFlPSCA0`: Succeeded, 1 component, 0 errors, 0 tests.
Four-definition validation `0Afaj00000pGEeLCAW`: Failed, 0 component errors, 3/3 tests passed,
controller coverage 37.5% (75% required). No deployment or live access changes. The older sequence
below records the earlier preparation-only authorization, now superseded only for local profile
preparation/check-only. Exact raw results and investigation:
`evidence/P8/PROFILE_PREP/P8_02_03_SECURITY_FOUNDATION_2026-10-26.md`; master handoff §52.

Owner enabled Digital Experiences. Current work permits read-only inspection and feasible local
foundation/security preparation, not site/user creation, publication, Account transfers, sharing,
permissions, deployment or Git release actions. Target ng-demo 00Daj00001Ae3iWEAR only.

1. Verify enabled settings, empty Network list, native Customer Service template, Plus license/
   UserType and the existing role-qualified user and customer candidates, read-only.
2. Finalize one login-only Customer Service (Aura) site, Northgate Owner Portal / owners, using
   Customer Community Plus. No guest business data, self-registration, SSO, React or new Flow.
3. Prepare only a default-deny self-Contact context controller, policy tests, custom permission
   and unassigned read-only permission set. No customer history/write endpoint, share writer,
   profile clone or invented Network/CustomSite metadata. Native site source must come from the
   separately approved creation of the real site rather than guessed domain/guest-profile IDs.
4. Validate local XML/package/source boundaries and native source conversion only. Do not run
   Salesforce deployments/check-only/Apex tests or create test users without the next bounded
   approval. Positive policy fixtures are not actual external-user access evidence.

## Safest provisioning plan — requires explicit owner approval

Do not transfer any existing customer Account or reparent existing Contacts. Do not assign roles
to the current roleless administrators, swap the VP role or create another internal Salesforce
user (four/four licenses used). The only currently active role-qualified internal user is the
existing VP_Sales identity, 005aj00000gE0b3AAC.

**Recommended pilot:** two dedicated new synthetic Accounts and one new Contact in each, owned
from creation by that existing role-qualified user solely as the native provisioning owner, only
if the owner explicitly approves that limited fixture responsibility. This changes no existing
Account ownership, role, profile, permissions or Finance/Service persona. It is not permission to
use VP as either customer test actor. Two new Plus users would consume two of five unused external
licenses, not internal Salesforce slots. All creation/invitations/memberships remain unauthorized.

This is safer than reshuffling 154 existing roleless-owned Accounts or repairing historical sales.
If limited fixture ownership by the existing role-qualified user is not approved, stop provisioning
at that policy decision; do not silently choose an admin role or ownership transfer.

The isolated pilot Contacts initially have no proven Vehicle ownership/history. Empty own-data
results are honest foundation behavior, not failed ownership inference. Future positive Vehicle/
appointment fixtures need separately approved evidence/data scope; do not attach old deliveries
to the new Contacts or claim a reservation/service visit as ownership. Existing records remain intact.

## Existing candidates and missing evidence

Current read-only queries reconfirm three distinct Contact/Account candidates: seeded
SEED-07-054 and SEED-07-116 (own service-history candidates) and the single UAT completed-delivery
Buyer (Vehicle/loyalty review candidate). All three Accounts are owned by an internal administrator
with no role, so none is provisioning-ready for the proposed Plus pilot without a separate role/
ownership decision. These are reference/negative-test candidates, not automatic live-user selections.

Only one completed Delivery has non-null Buyer and Vehicle; six other completed deliveries have
no Buyer. Current ownership must still be confirmed and allowlisted. Do not backfill Buyer, move
contacts, rewrite a historical delivery or alter existing inventory to produce a positive demo.
Controlled test mailboxes/unique usernames must be supplied outside source; do not reuse reserved
.test emails for actual invitations or store credentials in fixtures/documentation.

## Local source contract

OwnerPortalFoundationController.getContext has no caller-selected Contact/Account parameters.
It is non-cacheable; a prior UI context is not a durable authorization token.
Every later data endpoint must resolve its own server-side context again; returned IDs are not
client-supplied authorization on a subsequent request.
It requires active PowerCustomerSuccess / Customer Community Plus identity, a non-null Contact,
the new Access_Northgate_Owner_Portal permission, and the exact live Network name/path. A missing,
unpublished, wrong-site, guest/internal or unapproved identity fails closed with a generic error.
Only own Contact.Id/AccountId is queried WITH USER_MODE and returned; no names/email, inventory,
Cases, financial data or mutation path is exposed. Self-user/license and Network metadata checks
are not system-mode reads of customer data.

PS_Owner_Portal_Foundation is an unassigned local definition with only controller/custom-permission
access, Account/Contact Read and Contact.AccountId field Read. It grants no Create/Edit/Delete,
View All/Modify All, Vehicle/Case/service/loyalty rights or record shares. A hardened portal-only
profile is still mandatory: a permission set cannot remove the standard Plus profile's Case Edit.
That profile is now prepared and check-only validated, but not deployed or assigned.
No actual profile/permission/share is changed by preparing the files.

Policy tests use in-memory facts and test current internal-context denial, without creating users,
Contacts, Networks or shares. They now pass 3/3 in Salesforce check-only, but coverage fails.
They are not a positive licensed-user, FLS, site or end-to-end P8-03 pass.

## Exact separately approved changes still needed

1. Native site creation: Customer Service, Northgate Owner Portal, prefix owners, existing domain;
   no publish/activation. Retrieve generated Network/CustomSite/Experience source afterward.
   Site creation also generates a technical guest identity/profile and portal metadata; that
   inherent platform scope needs approval, but no guest business-object/Apex access is permitted.
   **Executed 2026-10-26** via `sf community create` (Connect API): Network `0DBaj000006bf3xGAA`,
   CustomSite `0DMaj000006c7JZGAY`, ExperienceBundle `Northgate_Owner_Portal1`, guest user
   `005aj00000gnLcbAAE`, guest profile `00eaj00000UB3CcAAL`. Status `UnderConstruction`,
   `FirstActivationDate=null`, self-registration off, zero guest object permissions and no
   custom Apex access (standard site page/FLS defaults only). No publish, user, membership, share or profile change. Evidence:
   `evidence/P8/SITE_CREATION/P8_01_SITE_CREATION_2026-10-26.md`; handoff §51.
2. Executed 2026-10-26: the two synthetic Account/Contact pairs were created under the approved
   VP owner; see handoff §50. No user aliases/mailboxes, transfers or role changes were made.
3. Local/server check-only is authorized and complete with the coverage failure above. Stop
   controller/test work pending approval of a bounded testability/coverage change and revalidation.
   Future exact deployment scope is five components (profile + four foundation definitions),
   not a site. Separate manifests select profile-only and the four foundation definitions.
4. Approve two Plus users, the hardened portal profile/site membership, then narrow reviewed
   record grants. Keep Private external OWD and Contact-specific native/endpoint isolation.
5. Approve actual customer login/publication only after actual-license sharing/FLS/cross-customer/
   guest/foreign-ID checks pass. No appointment/Case creation rights until later write guards.

**Next material decision:** approve a bounded controller/test coverage repair and scoped check-only
revalidation; no corrective code change has been made. After success, seek separate five-component
deployment approval. Native Customer Service (Aura)
site creation (login-only, no publication) is complete and verified, including the technical guest
identity/profile with zero business-data rights. Two Plus users/membership/narrow shares and any
publish/activation remain separately authorized. Digital Experiences enablement is complete and is
not being requested again.
