# Final Phase 8 development deployment — 2026-10-27

## CONFIRMED — exact validated transaction

`source_parity.json`: all 55 manifest/source SHA-256 entries match successful validation
`0Afaj00000pPiV7CAK`; scoped ledger and three LWC directories contain no extra files. Manifest
types/members match the frozen validated source. `validated_source/` preserves that exact input.

Command:
```sh
sf project deploy quick --target-org ng-demo --job-id 0Afaj00000pPiV7CAK --wait 10 --json
```
Raw `quick_deploy.json`:
```json
{"id":"0Afaj00000pPottCAC","checkOnly":false,"status":"Succeeded","numberComponentsDeployed":34,"numberComponentsTotal":34,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0}
```
Quick Deploy was eligible. One transaction reused the stored 43/43 Apex validation and its 98.039%
broker coverage. Prior 25/25 local UI tests are reused evidence, not a new browser/pass receipt.
No fallback, partial package, unrelated deployment or successful test rerun.

CONFIRMED — `verification.json`:
```json
{"reusedValidationId":"0Afaj00000pPiV7CAK","reusedApexTests":43,"reusedBrokerCoverage":98.039,"reusedLocalUiTests":25,"retrievedSourceFiles":54,"pageSiteXmlFilesUnchanged":64}
```
Deployment componentSuccesses match the validation's exact 34 (type,name) pairs. Full scoped
retrieve succeeded (`after/components_retrieve.json`); all 54 component source files verified in
`component_parity.json`: Apex/trigger/JS/HTML/CSS content matches, normalizing CRLF/terminal newline
only; submitted XML values match retrieved XML with platform-added defaults permitted. Manifest
is not an org component. Source still matches all submitted hashes after deployment.

## CONFIRMED — preserved customer security and business state

Raw snapshots: `before/`, `after/`; comparisons `verification.json`, `permission_deltas.json`,
`platform_default_context.json`, `pages_hashes.json`. Comparisons use actual records/values, not
just totals. All pre-existing queried permission/control rows are unchanged or retained.

Selected raw `verification.json` checks:
```json
{"all_existing_control_rows_unchanged":"CONFIRMED","no_guest_or_portal_vehicle_model_ledger_crud":"CONFIRMED","new_reviewer_unassigned":"CONFIRMED","scheduler_configuration_unchanged":"CONFIRMED","new_ledger_empty":"CONFIRMED","new_ledger_shares_empty":"CONFIRMED","portal_unpublished":"CONFIRMED","no_customer_users":"CONFIRMED","source_unchanged":"CONFIRMED","exact_34_component_transaction":"CONFIRMED"}
```
- All 11 existing Users' profile/role/type/activity/Contact fields compare equal; 32 assignments,
  guest assignment, profiles, existing permission sets/system flags/object/FLS/setup access rows
  unchanged. No customer users, assignments, memberships or invitations created.
- Hardened customer profile, Foundation, Batch B and guest have zero Vehicle/Model/ledger object
  grants. Prior hardened profile object/FLS/system rows and email denies unchanged. No native
  customer Visit Create extension. Reviewer set `0PSaj00000hErrhGAC` is deployed but unassigned.
- Seven available share tables unchanged, including Vehicle shares=0; new ledger shares=0.
  Parent-controlled Loyalty_Transaction__Share remains unavailable, not falsely compared.
- Seventeen business-object Id/SystemModstamp fingerprints unchanged, including Account/Contact,
  Vehicle/Delivery, Visit/Case/comments, loyalty, Opportunity/Quote/QuoteLineItem/Financing and
  product/price records. No ownership/backfill/history mutation; newly deployed ledger has 0 rows.
- All 64 retrieved existing FlexiPage/application/Network/CustomSite/navigation files byte-identical.
  No Builder Save, page assignment or navigation change; no SiteDotCom binary re-investigation.
- All three existing CronTrigger configurations identical, no new job. Reconciler not activated.

CONFIRMED — raw Network state:
```json
{"Id":"0DBaj000006bf3xGAA","Name":"Northgate Owner Portal","Status":"UnderConstruction","FirstActivationDate":null,"SelfRegProfileId":null,"OptionsSelfRegistrationEnabled":false,"OptionsAllowInternalUserLogin":false,"OptionsGuestMemberVisibility":false,"OptionsInvitationsEnabled":false}
```

## Expected metadata additions — not hidden as "zero permission changes"

Raw `permission_deltas.json` additions: 1 permission-set definition, 3 object rows, 6 FLS rows,
9 setup-access rows; zero existing-row edits/removals and zero assignments.
- New internal Reviewer set has its specified ledger Read/Create/Edit, six optional-field FLS
  rows, service class and reviewer custom permission. No enabled system permission flags and
  no Vehicle grant.
- New-object default rows for System Administrator and Analytics Cloud Integration User reflect
  their pre-existing Modify All Data / View All Data rights. `platform_default_context.json`
  proves those global flags true before AND after; no external profile acquired a ledger row.
- Seven new Apex classes acquire platform-generated Administrator class access; the other two
  setup rows are the Reviewer class/custom permission. No customer/guest new Apex or grants.
These inherent new-metadata defaults are enumerated, not mistaken for changed customer rights.
No unexpected security change demonstrated; no corrective org operation performed.

## Development delivery versus operational acceptance

P8-05 vehicle DTO list/details/photos and P8-07 independent-consent, current-ownership, durable
idempotent service requests are now DEPLOYED, alongside the previously completed foundation,
dashboard/history/Cases/loyalty/polish and UAT preparation. Broker checks current authority on each
request while native Vehicle/Model/ledger CRUD and Visit Create remain denied. It reuses the
existing capacity and intake logic; no scheduler is needed for its expiry authorization.

Actual functionality preservation evidence is exact deployed source, reused scoped test results
and unchanged bounded live configuration/data. No fresh full runtime CP2 regression, real-customer
login, live native/API session, real concurrency/load or rendered mobile/keyboard/AT acceptance
was run. No Phase 8/M4 owner acceptance or final demo-readiness claim.

## Genuine remaining gates / shortest separately approved sequence

Focused read-only operational inputs in `operational_inputs/`:
```text
Customer Community Plus: TotalLicenses=5, UsedLicenses=0
A Account=001aj000049ZoXNAA0 Contact=003aj00002Xl4IfAAJ
B Account=001aj000049ZoXOAA0 Contact=003aj00002Xl4IgAAJ
Both Account owners=005aj00000gE0b3AAC, role=00Eaj00000QCxlLEAT
Eligible catalog: a07aj00001MCKYwAAP Northgate Service Centre, active Service_Center, capacity=6
Ledger rows=0; customer users=0; portal never activated
```
No deployment or broker-design blocker remains demonstrated. The remaining gates are operational
authority and evidence, not another development deployment:

1. **Approve a precise pilot setup packet:** two controlled mailboxes/unique usernames, the named
   internal entitlement reviewer, A/B minimum assignments and membership, exact reviewed ownership
   AND separate servicing-consent rows/Vehicle IDs, positive-UAT data and narrow own-record access.
   Execute only those approved categories. Existing Accounts already have the required owner role;
   do not transfer/reparent/repair historical Deliveries. Never assign Reviewer to a customer.
   Keep native Vehicle/Model/ledger and native Visit Create denied; broker needs no Vehicle share.
   Review native Case/comment write and other-source visibility before enabling customer rights.
2. **Approve minimal Builder placement:** connect/read existing structure, save one
   ownerPortalHome on authenticated Home, native My portal navigation/login/logout; five child
   components are already composed, not independent exposed Builder pages. Capture guest/login/
   permission/visibility baseline. Do not publish under page-save approval alone.
3. **Approve controlled publication plus bounded write-UAT/containment scope:** positive portal
   endpoints require Live, so admin/UnderConstruction preview cannot substitute. Publish only after
   setup controls review, then immediately use normal A/B logins to verify own/foreign/missing/
   expired/revoked authority, service/capacity/idempotency, Cases/comments/loyalty and native/API
   tampering/guest denial. Same-Account negative coverage must be retained; extra live fixtures
   require explicit data/user approval, never silently reparent these two Contacts.
4. Capture actual mobile/keyboard/zoom/screen-reader/logout evidence, disposition failures and
   retained Phase 1–7 exceptions, and obtain explicit owner M4/Phase 8 sign-off.

No operational change began. No reconciliation scheduler activation is included in this sequence.
No Git command or source cleanup, no ng-dev access. Existing dirty source left untouched.
