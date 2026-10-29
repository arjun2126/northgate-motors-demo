# Sales Rep UAT Plan — 2026-10-20

**Status: COMPLETE.** Owner browser results are recorded in
`evidence/UAT/live_2026-10-19/REP_UAT_COMPLETED_2026-10-20.md`. The procedure below is a
historical plan; do not rerun setup or save another Quote.

## Purpose

Prepare the remaining Sales Rep browser UAT in `ng-demo` without repeating completed
Manager, VP, or Finance approval decisions.

This plan uses a fresh Opportunity with no Quote, so the first Quote Builder save is
independent of the existing approval records. It also verifies the `P3-DEF-01` guard
after that fix is deployed.

## Current state

- Org: `ng-demo` only, `00Daj00001Ae3iWEAR`.
- Persona: `ngpersona.ngdemo@northgate.demo`, `005aj00000gE0b3AAC`.
- Baseline: role `VP_Sales`, `ManagerId` null, profile `NG_Sales`, no persona PSGs.
- `ngpersona` is the owner of the prepared Account, Contact, and Opportunity.
- Standard Price Book `01saj00000NvczOAAR` is active.
- Vehicle `a0Daj00001D2FPZEA3`: `Available`, Kestrel Sport 2023, 900 days old.
- Product `01taj00000YGzDyAAL`: active `Vehicle_Trim`, list price `50615`.
- Pricing rules in scope: age winner `Aged_Inventory_Discount_90` at 15%; no trim,
  loyalty, or volume rule for this scenario.

## Execution record

- Owner completed Sales Rep browser checks; results and screenshot attestation are
  recorded in `evidence/UAT/live_2026-10-19/REP_UAT_COMPLETED_2026-10-20.md`.
- `scripts/uat/rep_verify.apex` returned `status: PASS`.
- Persona restored to captured baseline: role `VP_Sales`, profile `NG_Sales`,
  `ManagerId=null`, no persona PSGs. Unrelated assignments preserved.
- P3-DEF-01 check-only `0Afaj00000oNfTyCAK` passed 14/14. Deployment
  `0Afaj00000oON8LCAW` succeeded for the two approved Apex classes. Focused run
  `707aj00001McoRy` passed 15/15 results.
- No commit, push, historical data modification, or `ng-dev` access occurred.

## Browser checklist

### A. Quote Builder first save

1. Confirm the logged-in user is `Northgate Persona`, not Arjun.
2. Open the `opportunityUrl` from `REP_UAT_SETUP`.
3. Confirm the Opportunity is owned by Northgate Persona and has no Quote.
4. Open the Quote Builder component.
5. Select buyer `REP UAT Buyer`.
6. Keep category `Vehicle Trims`.
7. Set `Kestrel Sport 2023` quantity to `1`.
8. Click `Save and Price Quote` once.

Expected:

| Field | Expected |
|---|---|
| List subtotal | `50615` |
| Adjusted subtotal | `43022.75` |
| Signed net adjustment | `15%` |
| Rules applied | `1` |
| Rule breakdown | `Aged_Inventory_Discount_90`, Discount 15% |
| Blocker | none |

Do **not** click `Submit for Approval`. This UAT checks pricing and the duplicate guard,
not the already-completed VP approval.

### B. Duplicate-save guard (`P3-DEF-01`)

Do not click Save a second time on persisted UAT Opportunity. Owner did not run this
browser action. Regression is covered by passing
`createQuote_existingQuote_throwsAndLeavesApprovalUntouched`; `rep_verify.apex` confirmed
exactly one persisted Quote and unchanged Opportunity stamps.

### C. Delivery and loyalty UI access

Use the existing controlled records. Do not edit or complete them again.

1. Open Delivery `a03aj00002WPAQYAA5`.
2. Confirm status `Completed`, checklist complete, and buyer
   `003aj00002WPAQXAA5`.
3. Confirm the linked Opportunity is `Closed Won`.
4. Open Loyalty Member `a05aj00000gJUS1AAO`.
5. Confirm member number `NG-4403-0623`, tier `Bronze`, status `Active`.

Owner reported both records opened without error. Delivery tab was visible in the latest
Northgate Sales screenshot; do not deploy another tab permission change without new evidence.

### D. Negative permissions

1. Open a Price Book entry or Product list view.
2. Confirm no New/Edit action is available to the rep.
3. Open a Financing record URL directly only if the browser already has one; otherwise
   skip. Do not create a Financing record.
4. Confirm the rep cannot read Financing fields. If the record is visible, record the
   exact page/field behavior and stop.

## Verification command

`scripts/uat/rep_verify.apex` asserts:

- exactly one Opportunity for seed `UAT-2026-10-20-REP-QUOTE`;
- exactly one Quote and one QuoteLineItem;
- line = 1 × `Kestrel Sport 2023` at `50615`;
- Quote subtotal `50615`, adjusted `43022.75`, one rule applied;
- Opportunity discount `15`, approval status `Pending`;
- Opportunity owner is `ngpersona`;
- Opportunity vehicle and stage unchanged.

A non-`PASS` result means the browser UAT is not accepted. Stop and report the exact
mismatch.

## Stop conditions

- Check-only deploy fails.
- Apex tests fail.
- `rep_setup.apex` fails or finds an existing seed.
- Login As shows the wrong user or profile.
- Quote Builder shows a blocker, wrong pricing, or no duplicate-guard error.
- Any record access failure outside the expected negative checks.
- Persona restore does not return to the baseline.

## Out of scope

- Repeating Manager, VP, or Finance approval decisions.
- Submitting the new Quote for approval.
- Deleting or editing UAT records.
- Phase 5 re-load or reset.
- Commits, pushes, or `ng-dev`.
