# D08 readiness unblock — READY for exact-artifact deployment approval

Owner-authorized investigation and one new check-only validation completed. **No actual deployment,
Salesforce records/configuration/permissions/sharing changes, source edits, Git operations or
ng-dev access.** READY means technical package readiness, not browser-verified D08 closure or
full-project UAT acceptance. Prior failed job `0Afaj00000paEa9CAE` remains preserved.

## 1. Exact cause of the unexpected field

The repository parent file
`force-app/main/default/objects/Financing__c/Financing__c.object-meta.xml` contains:

```xml
    <fields>
        <fullName>Finance_Exception_Approved__c</fullName>
    </fields>
```

This is an inline declaration stub, not the separate complete definition in
`objects/Financing__c/fields/Finance_Exception_Approved__c.field-meta.xml`.
It is **not an LWC import, ListView column or required new approval dependency**.
The nine-member manifest contains no CustomField. Selecting a child ListView causes source
conversion to merge it into a parent CustomObject carrier. The converter also carries the
parent's inline `<fields>` stub and other root settings into `objects/Financing__c.object`, even
though package.xml names only the list view. Salesforce then sees an undeclared field child and
returns `Not in package.xml`.

The mechanism was reproduced **offline**, not through a second failed Salesforce attempt:

```sh
sf project convert source --manifest manifest/d08-presentation-local.xml --output-dir evidence/UAT/FULL_PROJECT_2026-10-28/D08_UNBLOCK/original-mdapi --json
```

`conversion.json` and `original-mdapi/objects/Financing__c.object` retain the converter output:
the same three-line field stub is present along with `NG_Overview`; `original-mdapi/package.xml`
still names exactly nine intended members and no field. This explains the extra component in
the previous validation. Do not add the field to package.xml or alter Finance approvals/FLS.

## 2. Smallest scope-preserving correction

**Packaging-only isolation, not production-source repair.** `prepare_package.py` copies the
converted package into `corrected-mdapi/` and limits all six object carrier files to the one
selected `<listViews>` child. This removes the stray field and excludes unselected parent object
settings (including sharingModel/search layouts/name-field settings) from the payload. Each
selected list view's contents remain equal to its original source definition. All bundle,
dashboard and manifest bytes remain identical to the original conversion. The correction diff
is `package_only_correction.diff`.

Original `force-app/` files, separate approval field definition, source object stub, source
manifest, logic, permissions and earlier user work are **untouched**. This deliberately avoids
cleaning up unrelated historical source or expanding the implementation. The corrected package
is a derived serialization of the exact selected `force-app/` source, not metadata from records.

**Deploy only the validated artifact if approved:**

`evidence/UAT/FULL_PROJECT_2026-10-28/D08_UNBLOCK/d08-corrected.zip`

SHA256:
```text
471ad0f5a72b1710ca1b6d192df8d8b8db78a1448e5a676874a47901d6c915c8
```

Do **not** rerun the original source-manifest deployment command: the original parent stub
remains preserved and that path would reproduce the packaging defect. No Quick Deploy eligibility
is claimed for a NoTestRun validation. Any approval should identify this exact ZIP/hash rather
than authorize deployment of a subsequently regenerated working tree.

## 3. Complete LWC comparison

`compare_bundles.py` fixes the path-collection error with `paths.add(path.relative_to(base))`.
It compares the union of all deployable files in both bundles against the separately retrieved
ng-demo source in `D08_READINESS/org-source/`, with pre-D08/current reviewed repository hashes
also recorded. No retrieval overwrote local work. Receipts: `bundle_comparison.json` and the
complete `org_to_candidate.diff`.

| Complete deployable file | Difference from retrieved ng-demo baseline |
|---|---|
| financeApplication.html | Reviewed D08 single notice binding only, plus terminal newline |
| financeApplication.js | Reviewed `draftNotice` display getter only, plus terminal newline; all load/preview/save handlers/imports unchanged |
| financeApplication.js-meta.xml | Terminal newline only; canonical XML/API/targets/action type equal |
| quoteSummary.html | Reviewed wrapping/table/print-control class changes only, plus terminal newline; financial value bindings unchanged |
| quoteSummary.css | New reviewed D08 component/print styles; absent from retrieved org bundle |
| quoteSummary.js | Terminal newline only; executable text equal |
| quoteSummary.js-meta.xml | Byte-identical |

`prepare_package.py` independently checks the unchanged JS and canonical descriptors, and
compares template/Finance JS bodies after undoing **only** the known D08 presentation edits
in memory. It also checks every previously reviewed production-source/manifest hash. No saved
source was reversed or replaced. Pre-existing repository work does not introduce additional
semantic bundle changes compared with this retrieved live baseline. Earlier differences reported
as byte-unequal are terminal newlines, not functional changes. No scope expansion is needed.

The comparison is against the explicitly requested retrieved snapshot, not an unobserved future
org state. If owner changes deployed source after that snapshot/validation, review drift again
before deployment. In `bundle_comparison.json`, `matchesReviewedD08Source=false` for previously
unchanged files reflects absent entries in the original changed-files hash map, not a new edit;
pre-D08 hash and live content comparison cover those files.

## 4. Updated scope — unchanged nine components

| Type | Exact members |
|---|---|
| LightningComponentBundle | `quoteSummary`, `financeApplication` |
| Dashboard | `NG_Sales/DM_Exec_OperationsOverview` |
| ListView | `Financing__c.NG_Overview`, `Trade_In__c.NG_Overview`, `Delivery__c.NG_Overview`, `Loyalty_Member__c.NG_Overview`, `Loyalty_Transaction__c.NG_Overview`, `Consent__c.NG_Overview` |

Corrected ZIP has 15 files, including package.xml; six child-only object carriers are for the
six ListView members, **not six CustomObject deployments**. No CustomField, Apex, Report,
permission/sharing, site/activation or destructive members. Dashboard source/formulas/type and
all list-view columns remain the original reviewed D08 candidate. Earlier administrative describe
dependencies and no-existing-NG_Overview receipts remain scoped evidence, not persona FLS proof.

## 5. One scoped Salesforce dry-run

Identity receipt `identity.json` returned Organization `00Daj00001Ae3iWEAR`, Developer Edition.
Exact command executed once under this unblock authorization:

```sh
sf project deploy start --dry-run --target-org ng-demo --metadata-dir evidence/UAT/FULL_PROJECT_2026-10-28/D08_UNBLOCK/d08-corrected.zip --single-package --test-level NoTestRun --wait 10 --json
```

`NoTestRun` is appropriate for the exact non-Apex Developer Edition scope and was accepted.
No full suite, Apex tests or coverage was run. Earlier local 14/14 UI-state/static and 4/4
metadata checks were reused, not rerun. Raw new receipt: `validation.json`.

CONFIRMED — raw receipt excerpts:
```json
"checkOnly": true,
"id": "0Afaj00000paFMXCA2",
"numberComponentErrors": 0,
"numberComponentsDeployed": 9,
"numberComponentsTotal": 9,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"status": "Succeeded",
"success": true
```
```json
"componentFailures": []
```
```json
"warnings": []
```

CONFIRMED — raw `final_readiness.json`/postcheck output excerpts:
```json
"unrelatedSemanticBundleChanges": 0,
"candidateSourceFilesChanged": [],
"actualDeploymentPerformed": false,
"browserVerified": false
```

Postcheck verifies exact nine successful component identities, zero errors, successful check-only
status, artifact hash unchanged and all 15 pre-readiness source/manifest hashes unchanged.
The check-only Created/Changed component flags/IDs do not represent persisted deployment.

## 6. Recommendation and owner decision

**READY for owner approval to deploy this exact nine-component corrected ZIP/hash to ng-demo.**
No automatic deployment. Server validation proves compilation/metadata compatibility for this
artifact, not browser readability, print/PDF pagination, actual-reader field access, completed
business workflows or project acceptance. All D08 browser checks and the original functional/
security/data-quality gates remain open. CP2, approvals, FLS, historical records, inactive loyalty
and customer access were not changed. Full-project UAT remains BLOCKED.

Owner approval requested: exact standard deployment of `d08-corrected.zip`, SHA256 above, nine
listed components only. Preserve the same artifact bytes; stop on any new failure or drift.
