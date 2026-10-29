# Phase 8 foundation — one recommended architecture and owner decision

**Continuation supersedes the disabled-org baseline below:** the owner enabled Digital Experiences;
retrieve 09Saj00000msYViEAM confirms true, Network list is empty and Customer Service template is
available. Plus UserType is PowerCustomerSuccess. Four local read-only context/security definitions
are packaged, not deployed/server-tested. Enablement is complete; the next decision is the
dedicated two-customer fixture-owner plan. Current scope: `P8_FOUNDATION_LOCAL_PREPARATION.md`;
evidence: `evidence/P8/ENABLED_FOUNDATION_PREPARATION.md`. Prior prohibitions below describe the prior task.

## Recommendation

Use **one login-only Experience Builder Customer Service (Aura) site**, named Northgate Owner
Portal, with **Customer Community Plus** licenses, standard Salesforce login and small custom
LWC/Apex surfaces. Use the existing provisioned Experience hostname; no custom hosting, SSO,
React, new Flow, Automotive Cloud or Data Cloud dependency. Confirm the native template in Setup
after enablement; its current availability is not proven while Networks is disabled.

Use **Contact-specific record sharing plus relationship-filtered, with-sharing Apex**. Community
Plus is recommended because this existing data model needs explicit record-level sharing of
private external Vehicle records reached through reviewed Delivery links; there is no direct
current-owner lookup suitable for an assumed Sharing Set mapping. This avoids adding an ownership
object/field or bypassing sharing in system mode. Five Plus licenses are unused, enough for two
test identities; do not create users or consume a license under current authorization.

No implementation is authorized. This is the focused P8-01–P8-03 decision, not a new portal scope
or an alternate architecture menu. All P8-01–P8-11 requirements remain unchanged.

## Verified starting point and actual blockers

Read-only evidence: `evidence/P8/FOUNDATION_PREREQUISITES_2026-10-26.md`.

- Digital Experiences is disabled; no Site or customer-linked User exists. My Domain is configured,
  and the native Domain record already provisions the my.site.com Experience hostname. A direct
  HTTPS HEAD timed out; browser reachability and site route remain unverified, not diagnosed broken.
- Customer Community Plus 5/0 used, Customer Community 5/0, Partner 5/0 and External Identity 9/0
  are present. The Plus standard profile exists and grants standard Case Read/Create/Edit.
  Custom-object grants and actual external-user CRUD/FLS/share behavior are not yet configured/proven.
- Account/Contact/Case/Delivery/Vehicle/Service Visit/Loyalty Member external OWD is already
  Private; Loyalty Transaction is ControlledByParent. **No org-wide sharing change is needed.**
- 229 Contacts exist; 205 have an Account. Seven completed deliveries exist, but six have no
  Buyer. Only one complete Buyer/Vehicle pair is a current ownership-review candidate.
- 154 of 155 Accounts have roleless owners; only one role-bearing-owner Account exists, with one Contact,
  and it is not the completed-delivery Account. No two existing, ownership-verified/provisioning-
  ready customer pairs were established. Plus provisioning's Account-owner role prerequisite
  requires an explicit owner decision; no role swap, admin reclamation or ownership transfer is implied.

Available licensing and private external OWD are positive findings. Disabled Networks, incomplete
ownership evidence and unresolved identity/owner-role provisioning are genuine blockers. Feature
activation and record/permission changes remain prohibited in this task.

## Customer identity and ownership contract

Resolve the current authenticated external User to exactly one Contact and its verified Account
on the server. Deny guest, internal preview/admin with no Contact, inactive/unapproved identity
and missing/ambiguous Contact/Account relationships. Customer isolation is **Contact-specific**;
sharing an Account does not authorize reading another Contact's Cases, visits, membership or vehicle.
Do not accept ContactId/AccountId/UserId supplied by the client as authority.

**Use existing completed Delivery__c records as purchase evidence, with explicit owner confirmation
of current ownership for the pilot.** The accepted entitlement requires Status__c=Completed,
non-null Buyer__c and Vehicle__c, Buyer equal to the current Contact, and no conflicting buyer/
resale/replacement evidence. A completed sale is not by itself a full ownership history: ambiguous
or unconfirmed records fail closed and appear as ownership unverified, not as an owned vehicle.

For this bounded pilot, the reviewed per-user Vehicle share with the dedicated portal ownership
sharing reason is the approved access allowlist; it does not become legal-title history. Require
both that current entitlement and matching reviewed Delivery evidence for the owned-vehicle/
appointment path. Revoking the entitlement must remove native record access and portal eligibility;
an old purchase alone cannot reauthorize access. Do not rewrite historical Delivery Buyer fields
to model a transfer. A general transfer/co-owner history is not present and is not invented here.

Reserved_By__c, a Test Drive, Service Visit, Account membership, financing applicant or inventory
OwnerId is never ownership proof. Do not fill six missing Buyer fields: existing delivery logic
can trigger enrollment/other side effects. No data repair, reservation change, customer reparenting
or new ownership schema is proposed now. The owner must confirm the single candidate's synthetic
identity/current ownership and approve any additional pilot fixture scope separately.

## Minimum sharing and field contract

Keep all existing internal/external OWD, roles, Sales Territory assignments and CP2/service logic
unchanged. After explicit future approval, create a dedicated least-privilege Plus portal profile/
permission scope and site membership; never modify the shared standard external profile.
No View All, Modify All, report/export/admin, Finance/Quote/Opportunity or unneeded API rights.

For P8-01–P8-03 the first customer data slice is **read-only**. Do not grant visit/Case creation
until the later write guards and authorization tests are ready. Standard Plus profile's existing
Case Edit is not a reason to grant it to the portal profile; tracking does not need status editing.

| Record | Server relationship required | Narrow future record grant / DTO |
|---|---|---|
| Contact / Account | User.ContactId and that Contact's Account | Own Contact and necessary Account Read only; Account child Contact/Case/Opportunity access None, no account-wide customer visibility |
| Vehicle | Owner-confirmed completed Delivery Buyer=current Contact and exact Vehicle | Exact per-user Vehicle__Share Read; customer DTO only model/year/colour/photo/approved identity fields, no invoice cost or all-inventory query |
| Vehicle Model / Rooftop reference data | Model belongs to an entitled Vehicle; service location is in the approved request catalog | Minimum Read/field access to required reference rows only; no manager/User details, pricing internals or customer lookup traversal |
| Delivery evidence | Buyer=current Contact and reviewed completed entitlement | Exact approved read access only if needed to evaluate the relationship; never return internal delivery/checklist/customer-note fields wholesale |
| Appointments/history | Service_Visit__c.Contact__c=current Contact | Exact per-user Read shares; approved schedule/status/mileage/service fields. A visit does not grant ownership of its Vehicle or access to unrelated linked records |
| Case | Case.ContactId=current Contact; linked visit alone cannot override a foreign/null Case Contact | Exact per-user Case Read. Future comments expose only published customer-visible comments, never internal notes. No Contact/owner/status injection |
| Loyalty Member | Contact__c=current Contact | Exact membership Read share; stored balance/tier only, inactive/historical limits explicit |
| Loyalty Transaction | Parent membership belongs to current Contact | Parent-controlled record access plus object/FLS Read; own transactions only, no redemption/accrual/expiry or repair |

Use the existing native share tables for this role-capable license, not broad role/territory/
All-Customers sharing. Custom-object shares need an application-owned sharing reason and bounded
grant/revocation for approved identities/records. Standard Case manual shares may be removed on
owner transfer; future code must revalidate/rebuild only the entitled customer's grant after
queue/owner changes, and synchronously revoke stale grants when Contact/ownership changes.
These are planned security operations, not shares created during this verification.

Vehicle Model and Rooftop external OWD were also verified Private. Their limited reference-data
permissions/shares must be included in future entitlement tests, not assumed from readable Vehicle
records. The customer UI receives whitelisted DTOs, never arbitrary relationship fields.

Two independent controls are required: native record isolation protects every access path;
with-sharing/USER_MODE reads plus explicit current-Contact predicates and CRUD/FLS protect the
portal API. No generic SObject query endpoint or unrestricted system-mode reader. The older
blanket "no direct Vehicle/Loyalty object grant" language needs owner clarification: narrow object
Read under verified Private external OWD is distinct from broad record access or exposing an
internal inventory page. **Approve that clarification before implementation; do not silently
relax the existing security direction or bypass object entitlement.**

For P8-07/08 later, every write must derive Contact/Account on the server, validate the exact
owned Vehicle/Case, restrict accepted fields and reuse existing capacity/intake/routing. Native
API/DML attempts must not bypass the same external-customer constraints: verify or add a narrowly
scoped external-user guard in the authoritative path before granting Create. A private internal
field, hidden button or controller-only check is not a complete write boundary. Preserve internal
actors and existing CP2/approvals/service behavior; no new scheduling or pricing engine.

## Minimum test identities and required tests

Use **two approved Customer Community Plus users A/B**, on distinct Contacts/Accounts, ordinary
lowest customer roles and no superuser/delegated-admin privileges. A real user/Contact/Account
link and supported owner-role prerequisites must be verified before creation. Do not use two
admin sessions, the VP, an old persona-switch script or an internal runAs substitute.

Data candidates for review, not automatic selection:

- A: the single completed-delivery Buyer can exercise confirmed Vehicle/loyalty access after
  owner validation; currently no service history/Case, and its Account owner has no role.
- B: seeded Contact SEED-07-054 has one Service Visit and one separate Contact-linked Case;
  its Account owner also has no role and its stored email is .test. Neither that visit nor its
  Vehicle is ownership evidence. SEED-07-116 was checked as another history candidate, not chosen.
- No two provisioning-ready users are approved. The owner must choose role-qualified ownership/
  test fixtures without silently changing existing customer records or administrator/VP roles.
  Invitation/password delivery needs an approved controlled test mailbox; never rewrite customer
  email values or store credentials to get around the reserved .test fixture domain.

After separate test/implementation authorization, required actual-license runAs and browser/API
checks are: A reads own allowed data; B cannot read A by ID, list, count, pagination, lookup or
linked Case; same-Account other-Contact denial via isolated fixture; guest/internal-no-Contact
denial; missing/wrong relationship and unverified/reserved-only vehicle denial; hidden financial/
internal comment fields absent; no Create/Edit/Delete while foundation is read-only; direct API
and later write foreign-ID/owner/status tampering denied; stale shares revoked on reparent/transfer;
legitimate later appointment still obeys existing capacity/intake/routing and Case owner changes
do not leak/lose entitled access. Two live identities suffice; extra same-Account negative fixtures
can be isolated tests. No tests or users are implemented/created under current authority.

## Owner decisions and exact Setup sequence

**Smallest next action: approve Digital Experiences enablement only on the existing provisioned
domain.** In ng-demo, open Setup > Digital Experiences > Settings, confirm the displayed existing
Experience domain/My Domain and Salesforce's enablement notice, then enable/save only after that
explicit approval. Do not rename/register a vanity domain, click New Site, create a user/profile,
change sharing or publish/activate anything. Record the resulting setting/domain state and stop.
The owner should also check the domain in their browser because the tooling HEAD timed out.

Before code, confirm these specific design decisions: Customer Community Plus and Customer
Service (Aura); strict Contact-specific policy/per-user native Read shares; narrow object Read
clarification under external Private OWD; current-ownership confirmation from reviewed delivery
evidence; two pilot Contact/Account identities and supported account-owner role strategy.

Only after a separate bounded foundation implementation/configuration authorization:

1. Setup > Digital Experiences > All Sites > New: verify Customer Service (Aura) template, choose
   Northgate Owner Portal on the existing domain with a reviewed site path. Inspect resulting
   status; do not Publish/Activate automatically. Capture source where supported.
2. Setup > Profiles: clone Customer Community Plus User into a portal-only least-privilege profile;
   prepare exact allowed object/field/Apex access and site membership. Keep guest business-data
   permissions empty and self-registration disabled. No broad standard-profile, territory or
   internal sharing changes. Validate per-object entitlement before deploying any grant.
3. Resolve approved Account-owner role eligibility and synthetic identity/mailbox scope before
   Contact > Enable Customer User. Create only approved A/B with Plus license/portal-only profile,
   lowest customer role, approved site membership and narrow reviewed record shares. No assumed
   Account transfer, role change, license reclamation or sharing of every Account record.
4. Authorize activation/publish and real login/UAT separately after access-negative tests pass.
   Do not accept owner/admin preview as an external-customer access pass.

Current action ends at planning/read-only verification. P8-01–P8-03 are not implemented, deployed
or accepted. Preserve Phase 7/Phase 6 exceptions, inactive prompt/unassigned Vehicle page,
Planning territory/zero assignments and all existing records/functionality.
