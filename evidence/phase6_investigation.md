# Phase 6 Critical-Function Investigation — Evidence Summary

Investigation scope: read-only review of ng-demo (source of truth: `force-app/main/default`) for Test Drive booking, CP2 pricing, delivery/loyalty chain, consent enforcement, and security. No source changes were made except the documented local fix recommendation.

---

## 1. TEST DRIVE BOOKING

### Source inspected
- `force-app/main/default/flows/TestDrive_Book_Screen.flow-meta.xml`
- `force-app/main/default/triggers/TestDriveTrigger.trigger`
- `force-app/main/default/classes/TestDriveBookingGuard.cls`
- `force-app/main/default/classes/TestDriveBookingGuardTest.cls`
- `force-app/main/default/objects/Test_Drive__c/validationRules/VR_TestDrive_EndAfterStart.validationRule-meta.xml`
- `force-app/main/default/objects/Test_Drive__c/Test_Drive__c.object-meta.xml`
- `force-app/main/default/permissionsets/PS_Test_Drive_Booking.permissionset-meta.xml`
- `force-app/main/default/permissionsets/PS_Sales_Rep.permissionset-meta.xml`
- `docs/planning/P2_BROWSER_UAT_PROCEDURE_2026-10-20.md` (procedure references `/flow/TestDrive_Book_Screen`)
- `evidence/UAT/MANAGEMENT_TESTDRIVE_UAT_2026-10-21.md` (live FlowDefinition record)

### Launch mechanism
- **CONFIRMED**: The active screen flow is `TestDrive_Book_Screen`.
- No Lightning App Builder, Quick Action, LWC, or custom-button reference to the flow exists in source metadata (grep across `*.flexipage-meta.xml`, `*.quickAction-meta.xml`, `*.js-meta.xml`, `*.layout-meta.xml`, `*.app-meta.xml` returned none).
- Procedure doc and UAT evidence specify direct URL launch: `/flow/TestDrive_Book_Screen`.
- Live org query for PermissionSet returned both `PS_Sales_Rep` and `PS_Test_Drive_Booking` (`sf data query` result).

### Minimum Sales Rep permissions needed
- `RunFlow` user permission (granted by `PS_Test_Drive_Booking`).
- Flow access to `TestDrive_Book_Screen` (granted by `PS_Test_Drive_Booking`).
- Object CRUD on `Test_Drive__c`: Create + Read + Edit (sales rep books and later updates drives).
- Object Read on `Vehicle__c` and `Contact` (lookups in the flow screen).
- Object Read/Create on `Opportunity` only if the rep will link a drive to an opportunity; the flow itself only populates `Contact__c`, `Vehicle__c`, `Scheduled_Start__c`, `Duration_Minutes__c`, and `Status__c`.
- FLS on `Test_Drive__c` fields used by the flow: `Vehicle__c`, `Contact__c`, `Scheduled_Start__c`, `Duration_Minutes__c`, `Status__c`. `Scheduled_End__c` is a formula and read-only.
- `PS_Sales_Rep` already contains all of the above.

### Conflict prevention
- **Flow-level soft check**: `Existing_Booking` lookup filters by `Vehicle__c`, overlapping interval, and `Status__c` = `Requested` OR `Scheduled`. Overlap routes to the `Conflict` screen.
- **Trigger-level hard check**: `TestDriveTrigger` (before insert/update) calls `TestDriveBookingGuard.guard`, which blocks overlapping `Requested`/`Scheduled` bookings for the same vehicle and also cross-checks against existing records.
- **Validation rule**: `VR_TestDrive_EndAfterStart` ensures `Scheduled_End__c > Scheduled_Start__c`.
- No Salesforce Duplicate Rule or unique field enforces slot uniqueness; the Apex guard is the data-layer enforcement.

### Test evidence
- Targeted ng-demo test run: 73 methods, 0 failures, outcome `Passed` (run id `707aj00001MvzBH`).
- `TestDriveBookingGuardTest` covers overlap blocked, adjacent allowed, cancelled does not block.

### Defects
- None confirmed for Phase 2 booking functionality.

---

## 2. CP2 PRICING

### Source inspected
- `force-app/main/default/classes/QuotePricingService.cls`
- `force-app/main/default/classes/QuoteBuilderController.cls`
- `force-app/main/default/classes/QuoteSummaryController.cls`
- `force-app/main/default/classes/QuoteTradeInGuard.cls`
- `force-app/main/default/triggers/QuoteTrigger.trigger`
- `force-app/main/default/objects/Quote/validationRules/VR_Quote_NoQuoteWithoutOpp.validationRule-meta.xml`
- `force-app/main/default/objects/Vehicle__c/validationRules/VR_Vehicle_PriceFloor.validationRule-meta.xml`
- `force-app/main/default/customMetadata/Price_Rule__mdt/*.md-meta.xml` (10 active rules)
- Test classes: `QuotePricingServiceTest`, `QuoteBuilderControllerTest`, `QuoteSummaryControllerTest`, `QuoteTradeInGuardTest`, `QuoteTriggerEnforcementTest`

### Regression evidence
- Existing evidence: `evidence/FINAL/full_suite/test-result-707aj00001MTeI1-junit.xml` contains 171 `<testcase>` elements with zero failures in that artifact.
- Fresh targeted ng-demo run: 73 methods, 0 failures (`707aj00001MvzBH`).

### Confirmed defect
- **QuoteSummaryController.getSummary does not use `WITH USER_MODE`**.
  - File: `force-app/main/default/classes/QuoteSummaryController.cls`, lines 26–65.
  - The SOQL selects `Quote.GrandTotal`, `Opportunity.Discount_Percent__c`, and `Opportunity.Approval_Status__c` without `WITH USER_MODE`. Although the class is `with sharing`, Apex SOQL defaults to system mode for FLS. If a persona's FLS were removed, the controller would still expose those fields.
  - `QuoteBuilderController` and `QuotePricingService` already use `WITH USER_MODE` consistently.
  - **Local fix**: add `WITH USER_MODE` to the two SOQL statements in `getSummary`:
    - Quote query: `FROM Quote WHERE Id = :quoteId WITH USER_MODE`
    - Opportunity query: `FROM Opportunity WHERE Id = :quote.OpportunityId WITH USER_MODE`

### Other observations (not confirmed defects)
- `Fixed_Adjustment__c` on `Price_Rule__mdt` is not consumed by `QuotePricingService`; all active rules use `Percent_Adjustment__c` = 0, so current calculations are correct.
- `QuoteTrigger` fires only `before insert`; it does not re-evaluate trade-in requirements on quote update.

---

## 3. DELIVERY AND LOYALTY

### Source inspected
- `force-app/main/default/triggers/DeliveryTrigger.trigger`
- `force-app/main/default/classes/DeliveryCloseService.cls`
- `force-app/main/default/triggers/OpportunityTrigger.trigger`
- `force-app/main/default/classes/OpportunityStageStamp.cls`
- `force-app/main/default/classes/LoyaltyEnrolmentService.cls`
- `force-app/main/default/objects/Delivery__c/validationRules/VR_Delivery_ChecklistBeforeCompleted.validationRule-meta.xml`
- `force-app/main/default/objects/Opportunity/validationRules/VR_Opportunity_ClosedWonNeedsDelivery.validationRule-meta.xml`
- `force-app/main/default/classes/DeliveryCompletionGuardTest.cls`
- `force-app/main/default/classes/LoyaltyEnrolmentServiceTest.cls`

### Chain verification
- `DeliveryTrigger` (after insert/update) calls `DeliveryCloseService.handleCompleted`.
- `handleCompleted` filters for records moving to `Status__c = 'Completed'` and with a related `Opportunity__c`.
- It stamps `Completed_Date__c`, updates the related `Opportunity` to `StageName = 'Closed Won'` and `Delivery_Completed__c = true`, increments `Contact.Lifetime_Vehicles_Owned__c`, and calls `LoyaltyEnrolmentService.enrolOnDelivery`.
- `VR_Opportunity_ClosedWonNeedsDelivery` ensures Closed Won requires `Delivery_Completed__c = true`; the trigger sets both fields, so the validation rule passes.
- `VR_Delivery_ChecklistBeforeCompleted` ensures all four checklist fields are true before status can become Completed.

### Test evidence
- `DeliveryCompletionGuardTest`: 4 methods passed in fresh ng-demo run.
- `LoyaltyEnrolmentServiceTest`: 4 methods passed.

### Confirmed gaps
- **No end-to-end Apex test** asserts that inserting/updating a `Delivery__c` to Completed drives `Opportunity.StageName = 'Closed Won'` and creates a `Loyalty_Member__c`. The components are individually tested but not the trigger chain.
- `DeliveryCloseService` is `public without sharing`; this is functional today but broadens record access beyond the initiating user.

---

## 4. CONSENT REVOCATION

### Source inspected
- `force-app/main/default/objects/Consent__c/Consent__c.object-meta.xml`
- `force-app/main/default/objects/Consent__c/fields/*.field-meta.xml`
- `force-app/main/default/objects/Consent__c/validationRules/VR_Consent_RevokedRequiresDate.validationRule-meta.xml`
- Grep across Apex classes, triggers, and Flows for `Consent__c` / `consent` returned no references.

### Findings
- `Consent__c` supports `Granted`, `Revoked`, and `Expired` statuses plus `Channel__c` and `Purpose__c`.
- `VR_Consent_RevokedRequiresDate` enforces that a `Revoked` record has a `Revoked_On__c` date.
- Reports exist (`Revoked_Consents`, `Revoked_Consent_Campaign_Members`) for reporting, but no automation gates campaign membership, email sends, or other communication entry points on consent status.

### Confirmed gap
- **Revoked consent is not enforced anywhere.** There is no trigger, flow, or Apex class that checks `Consent__c.Status__c = 'Revoked'` before adding a Contact to a campaign or before any communication action.

---

## 5. SECURITY

### OWD / sharing model (source)
- `Account`, `Contact`, `Opportunity`: `Private`
- `Quote`: `ControlledByParent`
- `Vehicle__c`, `Test_Drive__c`, `Delivery__c`, `Loyalty_Member__c`: `ReadWrite`
- `Consent__c`: `Private`

### Permission recommendations (do not expand beyond current persona sets)
- **Test Drive booking**: `PS_Test_Drive_Booking` + `PS_Sales_Rep`. Current `PS_Sales_Rep` already provides the minimum object/FLS needed.
- **CP2 pricing as-is**: `PS_Sales_Rep` (plus `PS_Sales_Manager` for approvers). No additional object or sharing access is required.
- **Delivery/loyalty chain**: `PS_Sales_Rep` provides Edit on `Delivery__c` and `Opportunity`, Create on `Loyalty_Member__c`, and Read on `Vehicle__c`/`Contact`. Finance officer persona receives Read on deals plus `Loyalty_Member__c` Create/Edit via `PS_Finance_Officer`.
- **Consent enforcement (future)**: any consent gate will need at least Read on `Consent__c` for the running persona. No consent-related permissions are currently assigned to sales personas, which is correct because the enforcement does not yet exist.

### Security defect
- `QuoteSummaryController` SOQL bypasses FLS (see CP2 defect above). This is the only confirmed permission-boundary gap.

---

## Consolidated approval request

**Requesting approval to deploy one local source change:**

- File: `force-app/main/default/classes/QuoteSummaryController.cls`
- Change: add `WITH USER_MODE` to the two SOQL queries in `getSummary` so that field-level and object permissions are enforced for the quote summary LWC.
- No other deployments, permission assignments, sharing changes, or data writes are requested.

---

## Remaining critical blockers before Phase 6

1. **Consent gate is unimplemented.** A design decision is needed for P6-12 (Consent_Gate_Flow / ConsentTrigger) before campaign-membership automation can be built and tested.
2. **No end-to-end delivery/loyalty trigger test.** Add at least one test that inserts a completed `Delivery__c` and asserts `Opportunity.StageName = 'Closed Won'` plus `Loyalty_Member__c` creation.
3. **QuoteSummaryController FLS gap** must be fixed before Phase 6 pricing/security sign-off.

*Evidence collected in this file and in the fresh ng-demo test run output (run id `707aj00001MvzBH`).*
