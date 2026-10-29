# P3-DEF-01 — QuoteBuilderController overwrite defect

**Status:** Deployed to `ng-demo` on 2026-10-20. Check-only passed, deployment succeeded,
and focused `QuoteBuilderControllerTest` passed. Backlog item `P3-DEF-01` is implemented.

## Incident

On 2026-10-20 at 02:40:27Z, a second Quote was created for Opportunity
`006aj00000faIjZAAU` with 1 × `Aurelia EX 2026` (subtotal 33,607). The pricing
result was a 1.00% net discount. `QuoteBuilderController.createQuote` then
stamped the Opportunity as `Discount_Percent__c = 1.00` and
`Approval_Status__c = Not_Required`.

The original Quote `0Q0aj000003kJNhCAM` (8.92%, 2 rules) and its pending
approval `04gaj000001yDbJAAU` were untouched. The approval page reads the live
Opportunity fields, so the manager saw 1.00% instead of 8.92%.

## Root cause

`force-app/main/default/classes/QuoteBuilderController.cls` inserts a new Quote
on every `createQuote` call and then, after pricing, always writes the result to
the Opportunity:

```apex
Opportunity stamp = new Opportunity(Id = opp.Id);
stamp.Discount_Percent__c = result.netDiscountPercent;
stamp.Approval_Status__c = result.netDiscountPercent > MANAGER_APPROVAL_THRESHOLD ? 'Pending' : 'Not_Required';
updateUserMode(stamp);
```

There is no guard for:

- an existing Quote on the Opportunity,
- a pending approval on the Opportunity,
- a pricing blocker (`result.blockerMessage != null`); the Quote update is
  skipped in that case but the Opportunity is still stamped.

The application assumes one Quote of record per Opportunity, but nothing
enforces that assumption.

## Proposed fix

Reject a second Quote before any DML, and stamp only when pricing succeeded.
This keeps the existing one-Quote-per-Opportunity behaviour and makes the
pending approval immutable from Quote Builder saves.

```diff
@@
     if (lines == null || lines.isEmpty()) {
         throw new IllegalArgumentException('At least one product line is required.');
     }
 
+    Integer existingQuoteCount = [
+        SELECT COUNT()
+        FROM Quote
+        WHERE OpportunityId = :opportunityId
+        WITH USER_MODE
+    ];
+    if (existingQuoteCount > 0) {
+        throw new IllegalArgumentException(
+            'This Opportunity already has a quote. Only one quote is allowed per Opportunity.'
+        );
+    }
+
     Opportunity opp = [
         SELECT Id, Name, AccountId, Vehicle__r.Vehicle_Model__r.Name, Vehicle__r.Vehicle_Model__r.Trim__c,
             Vehicle__r.Inventory_Age_Days__c
@@
         if (result.blockerMessage == null) {
             quote.Adjusted_Subtotal__c = result.adjustedSubtotal;
             quote.Rule_Applied_Count__c = result.rulesApplied;
             updateUserMode(quote);
+
+            Opportunity stamp = new Opportunity(Id = opp.Id);
+            stamp.Discount_Percent__c = result.netDiscountPercent;
+            stamp.Approval_Status__c = result.netDiscountPercent > MANAGER_APPROVAL_THRESHOLD ? 'Pending' : 'Not_Required';
+            updateUserMode(stamp);
         }
-
-        Opportunity stamp = new Opportunity(Id = opp.Id);
-        stamp.Discount_Percent__c = result.netDiscountPercent;
-        stamp.Approval_Status__c = result.netDiscountPercent > MANAGER_APPROVAL_THRESHOLD ? 'Pending' : 'Not_Required';
-        updateUserMode(stamp);
 
         return wrapper;
     }
```

### Why block on an existing Quote

- It prevents duplicate Quote records from a repeated Save.
- It covers the incident path: the second Quote cannot be created, so the
  pending 8.92% approval cannot be overwritten.
- It avoids querying `ProcessInstance` under `WITH USER_MODE`, which may not be
  readable by every Quote Builder persona.
- If the business later needs multiple quotes per Opportunity, the guard should
  be replaced by an explicit primary/quote-of-record field or lookup; the
  Opportunity stamp must then read only that quote.

## Regression tests

1. `createQuote_existingQuote_throwsAndLeavesApprovalUntouched`
   - Create the first Quote.
   - Set the Opportunity to `8.92` / `Pending` to simulate the protected approval.
   - Call `createQuote` again.
   - Assert `IllegalArgumentException`.
   - Assert `Discount_Percent__c` and `Approval_Status__c` are unchanged.
   - Assert exactly one Quote exists for the Opportunity.
2. `createQuote_blocker_doesNotStampOpportunity`
   - Force an ambiguous vehicle basis.
   - Assert the Opportunity fields are unchanged.
3. Existing happy-path tests must keep passing, including the 19.85% stamp and
   `Not_Required` below-threshold stamp.

## Validation and deployment

- Static analysis completed 2026-10-20: 62 findings (25 Moderate, 37 Low),
  no critical or high findings.
- First check-only job `0Afaj00000oOEWUCA4` ran while no active `VP_Sales` user existed;
  13/14 tests passed. `submitForApproval_above10ResolvesVpApprover` failed at line 439
  with `System.QueryException: List has no rows for assignment to SObject`. No source was
  deployed by that check-only.
- After owner browser UAT and baseline restore, active `ngpersona` was verified as
  `VP_Sales`. Exact two-class check-only `0Afaj00000oNfTyCAK` succeeded; 14/14 tests
  passed.
- Exact two-class deployment `0Afaj00000oON8LCAW` succeeded. Deployment test run passed
  14/14 tests; no component failures.
- Focused standalone run `707aj00001McoRy` passed 15/15 results (14 test methods plus
  `setup`); 0 failures.
- `scripts/uat/rep_verify.apex` returned `REP_UAT_VERIFY` status `PASS`: exactly one
  Opportunity, Quote, and QLI; subtotal `50615`, adjusted subtotal `43022.75`, one rule;
  Opportunity stamp `15` / `Pending`.
- Rollback: redeploy the previous class version; no org data migration is
  involved.

## Design decision

One Quote per Opportunity is the accepted demo model. This matches the
documented acceptance criteria and the existing Quote Builder behaviour. No
multi-Quote regression is required. Historical duplicate Quote records are
preserved; there is no data cleanup in this change.

If multiple quotes are required later, replace the guard with an explicit
primary/quote-of-record lookup and read the Opportunity stamp only from that
quote.
