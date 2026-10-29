# Northgate Motors — Loyalty Management simulation seam

P6-10. This is a custom demonstration, not Salesforce Loyalty Management and not a financial
liability ledger. Batch 2 deployed as `0Afaj00000oya5SCAQ`; its program remains inactive.
No processing, schedule, historical repair or permission assignment is authorized by this note.

## Implemented custom behavior

`LoyaltyEnrolmentService`/existing Delivery automation retain Active/Bronze/zero enrollment,
including late buyer and replacement exclusions. `LoyaltyAccrualBatch` observes post-cutoff
Completed Service Visits and Delivered sales without changing accepted source triggers.
`LoyaltyAccrualService` resolves authoritative source records; `LoyaltyLedgerService` serializes
member/source/lot access, assigns unique event hashes and commits ledger/lot/member changes
atomically with savepoint rollback. Posted source changes require manual review, not repricing.

`LoyaltyTierEvalBatch` evaluates stored lifetime spend from metadata, records current/previous
tier and most recent transition, with upgrades only by default and configurable downgrade.
`RedemptionService` requires operator permission plus USER_MODE membership access before narrow
internal writes. Repeated request tokens cannot spend twice; debits consume earliest-expiring
managed lots. `Loyalty_ExpiryBatch` debits only unspent eligible lots, strictly after expiry date
using Toronto dates. Scheduler delegates are code only; no jobs are activated.

Owner-approved demonstration defaults: service 1 point/CAD, sale 0.10/CAD, floor after multiplier;
Bronze 0/1/365, Silver 5000/1.25/365, Gold 25000/1.5/540, Platinum 50000/2/730
(lifetime CAD threshold/multiplier/expiry days); CAD 0.01/point display value. Source bases are
service Total Cost and Opportunity Amount, not settled invoices or payment proof. Rates, tiers,
expiry, point value, rollout and downgrade behavior are configurable metadata. `Is_Active=false`
blocks monetary operations. The provisional cutoff is not authorization to activate processing.

## Preserved historical limitations

The planning baseline had 72 members with stored balance total zero and 110 historical
transactions netting 17,370 points; source references and expiry dates were absent. No historical
provenance, spend, lot remainder or balance was reconstructed. Only newly managed lots are
spendable/expirable. Stored balances and historical transaction sums are not interchangeable.
Managed-record guards protect engine values; existing trusted loading bypass remains privileged.
Tier evidence records the latest transition, not every historical transition. Accrual polling
uses current state/source-created cutoff and cannot prove actual payment/completion chronology.

## Reporting and licensed-product differences

Batch 3 loyalty dashboard values stored points at configured point value; this is a demonstration
estimate, not accounting valuation, cash entitlement or proof of a reconciled ledger. Its fixed
running user is intentionally privileged, so folder visibility is restricted to Service management
and the primary administrator. Drill-through still requires actual report/object/FLS access.
Service operations remains viewer-scoped; no operational data is granted to the VP as a workaround.

A licensed Loyalty Management implementation adds program/currency models, promotions and
partner settlement, transaction journals and formal adjustments, benefit/voucher catalogs,
qualifying-period policies, omnichannel processing and richer audit/reconciliation. This custom
build provides none of those licensed features, cash handling, tax, payment, Quote repricing,
external customer access or production throughput guarantees. Consent/nurture gates are a separate
simulation and do not authorize marketing messages. No new project-owned Flow is introduced.

Tests establish isolated math, replay, bulk and rollback behavior, not multi-session race freedom,
licensed persona/browser acceptance or scheduled operation. Those acceptance gates remain explicit.
