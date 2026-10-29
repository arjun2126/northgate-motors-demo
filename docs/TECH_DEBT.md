# Tech Debt — known deliberate limitations

Recorded so each item is a visible decision rather than a hidden gap.

## Round-robin is per-transaction only

**Component:** `force-app/main/default/classes/LeadRoundRobin.cls` (+ handler use in `LeadRoutingHandler.onAfter`).

**Spec:** Backlog P2-01 says "round-robin within rooftop"; `DATA_MODEL` §8 documents `Lead.Assigned_Batch__c` as a "Round-robin audit" field.

**Current behaviour:** rotation state is a static map, so the lane index rotates only inside one
transaction. Sequential individual Lead saves each produce the same slot label (e.g.)
`M5V2T6` to Northgate Downtown gives `M-R1` on the first save and `M-R1` again on the next,
not the intended alternation.

**Not verified:** cross-transaction rotation. Do not record it as working.

**Status:** open design decision, separate from the P2-01 test correction. FSA routing and
in-transaction rotation are verified; rotation across sequential saves is not.

**Fix options when prioritized:**
1. Custom counter object per rooftop updated under `SELECT ... FOR UPDATE`, so concurrent saves serialize.
2. Increment a stored counter in a hierarchy custom setting and fall back to queue on contention.

Option 1 is the safer pattern. If neither is scheduled, this stays an owner decision.

**Not a gap:** all six `LeadRoutingHandlerTest` methods pass, and a real save is confirmed
(`M5V2T6` → Northgate Downtown → Sales Rep → `M-R1`).

## Service visit slot overlap

**Components:** `TestDriveBookingGuard.cls`; historical DATA_MODEL §5.5 and the earlier
TempDataForming reference are design history, not current service-capacity implementation.

**Limitation:** the test-drive guard checks same-batch and persisted time overlaps without an
exclusive vehicle lock. Concurrent transactions can both pass before either booking commits.
No universal concurrency guarantee is claimed. Owner: project owner; disposition: retained demo
limit. Revisit when strict concurrent test-drive exclusion becomes a requirement.

**Superseded claim:** Phase 6 service visits use `ServiceVisitCapacityGuard`, which locks rooftops
and enforces daily capacity in America/Toronto. This is daily admission, not time-slot/resource
overlap scheduling. Multi-session acceptance remains P6-E02; do not replace accepted capacity
with the historical slot-overlap proposal. Evidence: P6 owner acceptance P6-E02/P6-E12.

## Source provenance is not a polymorphic foreign key

**Location:** `Loyalty_Transaction__c.Source_Reference__c`, DATA_MODEL §5.4,
`LoyaltyLedgerService.cls`, `docs/architecture/SIMULATION_LOYALTY.md`.
The Text(80) field is provenance, not uniqueness or referential integrity. Concrete Opportunity/
Service_Visit lookups and managed Event_Key/Request_Key contracts serve their distinct purposes.
Do not infer historical provenance or repair the 110 historical transactions/72 member balances.
Owner: project owner; disposition: accepted P6-E06. Revisit for a real polymorphic-reporting or
historical reconciliation requirement with separately approved data migration.

## Derived caches and scale limits

**Location:** `VehicleCounters.cls`, `TestDriveCounters.cls`, DATA_MODEL §5.3.
Vehicles_On_Hand counts every linked Vehicle, regardless of status. Inventory_Age_Days is already
a formula; there is no deployed Vehicles_Aged_60 rooftop field in current source. Older scheduled
Flow/counter names are design history, not proof of active jobs. TestDriveCounters currently
counts completed drives for vehicles in the invocation scope, not every vehicle of each model;
it does not handle delete/undelete. Preserve this accepted behavior rather than silently change
it during trigger consolidation. Owner: project owner; disposition: known limitations; revisit
on a separately approved counter-definition change. Aggregate/query-row and concurrent cache
updates remain bounded demo behavior, not a production throughput or serialization guarantee.

## History, SLA and operational throughput

**Location:** `CaseEscalationStampBatch.cls`, history controllers, `LoyaltyLedgerService.cls`,
`NurtureAudienceService.cls`, and `evidence/P6/PHASE6_OWNER_ACCEPTANCE_2026-10-24.md`.
History visibility/retention, best-effort escalation stamps, query-row/governor ceilings, source
cutoffs and atomic-failure limits remain P6-E03/E04/E06/E07/E11/E13. No silent truncation or
universal race/production-throughput guarantee. Owner: project owner; disposition: accepted
exceptions. Revisit only when measured volume, missing events or operational activation justify
an explicitly approved durable/reconciliation strategy.

## Inventory refresh is not a durable business integration

**Location:** `VehicleReservationEventPublisher.cls`, `inventoryGallery`,
`docs/architecture/EVENTS_CDC_PUBSUB.md`.
After-commit refresh events contain no customer data. Publish failures are log-only and do not
invalidate reservations; no durable outbox or guaranteed external delivery exists. Manual refresh
is the fallback. Owner: project owner; revisit if refresh delivery becomes business-critical.
Batch 1 browser/gallery/event acceptance, operational access and VIN credentials remain deferred;
the deployed batch is not owner-accepted.

## Permission usage and native capability gates

**Location:** `scripts/tests/audit_p7_batch2.py`, `evidence/P7/BATCH2_PERMISSION_TERRITORY_AUDIT.json`.
Assignments/group membership provide a snapshot, not permission usage telemetry. An unassigned
set may be a group member, deferred feature dependency or loader-only tool; never revoke it
automatically. The earlier missing-Territory-object gate was cleared after owner enablement:
`evidence/P7/P7_12_READ_ONLY_REVERIFICATION.md` confirms all four objects and the enabled setting.
Batch 2 now deploys one Planning model/shared type/four siblings; actual readback persists
Read/None/None/None with zero Account/User associations (`evidence/P7/BATCH2_DEPLOYMENT.md`).
Owner: project owner; P7-12 still requires approved mapping, access/membership, activation and
actual tree/persona acceptance. The existing Contact Edit default was not changed or inherited.
No substitute or unapproved configuration/assignment change was made.

## Evidence/release and deferred access

**Location:** handoff §38, Phase 5 exceptions and P6-E01/E05/E08/E09/E10/E14.
Dirty/untracked source is not a reproducible clean release. Isolated tests do not establish live
personas, browser presentation, Knowledge publication, positive CSI samples or inactive loyalty
processing. Owner: project owner; retained acceptance/activation decisions require their own
authorization and evidence. Review with `docs/GOVERNANCE.md`; do not weaken release checks.
