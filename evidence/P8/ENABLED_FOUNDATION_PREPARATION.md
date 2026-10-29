# P8-01–P8-03 — enabled-org verification and local preparation

## Read-only org evidence

Owner reports successful Digital Experiences enablement. Target query confirms ng-demo
00Daj00001Ae3iWEAR, Developer Edition. Retrieve 09Saj00000msYViEAM reads Communities settings into
evidence only, not force-app.

CONFIRMED — retrieved XML:

```xml
<enableNetworksEnabled>true</enableNetworksEnabled>
```

CONFIRMED — current Network query result:

```json
{"records":[],"totalSize":0,"done":true}
```

CONFIRMED — native template-list projection:

```json
{"publisher":"Salesforce","templateName":"Customer Service"}
```

The template list contains eleven native templates. The existing Customer Service (Aura)
recommendation is now verified as available; no template/site was created. CLI automatically
installed its community listing plugin locally; no repository dependency or Salesforce feature
was changed by that listing command.

CONFIRMED — license/profile projections:

```json
{"Name":"Customer Community Plus","TotalLicenses":5,"UsedLicenses":0}
{"Name":"Salesforce","TotalLicenses":4,"UsedLicenses":4}
{"UserType":"PowerCustomerSuccess","UserLicense":{"Name":"Customer Community Plus"}}
```

The only active internal User with a role remains the existing NG_Sales / VP_Sales identity.
No current User has ContactId. Existing delivery Buyer and seeded SEED-07-054 / SEED-07-116
Contacts remain on distinct Accounts owned by an administrator with UserRole=null. They are not
silently reassigned or made provisioning-ready. The completed-delivery query still returns one
Buyer/Vehicle pair; six missing historical Buyers were not repaired or guessed.

Architecture is finalized as a login-only Customer Service site, Northgate Owner Portal / owners,
Community Plus, Contact-specific native sharing plus with-sharing/USER_MODE/CRUD-FLS checked
Apex. Site creation, user/profile/membership/shares and publication remain separately authorized.

## Provisioning decision, not an executed change

The safest proposed pilot leaves all existing customers/Account owners and internal roles intact:
two new synthetic Account/Contact pairs, owned from creation by the existing role-qualified
VP user solely for native provisioning, if the owner explicitly approves that limited fixture
responsibility. No additional internal license or role reassignment. Two Plus users would later
use two of five free external slots. No site, Account, Contact, User, role or share was created.

The new pilot Contacts would initially have no confirmed vehicles/history. Existing UAT/seeded
data remains review/negative-test material; do not attach old deliveries to new Contacts. Positive
Vehicle ownership needs separately confirmed existing evidence or explicitly approved future
synthetic fixture scope, not a reservation, service visit or historical buyer backfill.

## Local implementation prepared, not deployed or server-tested

Four new local definitions in manifest/p8-foundation-preparation.xml:

- ApexClass OwnerPortalFoundationController.
- ApexClass OwnerPortalFoundationControllerTest.
- CustomPermission Access_Northgate_Owner_Portal.
- PermissionSet PS_Owner_Portal_Foundation (unassigned).

The non-cacheable endpoint accepts no identity selectors and returns only current Contact/Account
IDs after Plus/active/permission/live exact-site and USER_MODE record checks. No customer names,
emails, Case/Vehicle/financial data or writes. The permission set has Account/Contact Read only;
it cannot replace a hardened portal profile or remove the standard profile's Case Edit.
No Network/CustomSite/Experience bundle, Profile, role, User, share, activation or guest grant is
invented in the local package. Actual site metadata must come from approved native creation.

Command executed (local source conversion; no org target):

```sh
sf project convert source --manifest manifest/p8-foundation-preparation.xml --output-dir evidence/P8/LOCAL_FOUNDATION_CONVERSION --json
python3 scripts/tests/check_p8_foundation_local.py
```

CONFIRMED — raw local-check projection:

```json
{"status":"PASS","localMetadataComponents":4,"siteProfileUserSharingComponents":0,"contextCacheable":false,"permissionSetAssigned":false,"sourcePolicyTestsProvided":3,"apexTestsExecuted":0,"serverCompilation":"NOT RUN","positiveExternalUserSiteFlsProof":"NOT VERIFIED","orgWritesPerformed":0}
```

The source converter returned status=0, warnings=[]. This checks packaging/XML/boundaries, not
Apex compilation or security runtime. Three Apex policy/current-internal-denial tests are
provided but have not run; positive external-site/identity/FLS proof remains outstanding. No
test users/records, Apex test execution, Salesforce check-only/deployment or prior Phase 7 suite
rerun occurred. No Git stage/commit/push or ng-dev access.

The sole next material decision is approval/rejection of the limited role-qualified fixture-owner
plan. Exact remaining site/profile/user/share/deploy/publication scopes are in
docs/planning/P8_FOUNDATION_LOCAL_PREPARATION.md. Phase 8 is not accepted; Phase 7 exceptions remain.
