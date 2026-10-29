# P7-12 — native territory implementation design

**Subsequent validation:** owner-authorized six-component check-only `0Afaj00000p7zkYCAQ`
succeeded 2026-10-26T03:24:10Z with 6/6 components, zero errors and zero Apex tests. Submitted
Read/None/None/None access values were accepted without metadata edits. Earlier unverified
server-gate wording below records the design baseline; current result is
`evidence/P7/P7_12_SCOPED_VALIDATION.md`. No actual deployment or assignment/activation occurred;
persisted/effective access and identity decisions remain outstanding.

## Authorization and file-level plan

This task authorizes read-only dependency inspection, implementation design and scoped local
metadata preparation. It does not authorize live model/type/territory creation, deployment,
activation, Account/User assignment, org-wide sharing changes or Git release actions.
Only ng-demo `00Daj00001Ae3iWEAR` may be accessed.

1. Inspect the current P7-12 acceptance criteria, handoff §40, native settings, actual users,
   roles, Staff links, Rooftop managers and relevant effective permission definitions.
2. Record focused read-only schema/persona evidence under `evidence/P7/P7_12_DESIGN_*` using
   `scripts/tests/inspect_p7_12_design.py`. Verify native manual-association support and metadata
   shape before selecting assignment/access settings; do not assume lookup-rule support.
3. Prepare only a native model/type/four-sibling-territory source slice under `force-app/`,
   with its own manifest and local scope check, where verified settings permit safe preparation.
   Do not add assignment rules, helper fields, Apex, Flows, memberships or settings by default.
4. Finalize this design with actual user recommendations, least-privilege access, precise
   configuration dependencies and separate deployment/data-assignment/activation approvals.

The five Accounts without Preferred_Rooftop__c remain untouched. Existing CP2 and Phase 1–6
functionality is preserved. P7-07–P7-10 code and the successful 235-test baseline remain intact;
no demonstrated reason currently exists to repeat those Apex tests.

## Recommended architecture and assignment approach

Use one native model `NG_Rooftops` (display name Northgate Motors), one shared type `NG_Rooftop`
(display name Northgate Rooftop, priority 1), and four sibling territories: Downtown, North,
Airport and Service_Centre. Omit parentTerritory on all four; the model itself supplies the root.
Priority classifies this one shared type; it does not establish user authority or business rank.

**Recommendation: one-time, owner-approved native manual Account associations.** Select the
explicitly approved Accounts with non-null Preferred_Rooftop__c mapped to one of the four
existing rooftop records. Resolve model/territory IDs at execution time from exact developer
names, then insert ObjectTerritory2Association with ObjectId=Account.Id, Territory2Id=resolved
territory and AssociationCause=Territory2Manual. This changes native association data, not Account
ownership, Preferred_Rooftop__c, CP2, Opportunity assignment or Account/User roles.

The existing 150 mapped Accounts are the candidate ceiling, not a preapproved load. Preserve
the five null-rooftop Accounts and their fields/associations unchanged. Do not use a name, owner,
postal code, Staff role, finance activity or nearest-rooftop guess to place them.

This is a point-in-time alignment, not a background sync. New Accounts or later changes to
Preferred_Rooftop__c will not automatically realign. Revisit only if ongoing automatic alignment
becomes a real requirement. No helper field, formula, Flow, Apex service, trigger or scheduled
job is needed for the current four-rooftop demo.

## Supported native mechanisms and evidence boundary

The current native describe confirms ObjectTerritory2Association is createable/queryable/
deletable but not updateable. ObjectId accepts Account (and also Lead, which is outside this
scope); ObjectId and Territory2Id are createable. AssociationCause is createable and exposes both
Territory2Manual and Territory2AssignmentRule. UserTerritory2Association exposes createable
UserId/Territory2Id. This verifies the native API contracts in the authenticated admin context,
not a successful insert, planning-model behavior or operational-persona license/access test.

Territory2Rule exists in the WSDL-derived metadata schema, and Salesforce's source registry
supports model-scoped rules/territories. Neither proves Account.Preferred_Rooftop__c is an eligible
rule criterion. The Account describe confirms this field is a lookup/reference; no claim is made
that its filterability or API accessibility makes it available in the native rule builder.
Direct lookup-rule eligibility remains unverified and is unnecessary for the recommended manual
association path. No rule metadata is prepared and no new field is proposed to bypass that gate.

Salesforce Developer/Help pages did not expose usable content through the available fetch tool.
Metadata shape is instead checked against the WSDL-derived jsforce schema and Salesforce's own
source-deploy-retrieve registry plus territory snapshot fixtures. These references establish
format/packaging, not server acceptance or current administrative UI behavior. URLs/hashes and
raw native describes are in `evidence/P7/P7_12_DESIGN_INSPECTION.json`.

## Actual persona and responsibility findings

Live queries include active users, profiles/licenses, roles, permission assignments, Staff user
links and Rooftop manager lookups. A separate targeted query included inactive users with the
operational role/profile names; it still returned only the VP_Sales user on NG_Sales.
All fourteen Staff.User__c links and all four Rooftop.General_Manager__c values are null.
Is_Persona_Login__c is not a real linked User and is not a territory membership instruction.

| Territory | Intended responsibility if an eligible identity is approved | Existing user recommended now |
|---|---|---|
| Downtown | Dedicated Sales_Rep / Sales_Manager_Downtown with verified Downtown responsibility | None: Sales_Rep has Downtown's manager as its parent role, but no User holds either role |
| North | Dedicated Sales_Manager_North or explicitly linked North operational identity | None: role exists without a matching configured User/link |
| Airport | Dedicated Sales_Manager_Airport or explicitly linked Airport operational identity | None: role exists without a matching configured User/link |
| Service Centre | Dedicated Service_Advisor / Service_Manager only if Account-read responsibility is approved | None: roles exist without matching Users/links; a Staff record is not a login |

The actual business-profile user `005aj00000gE0b3AAC` has NG_Sales / Salesforce license /
VP_Sales and PS_VP_Executive_Reporting. Preserve the owner's VP metrics-only boundary; do not
add all four memberships because the role sounds senior or because older switcher plans exist.
Three active Salesforce users have System Administrator profiles and no roles
(`005aj00000fH2LxAAK`, `005aj00000feqbNAAQ`, `005aj00000gBoPVAA0`). Recommend no memberships for
these administrators; their administrative visibility is not a positive territory-sharing demo.
Analytics, Chatter, automated and integration identities are not rooftop sales/service members.
No existing Finance-role user was found; do not attach Finance responsibility to VP/Admin to fill
that gap. Actual profiles, roles and identities remain unchanged.

The live Salesforce license query reports four total/four used. No license reclamation, user
creation, profile/role swap or paid expansion is part of this design. Owner must decide which
existing identity can legitimately demonstrate operational territory access without violating
preserved Admin/Sales/Finance boundaries. Until then the recommended User assignment delta is
**zero for every territory**, and actual-persona acceptance remains blocked.

## Least-privilege access recommendation

| Object | Last retrieved native default | Explicit local territory value | Reason |
|---|---|---|---|
| Account | Read | Read | Smallest exposed territory Account level; enough for the Account mapping demo |
| Contact | Edit | None | P7-12 requires no Contact record access or editing; no demonstrated reason to grant it |
| Opportunity | None | None | Preserve existing private opportunity/Quote/finance paths; no sales-deal widening |
| Case | None | None | Preserve existing Service/Case boundaries; this is not a service-queue sharing change |

Live EntityDefinition reports Private internal and external sharing for all four objects.
Native Territory2 describe lists the proposed Read/None values as active, createable/updateable
picklist values. All four local territory files explicitly specify them; none inherits Contact
Edit by omission. No Settings component or org-wide sharing change is included.

**Deployment gate:** live default/minimum/override behavior has not been tested. Native field
values and offline conversion do not prove that Salesforce accepts Contact None under the
current Contact Edit default, or that the effective sharing matches that declaration. First run
the separately approved six-component metadata-only check-only. If Salesforce requires a default
change or rejects the override, stop and obtain an explicit owner decision; never substitute Edit
or silently update Territory2Settings. After an approved deployment, read back all four territory
access fields before any association, membership or activation. Contact Read would also be an
additional decision, not an automatic compromise.

Territory sharing is additive. None does not revoke ownership, role, sharing-rule, implicit or
administrative access. CRUD/FLS still apply. Opportunity/Case None does not promise these objects
are invisible through existing grants. Preserve the disabled Opportunity filter; no forecasting
configuration or assignment integration is part of this scope.

## Prepared local scope

`manifest/p7-12-territories.xml` selects exactly six components:

- Territory2Type: `NG_Rooftop`.
- Territory2Model: `NG_Rooftops`.
- Territory2: `NG_Rooftops.Downtown`, `.North`, `.Airport`, `.Service_Centre`.

Source paths:

- `force-app/main/default/territory2Types/NG_Rooftop.territory2Type-meta.xml`.
- `force-app/main/default/territory2Models/NG_Rooftops/NG_Rooftops.territory2Model-meta.xml`.
- Four files under `force-app/main/default/territory2Models/NG_Rooftops/territories/`.

No rule, user membership, assignment CSV/loader, setting, permission, OWD, Apex, Flow, custom field
or destructive change is included. Model state is not a Territory2Model metadata property in the
reference schema; do not invent a `<state>` tag. The native object describes Planning as its
default state, but an eventual deployment must verify State=Planning before further operations.
No activation operation is packaged.

Offline checks: `python3 scripts/tests/check_p7_12_metadata.py`; native source conversion:

```sh
sf project convert source --manifest manifest/p7-12-territories.xml --output-dir evidence/P7/P7_12_METADATA_CONVERSION --json
```

Conversion is local and has no target-org argument. The converted package contains only the
same six components. The scope checker compares converted/source XML, exact member sets,
explicit supported access values, four siblings/no rules, and all twenty previous Batch 2
selected source hashes. No Apex test run or org check-only has been performed for this design.

## Exact next actions and separate owner approvals

1. **Approve design and scoped check-only only.** Approve the one model/type/four siblings,
   explicit Read/None/None/None access and manual-association approach. Then authorize:

   ```sh
   sf project deploy start --dry-run --target-org ng-demo --manifest manifest/p7-12-territories.xml --test-level NoTestRun --wait 10 --json
   ```

   This proposed Developer Edition metadata-only check has not run. Stop on unexpected errors;
   do not modify settings or rerun 235 unrelated Apex methods to compensate for a native gate.
2. **Approve exact metadata deployment separately after validation.** Deploy only the six
   components in the dedicated manifest, with no destructive/settings/user/Account scope.
   This creates a live native model/type/territories and therefore remains unauthorized now.
   Reconfirm the org ID and that NG_Rooftops/NG_Rooftop do not already exist before first
   deployment. Stop on any naming collision or existing active model; do not overwrite it.
   Confirm one model in Planning, four root siblings, one shared type and explicit access values.
   The existing ten-replacement/four-removal Batch 2 package remains a separate approval.
3. **Approve Account association data separately.** Requery Account.Id/Preferred_Rooftop__c
   read-only, freeze the owner's reviewed allowlist and confirm the five null-rooftop Accounts
   are excluded. Resolve exact Planning-model territory IDs. Native CSV/API insertion fields:
   ObjectId, Territory2Id, AssociationCause=Territory2Manual. Account IDs only, never Lead IDs.
   Precheck existing pairs and unexpected memberships; skip exact duplicates, stop on conflicting
   scope, never update/delete existing associations as a workaround. Record inserted association
   IDs and per-territory counts. Do not mutate Account fields or ownership. If Planning-mode
   assignment is rejected, stop rather than activating the model as a workaround.
4. **Approve User membership only after the identity decision.** Current recommendation is zero.
   Any future approved UserTerritory2Association uses explicit existing UserId/Territory2Id pairs
   after license/permission/responsibility review. Do not assume UserRole maps to territory role.
   No profile, role, permission set, license or user change is implicit in membership approval.
5. **Approve activation/sharing recalculation separately.** Before activation, compare Account
   and User deltas with the approved receipts, confirm no rules/Opportunity automation and no
   changes to the five excluded Accounts, then activate the exact model through native Setup.
   Wait for State=Active and sharing recalculation; do not treat Activating as success.
6. **Run actual acceptance with approved identities.** Capture the four-sibling native tree,
   reviewed Account assignments and positive/negative cross-territory access compared with the
   preactivation baseline. Verify no new Contact edit, Opportunity/Quote/finance or Case access.
   Administrator tree visibility is not operational sharing proof. If rollback is required, stop
   and seek owner approval; delete only receipt-owned associations or perform the specifically
   approved model-state action, never broad cleanup or guessed restoration.

P7-12 remains prepared locally, not deployed or accepted. Batch 1 browser/gallery/event
acceptance, operational access/page placement and VIN credentials remain deferred; Batch 1 is
not owner-accepted. Phase 6 exceptions and P7-11 reader/browser gates are unchanged.
