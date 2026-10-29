# Quote Summary security validation

## Scope

Local repair and `ng-demo` check-only validation of Quote Summary user-mode queries and narrowly scoped Quote Builder/Quote Summary access. No deployment, persistent data write, permission assignment, role change, or sharing change is authorized or performed. Test-created records and permission assignments exist only inside rolled-back Apex tests.

## Files in this change

- `force-app/main/default/classes/QuoteSummaryController.cls`: add `WITH USER_MODE` to Quote, QuoteLineItem, and Opportunity SOQL. Place the clause before `ORDER BY` in the line query. Preserve DTOs, arithmetic, and null behavior.
- `force-app/main/default/classes/QuoteSummaryControllerTest.cls`: retain existing administrator regression tests; add authorized workflow/legacy-rep tests, exact-field denial scenarios for all three queries, object denial, unshared-record denial, stored-null behavior, and full-stack CP2 pricing assertions under the narrow permission set.
- `force-app/main/default/permissionsets/PS_Quote_Workflows.permissionset-meta.xml`: additive, quote-scoped permissions. No existing permission set is edited.

## CONFIRMED — live access evidence

Queries use `--target-org ng-demo --json`. The following are raw returned record excerpts, with REST `attributes` omitted.

`User` query:

```json
{"Id":"005aj00000gE0b3AAC","ProfileId":"00eaj00000TnZaFAAV","Profile":{"Name":"NG_Sales"},"UserRole":{"DeveloperName":"VP_Sales"},"IsActive":true}
{"Id":"005aj00000feqbNAAQ","Profile":{"Name":"System Administrator"},"UserRole":null,"IsActive":true}
```

`PermissionSetAssignment WHERE AssigneeId = '005aj00000gE0b3AAC'` (all returned assignments):

```json
{"Id":"0Paaj000016Ty3HCAS","PermissionSetId":"0PSaj00000gE0RPGA0","PermissionSet":{"Name":"X00eaj00000TnZaFAAV"},"PermissionSetGroupId":null}
{"Id":"0Paaj000016dBqzCAE","PermissionSetId":"0PSaj00000gKc49GAC","PermissionSet":{"Name":"NG_Lightning_Experience_Access"},"PermissionSetGroupId":null}
```

The live browser actor is not currently assigned PS_Sales_Rep or PSG_Rep. The two effective sets have no access to either controller. The live PS_Sales_Rep grants QuoteBuilderController but not QuoteSummaryController. Administrator profile grants both:

```json
{"ParentId":"0PSaj00000eq3ikGAA","SetupEntityId":"01paj00000bRxC1AAK","SetupEntityType":"ApexClass"}
{"ParentId":"0PSaj00000eq3ikGAA","SetupEntityId":"01paj00000bRxC5AAK","SetupEntityType":"ApexClass"}
{"ParentId":"0PSaj00000gDl7UGAS","SetupEntityId":"01paj00000bRxC1AAK","SetupEntityType":"ApexClass"}
```

`ObjectPermissions` restricted to the persona's two sets and Quote, QuoteLineItem, Opportunity, Product2, Pricebook2, PricebookEntry returned only:

```json
{"ParentId":"0PSaj00000gE0RPGA0","SobjectType":"Opportunity","PermissionsRead":true,"PermissionsCreate":true,"PermissionsEdit":true,"PermissionsViewAllRecords":false,"PermissionsModifyAllRecords":false}
```

The missing Quote object grant explains the direct Quote list denial. A hidden tab is not the demonstrated cause:

```json
{"ParentId":"0PSaj00000gE0RPGA0","Name":"standard-Quote","Visibility":"DefaultOn"}
```

Live PS_Sales_Rep already grants Quote/Product2/Pricebook2 Read, Quote Create/Edit, and Read on all seven permissionable fields queried by Quote Summary: Quote.Adjusted_Subtotal__c, Quote.Rule_Applied_Count__c, Quote.Quote_Valid_Until__c, Quote.GrandTotal, Product2.Category__c, Opportunity.Discount_Percent__c, Opportunity.Approval_Status__c. Administrator profile provides base-object access and Quote.GrandTotal Read; assigned PS_Demo_Admin provides the six custom-field reads. Permissionable relationship fields required by Quote Builder are included in the new set. Describe output identifies Quote.OpportunityId, QuoteLineItem.Product2Id/QuoteId/Quantity/UnitPrice, Product2.Name, Opportunity.Name, Vehicle__c.Vehicle_Model__c, Vehicle_Model__c.Name, and Loyalty_Member__c.Contact__c as `permissionable: false`; no FLS entries are added for those fields. QuoteLineItem/PricebookEntry access follows their parent permissions.

## CONFIRMED — baseline quote fields explain the blank metrics

The owner's administrator browser observation is the baseline UI evidence, not a new post-fix UI result. Querying the matching quote by grand total returned:

```json
{"Id":"0Q0aj000003jGGbCAM","QuoteNumber":"00000001","OpportunityId":"006aj00000fUIstAAG","GrandTotal":121565,"Adjusted_Subtotal__c":null,"Rule_Applied_Count__c":1,"Quote_Valid_Until__c":"2026-10-31","Opportunity":{"Discount_Percent__c":null,"Approval_Status__c":"Not_Required"}}
```

Its two line items returned:

```json
{"Quantity":1,"UnitPrice":81043,"TotalPrice":81043}
{"Quantity":1,"UnitPrice":40522,"TotalPrice":40522}
```

The seed CSV header has no Adjusted_Subtotal__c column; the existing seeded quote is not proof that Quote Builder computed a rules result. Quote Summary returns stored Adjusted_Subtotal__c and Opportunity.Discount_Percent__c directly. Blank values are expected for these stored nulls; no CP2 recalculation or data backfill is justified. The stored rule count alone does not establish a calculated result.

## Proposed permission scope

PS_Quote_Workflows grants only:

- Apex access to QuoteBuilderController and QuoteSummaryController, plus Price_Rule__mdt access.
- Quote Read/Create/Edit, no Delete. QuoteLineItem access follows Quote.
- Read only on Product2, Pricebook2, Vehicle__c, Vehicle_Model__c, and Loyalty_Member__c.
- Explicit Opportunity Read for Salesforce's Quote permission dependency, added with owner approval after the first failed validation. No Opportunity Create/Edit/Delete/View All/Modify All grant.
- The 18 permissionable fields used by the existing Builder/Summary read/write paths. Only seven field grants are editable: the two Opportunity pricing/approval stamps and five Quote input/result fields (ExpirationDate, Buyer_Contact__c, Adjusted_Subtotal__c, Quote_Valid_Until__c, Rule_Applied_Count__c).

It relies on existing Account/Contact Read and Opportunity Edit. Opportunity Read is redundant for the captured live persona, which already has it. It grants no Account/Contact object expansion, Delete, View All, Modify All, invoice-cost access, financing access, bypass, role change, sharing change, or tab change. Private records still require existing record access. Assignment is a separate owner approval action; the file alone changes no persona.

## Validation

### REFUTED — scoped validation passed

Command executed:

```sh
sf project deploy start --target-org ng-demo --dry-run \
  --source-dir force-app/main/default/classes/QuoteSummaryController.cls \
  --source-dir force-app/main/default/classes/QuoteSummaryControllerTest.cls \
  --source-dir force-app/main/default/permissionsets/PS_Quote_Workflows.permissionset-meta.xml \
  --test-level RunSpecifiedTests \
  --tests QuoteSummaryControllerTest QuoteBuilderControllerTest QuotePricingServiceTest QuoteTradeInGuardTest QuoteTriggerEnforcementTest \
  --wait 10 --junit --results-dir evidence/QUOTE_SECURITY --json
```

Raw Salesforce response excerpts:

```json
{"checkOnly":true,"id":"0Afaj00000oZwypCAC","status":"Failed","success":false,"numberComponentErrors":8,"numberTestErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"rollbackOnError":true}
{"fullName":"QuoteSummaryController","componentType":"ApexClass","success":true}
{"fullName":"QuoteSummaryControllerTest","lineNumber":313,"columnNumber":34,"problem":"Variable does not exist: SObjectType","success":false}
{"fullName":"QuoteSummaryControllerTest","lineNumber":327,"columnNumber":33,"problem":"Variable does not exist: SObjectType","success":false}
{"fullName":"QuoteSummaryControllerTest","lineNumber":331,"columnNumber":46,"problem":"Initial expression is of incorrect type, expected: Schema.SObjectField but was: Decimal","success":false}
{"fullName":"QuoteSummaryControllerTest","lineNumber":331,"columnNumber":46,"problem":"Initial expression is of incorrect type, expected: Schema.SObjectField but was: Decimal","success":false}
{"fullName":"QuoteSummaryControllerTest","lineNumber":331,"columnNumber":46,"problem":"Initial expression is of incorrect type, expected: Schema.SObjectField but was: Date","success":false}
{"fullName":"QuoteSummaryControllerTest","lineNumber":331,"columnNumber":46,"problem":"Initial expression is of incorrect type, expected: Schema.SObjectField but was: Decimal","success":false}
{"fullName":"QuoteSummaryControllerTest","lineNumber":367,"columnNumber":33,"problem":"Variable does not exist: SObjectType","success":false}
{"fullName":"PS_Quote_Workflows","problem":"Permission Read Quote depends on permission(s): Read Opportunity","success":false}
```

No Apex tests ran. Zero reported test errors does not mean tests passed. Only the controller compiled successfully within this failed check-only transaction; no metadata was deployed.

### Stop and owner escalation

Work stopped after the first check-only failure, as required by repository AGENTS.md. No speculative repair or retry followed.

Corrections proposed at that stop, subsequently approved and applied in the next section:

1. Qualify schema tokens in the added tests using `Schema.SObjectType.Quote` and `Schema.SObjectType.Quote.fields.<field>` so the local `quote` variable cannot shadow the object token. Audit the other new object/field tokens for the same collision.
2. Add explicit Opportunity Read to the quote-scoped permission set to satisfy the platform dependency, without Create/Edit/Delete/View All/Modify All grants. The live persona already has Opportunity Read, so this is redundant effective access for that persona. The test-created restricted permission sets must satisfy the same Quote dependency.
3. Rerun this exact check-only command after owner approval of those corrections. Preserve the restricted-field assertions and CP2 expected values.

At that stop, the permission metadata and tests were not deployable. No deployment approval was requested while validation failed.

## Owner-approved correction attempt

The owner approved qualifying the schema references, adding explicit Opportunity Read to PS_Quote_Workflows and the restricted-test permission sets, and rerunning the same scoped check-only command. No existing permission set or pricing component was edited.

Applied changes in this attempt:

- `QuoteSummaryControllerTest.cls`: namespace object/field describe references with `Schema.SObjectType`; add Opportunity Read to each of the three test-created limited sets. Assertions and CP2 expected values are unchanged.
- `PS_Quote_Workflows.permissionset-meta.xml`: add a four-line Opportunity object permission entry with Read true and Create/Edit/Delete/View All/Modify All false. It now has seven object entries, eighteen field entries, and two Apex class entries.
- `QuoteSummaryController.cls`: unchanged in this correction attempt; the three user-mode clauses from the original security change remain.

### REFUTED — approved retry passed

The exact command in the Validation section ran again. Raw Salesforce response excerpts:

```json
{"checkOnly":true,"id":"0Afaj00000oYaCNCA0","status":"Failed","success":false,"numberComponentErrors":10,"numberTestErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"rollbackOnError":true}
{"fullName":"QuoteSummaryController","componentType":"ApexClass","success":true}
{"fullName":"PS_Quote_Workflows","componentType":"PermissionSet","success":true}
{"fullName":"QuoteSummaryControllerTest","lineNumber":332,"columnNumber":46,"problem":"Initial expression is of incorrect type, expected: Schema.SObjectField but was: Schema.DescribeFieldResult","success":false}
{"fullName":"QuoteSummaryControllerTest","lineNumber":356,"columnNumber":9,"problem":"Method does not exist or incorrect signature: void assertFieldDenied(String, Schema.DescribeFieldResult) from the type QuoteSummaryControllerTest","success":false}
{"fullName":"QuoteSummaryControllerTest","lineNumber":361,"columnNumber":9,"problem":"Method does not exist or incorrect signature: void assertFieldDenied(String, Schema.DescribeFieldResult) from the type QuoteSummaryControllerTest","success":false}
{"fullName":"QuoteSummaryControllerTest","lineNumber":366,"columnNumber":9,"problem":"Method does not exist or incorrect signature: void assertFieldDenied(String, Schema.DescribeFieldResult) from the type QuoteSummaryControllerTest","success":false}
{"runTestResult":{"numFailures":0,"numTestsRun":0,"totalTime":0,"codeCoverage":[],"successes":[]}}
```

The line 332 error occurred seven times, once for each field in the list; the helper argument error occurred at the three listed call sites. The schema rewrite returns DescribeFieldResult values while the list and helper require SObjectField values. This is an error in the new local test code, not evidence of a pricing or persona runtime defect.

The controller and permission metadata passed component validation in this transaction. Because `checkOnly` is true, the reported permission-set creation is temporary validation state, not a deployed permission set. Zero tests executed; no coverage or passing test result is claimed.

Work stopped again after this failure. No further source repair, retry, deployment, or persistent assignment followed. Remaining proposed local correction: obtain actual SObjectField tokens for the seven list entries and three helper arguments (for example, explicitly convert each DescribeFieldResult with `getSObjectField()`), preserving all denial assertions and pricing expected values. Owner approval is needed before another repair/retry under the repository escalation policy.

### Last verified state and deployment dependencies

- Latest raw response accepts the controller and the approved Opportunity Read dependency. The test class does not compile.
- Local XML validation returned `xml: valid`, `classAccesses: 2`, `objectPermissions: 7`, `fieldPermissions: 18`, and `noDeleteOrAllRecordsGrants: true`. `git diff --check` exited zero.
- Deployment remains blocked until the test class compiles and the five specified suites pass check-only validation.
- Once validated, a future request must separately authorize deploying exactly the controller, test class, and new permission set, then assigning only PS_Quote_Workflows to the owner-designated persona (`005aj00000gE0b3AAC` if the same live browser actor is intended). No PSG_Rep, PS_Sales_Rep, role, or sharing change is required by this proposed assignment. No such deployment/assignment is requested for execution while validation is failing.
