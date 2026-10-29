# P3-01 Trade-In Deferred Checks — 2026-10-20

## Status

These checks are explicitly deferred, not passed and not failed. They are **not** Phase 5
data-load blockers. Run them only before a demo that shows the Trade-In Appraisal flow, and
only with owner authorization for a Sales Manager persona switch.

## Prerequisites

- Deploy and activate flow `Trade_In_Appraisal` (`Active`, v4) in the target org.
- Confirm `Trade_In_Calc_Equity` and its four tests pass.
- Switch `ngpersona` to `manager` with `scripts/persona.sh manager`.
- Use an Opportunity and Contact that the manager can read and edit. A fresh
  admin-created Opportunity and Contact owned by `ngpersona`, or explicitly shared to
  `ngpersona`, avoids a visibility failure that would look like a flow defect.
- Do not change an existing `Trade_In__c` or approve anything.

## Browser checks

### 1. Manager persona access

1. Login As `ngpersona`; confirm role `Sales_Manager_Airport` and `PSG_Manager`.
2. Open the prepared Opportunity and Contact.
3. Launch `Trade_In_Appraisal` from the Opportunity or the flow launcher.
4. Confirm the flow opens without a permission error.

### 2. Input and review screens

1. Enter vehicle year, make, model, VIN, odometer, structural-damage flag, appraisal
   amount, and payoff amount.
2. Continue to `Review Appraisal`.
3. Confirm the review screen shows the same vehicle values, appraisal, payoff, and equity.
4. Capture the review screen with the equity value visible.

### 3. Saved record

1. Finish the flow.
2. Record the saved `Trade_In__c` ID from the confirmation screen.
3. Open the saved record as the same manager.
4. Confirm:
   - `Status__c = Appraised` (not `Accepted`);
   - `Appraisal_Amount__c` and `Payoff_Amount__c` match the inputs;
   - `Trade_Equity__c = Appraisal_Amount__c - Payoff_Amount__c`;
   - `Appraised_By__c` identifies the Sales Manager;
   - `Appraisal_Date__c` is populated;
   - the Opportunity and Contact links match the inputs.
5. Query the Opportunity for `Trade_In__c` count. Expected: exactly one new record for
   this run, identified by the returned ID.

### 4. Record evidence

Write the record ID, input values, saved values, and screenshot path to
`evidence/P3/equity_test.md` under a new dated section. Mark each check PASS or FAIL.
Do not edit the earlier owner-reported results.

## Stop conditions

- Manager cannot open the prepared Opportunity or Contact.
- Flow opens as the wrong user or role.
- Review screen or saved record has different values.
- `Status__c` is `Accepted`.
- `Appraised_By__c` is blank or not the manager.
- More than one `Trade_In__c` is created for the run.

Stop and report the exact screen, field, and record ID.
