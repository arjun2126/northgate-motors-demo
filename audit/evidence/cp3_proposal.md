# CP3 Proposal — Block B (Quote Summary, Approval Process, Permission Set)

**Scope:** Block B per the handoff §3: `Opportunity_Discount_Approval` approval process (deploy with `active=false`), `DiscountApprovalTest`, `QuoteSummaryController` + test, `quoteSummary` LWC, `NG_Quote_Summary` FlexiPage.

**Dependencies satisfied by CP2 completion:**
- 3 Quote fields present (P3-03 deployed).
- 4 Apex classes deployed (P3-04/05 engine + controller + tests).
- `quoteBuilder` LWC deployed.
- `NG_Opportunity_Quote_Builder` FlexiPage deployed and assigned (post-CP2).
- Standard Price Book active (post-CP2).
- §4.2 fixture set present (post-CP2).
- `PS_Sales_Rep` deployed with 3 Quote field FLS (post-CP2).

## Components (Block B)

1. `force-app/main/default/approvalProcesses/Opportunity_Discount_Approval.approvalProcess-meta.xml` — Native approval process on `Opportunity`. `active=false` at deploy. Entry: `Discount_Percent__c > 5`. Step 1: Sales Manager (managerOfSubmitter) for ≤ 10. Step 2: VP_Sales (role) for > 10. Final actions: set `Approval_Status__c` to Approved/Rejected.
2. `force-app/main/default/classes/DiscountApprovalTest.cls` — Tests `Approval.process` submit/approve/reject. **Requires the approval process to be ACTIVE in the org at test-run time.** The test asserts `defs[0].IsActive` on `ProcessDefinition`.
3. `force-app/main/default/classes/QuoteSummaryController.cls` — Read-only summary DTO. Calls `getSummary(quoteId)`.
4. `force-app/main/default/classes/QuoteSummaryControllerTest.cls` — 2 test methods.
5. `force-app/main/default/lwc/quoteSummary/` (3 files: `.js`, `.html`, `.js-meta.xml`) — LWC for Quote record page, displays adjusted subtotal, list subtotal, rules applied, approval status.
6. `force-app/main/default/flexipages/NG_Quote_Summary.flexipage-meta.xml` — FlexiPage for `Quote` record page, hosts `quoteSummary` LWC.

## Approval-Submission Affordance

**Required for Block B end-to-end:** The `quoteBuilder` LWC must include a "Submit for Approval" button that calls `Approval.process` when `Approval_Status__c = 'Pending'`. This is a new `@AuraEnabled` Apex method on `QuoteBuilderController` (e.g., `submitForApproval(quoteId)`).

**Current state:** `quoteBuilder` LWC does NOT have a submit button. The `QuoteBuilderController.createQuote` writes `Approval_Status__c` to `Pending` but does not call `Approval.process`. The `DiscountApprovalTest` calls `Approval.process` directly, bypassing the LWC.

**Proposed addition (local implementation, included in CP3 manifest):**
- Add `@AuraEnabled` method `submitForApproval(Id quoteId)` to `QuoteBuilderController`.
- Add `<lightning-button label="Submit for Approval">` to `quoteBuilder.html`, wired to call `submitForApproval`.
- Add a test method to `QuoteBuilderControllerTest` for `submitForApproval`.

## Activation-Dependent Test Handling

**Problem:** `DiscountApprovalTest` asserts `ProcessDefinition.IsActive` (line 107, 136, 188, 207 in `DiscountApprovalTest.cls`). If the approval process is deployed with `active=false`, these tests will fail.

**Solution:** Exclude `DiscountApprovalTest` from pre-activation test runs. The CP3 deploy runs `RunLocalTests` which would include `DiscountApprovalTest` — this will fail. Two options:

**Option A (proposed):** Deploy with `--test-level NoTestRun` (or omit `--test-level`), then run `sf apex run test --test-level RunLocalTests --code-coverage` after activation. This means the CP3 deploy itself runs no tests; the test run is a separate command.

**Option B:** Deploy with `RunLocalTests` and accept the 4 `DiscountApprovalTest` failures. Run a separate post-activation test run to confirm they pass.

**Option C:** Do not deploy `DiscountApprovalTest` at CP3. Deploy it as a separate action after activation. The test class depends on the process being active.

**Recommendation: Option A.** Deploy metadata without test execution, then run tests after activation. This keeps the deploy and activation as separate, clean steps.

## Dependency-Correct Order

### Step 1: Deploy metadata (no tests)
```
sf project deploy start --manifest audit/evidence/cp3_metadata_manifest.xml --target-org ng-dev
```
- Manifest: `Opportunity_Discount_Approval` (active=false), `DiscountApprovalTest`, `QuoteSummaryController`, `QuoteSummaryControllerTest`, `quoteSummary` (LWC), `NG_Quote_Summary` (FlexiPage), `QuoteBuilderController` (with `submitForApproval` method), `QuoteBuilderControllerTest` (with new test).
- **No tests run** during this deploy.
- **No activation** of the approval process (it deploys as `active=false`).

### Step 2: Activate the approval process
```
sf data update --sobject ApprovalProcess --record-id Opportunity_Discount_Approval --values "active=true" -o ng-dev
```
Or equivalent Tooling API / Metadata API call to set the process active. **This is a separate approval**, not auto-executed with Step 1.

### Step 3: Post-activation test run
```
sf apex run test --test-level RunLocalTests --target-org ng-dev --wait 180 --code-coverage
```
- All `DiscountApprovalTest` methods should now pass (process is active).
- All `QuoteSummaryControllerTest` methods should pass.
- All other tests should continue to pass.

## Components excluded from CP3

- `PS_Sales_Rep` already deployed at CP2 (3 Quote field FLS). Not re-deployed at CP3.
- `PS_Quote_Fields_P3_04` already deployed and assigned at prior checkpoint. Not re-deployed.
- No new permission set changes.
- No fixture changes.
- No page assignment changes (CP2 covers `NG_Opportunity_Quote_Builder`; CP3 deploys `NG_Quote_Summary` as available, assignment is a separate owner-click step).

## Explicit Exclusions

- No Block C reports/dashboard (CP4).
- No P3-02 changes.
- No commits, pushes, tags, or ng-demo changes.
- No broader permission grants.
- No `DiscountApprovalTest` run before activation (Option A avoids pre-activation failure).

## Evidence

- `evidence/P3/p3_03_source_mappings.md` — P3-03 catalog deploy (deploy id `0Afg800000H1av1CAB`).
- `evidence/P3/equity_test.md` — P3-01 equity scenarios (5 cases, owner-reported).
- `evidence/P3/evidence_gaps.md` — Tooling API coverage-data gap (mitigated by `--code-coverage` flag in CLI).
- `audit/evidence/deploy-reports/0Afg800000H5I5lCAF.json` — CP2 successful deploy (76/76 tests, 6/6 components).
- `audit/evidence/test-runs/707g800000oPD2B.txt` — post-deploy coverage (81/81 tests, 92% engine).

**No org commands will be executed until this CP3 proposal is approved.**
