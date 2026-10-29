# Sales Rep UAT — 2026-10-20

## Evidence source

Owner reports completion of Sales Rep browser checks and states screenshots confirm
results below. Screenshot files were not attached to the repository during this update;
this record preserves the owner's attestation and observed values.

Org: `ng-demo` (`00Daj00001Ae3iWEAR`)
Persona: `ngpersona.ngdemo@northgate.demo` (`005aj00000gE0b3AAC`), Sales Rep

## Browser results

| Check | Result | Owner-reported observation |
|---|---|---|
| Loyalty Members → All | PASS | More than 50 records displayed. |
| Deliveries → All | PASS | 13 records displayed. Delivery tab visible in Northgate Sales. |
| Pipeline by Stage | PASS | Report opened; 81 Opportunities; `$4,827,766`. |
| Loyalty Tier Distribution | PASS | Report opened; 12 members. |
| `DM_DealDesk` dashboard access | PASS | Dashboard opened and rendered three metrics. |
| `DM_DealDesk` metric accuracy | UNVERIFIED | All displayed values were zero; accuracy not established. |
| Delivery 12 record access | PASS | `a03aj00002WPAQYAA5` opened; status Completed. |
| Loyalty Member 70 record access | PASS | `a05aj00000gJUS1AAO` opened; status Active; tier Bronze. |
| Rep Quote pricing | PASS | Quote `00000069` persisted with CP2 pricing: subtotal `50615`, adjusted subtotal `43022.75`, one rule. |

The prior live report metadata shows `PG_All_Sales` has View access to report and
dashboard folders. Owner confirms report/dashboard UI access passed.

## Nonblocking note

Loyalty Tier Distribution report description is outdated. Record as cleanup; it does not
block Sales Rep UAT acceptance.

## P3-DEF-01 result

Scoped check-only `0Afaj00000oNfTyCAK` passed 14/14 tests. Deployment
`0Afaj00000oON8LCAW` succeeded for the two approved Apex classes. Focused run
`707aj00001McoRy` passed 15/15 results (14 methods plus `setup`). Regression test
`createQuote_existingQuote_throwsAndLeavesApprovalUntouched` passed. Owner did not perform
a second live save; persisted UAT still has exactly one Quote and one QLI, verified by
`scripts/uat/rep_verify.apex`. No approval was submitted.
