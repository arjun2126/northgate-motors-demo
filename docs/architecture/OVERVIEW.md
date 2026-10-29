# Architecture overview — navigation, not redesign

## Existing system

Northgate implements the dealership lifecycle on standard Salesforce Lead, Account, Contact,
Opportunity, Quote/QuoteLineItem, Product2/PricebookEntry and Case, with custom inventory,
test-drive, financing, delivery, service, loyalty, consent and entitlement objects.
Metadata source is `force-app/`; records are data, not deployment source.
See the [data model](../../DEMO_ORG_DATA_MODEL.md) and
[current handoff](../../NORTHGATE_PROJECT_HANDOFF.md) for detailed field/service history.

| Boundary | Existing direction / authoritative detail |
|---|---|
| Automation | Thin triggers/handlers → existing domain guards/services; no new project-owned backend Flows. Preserve accepted appraisal screen Flow and native approvals/rules. [Automation direction](AUTOMATION_DIRECTION.md), [governance](../GOVERNANCE.md) |
| Pricing/quotes | Custom CPQ simulation on standard Quotes; CP2 primary Vehicle_Trim basis, signed discounts/premiums and authoritative server pricing. Existing one-Quote guard prevents overwriting approval state. [CPQ seam](SIMULATION_CPQ.md), [current UAT](../../evidence/UAT/FULL_PROJECT_2026-10-28/UAT_REGISTER.md) |
| Financing/delivery | Existing calculator/rate/application/lifecycle/approval services; checklist-gated delivery, Closed Won and eligible idempotent enrollment. Finance approval state is separate from Opportunity discount approval. [Finance seam](SIMULATION_FINANCE.md) |
| Service/loyalty/consent | Toronto-day capacity, intake Case linkage; custom ledger/redemption/tiering/expiry and independent consent. Operational activation is not implied by deployed code. [Field Service](SIMULATION_FIELD_SERVICE.md), [loyalty](SIMULATION_LOYALTY.md), [nurture](SIMULATION_NURTURE.md) |
| Owner Portal | Experience Cloud + LWC; server-resolved identity and Contact scope. Privileged Vehicle broker checks current entitlement on every request; native customer Vehicle/Model/ledger CRUD and Visit Create stay denied. [Portal](EXPERIENCE_PORTAL.md), [ownership ledger](P8_CONTACT_VEHICLE_OWNERSHIP.md), [broker amendment](P8_NATIVE_VEHICLE_ACCESS_DECISION.md) |
| Inventory/events/integration | Existing gallery, reservation event and VIN mock transport. No claim that credentials, multi-session delivery or external subscribers are operational. [Integration seam](SIMULATION_INTEGRATION.md), [events](EVENTS_CDC_PUBSUB.md) |
| Security/reporting | Permission sets/groups, CRUD/FLS, record sharing and actual-persona checks. Lookup groupings require target-object Read; folder shares/running user need live evidence. [Permission matrix](../security/PERMISSION_MATRIX.md), [audit](../security/P7_PERMISSION_AUDIT.md) |

## Continuity and expansion

[Decision status](../decisions/STATUS.md) indexes ratified decisions; it does not supersede them.
The [current register](../../evidence/UAT/FULL_PROJECT_2026-10-28/UAT_REGISTER.md) retains pending
portal loyalty/comments, security certification and operational acceptance. Preserve owner-positive
dashboard/vehicles/booking/history/My Cases paths without calling Phase 8 complete.

Vehicle Studio remains the [backlog's](../../DEMO_ORG_BACKLOG.md) post-Phase-8 proposal: prepared
assets first, optional 3D later, approved CP2 handoff rather than a second pricing engine.
Staff Workspace is not authorized implementation. Neither proposal permits changing current
security, native-vs-simulation seams or ratified automation.

The local [validation entry point](../../harness/check.sh) adds regression navigation and offline
checks; it neither changes runtime architecture nor connects to an org.
