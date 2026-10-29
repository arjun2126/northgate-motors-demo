# P7-05/P7-06 — reservation events and CDC/Pub-Sub seam

## Actual implementation

Vehicle_Reserved__e is a native high-volume Platform Event with PublishAfterCommit behavior.
The deployed Batch 2 VehicleTriggerHandler after-update path calls VehicleReservationEventPublisher
after counter maintenance through the single VehicleTrigger entry point. This preserves Batch 1's
call/order; obsolete VehicleCounterTrigger was removed atomically in the authorized Batch 2 deployment.
No third Vehicle trigger or Flow was added. Events are built only for a
transition into Reserved/changed reserver with a non-null timestamp; neutral edits and releases
do not publish reservation events. Payload contains Vehicle Id and reservation time, no Contact,
financial values or consent. It is a refresh hint, never authority to reserve or expose a record.

The gallery subscribes with lightning/empApi (new messages, replay -1), refreshes through USER_MODE
queries and releases subscriptions on disconnect, including a late subscription completion.
It refreshes its own reservation immediately without a page reload and retains a manual Refresh
path if streaming is unavailable. The read-only gallery cannot infer a successful save from an
event alone or use event payload to mutate another row.

The gallery permission set includes native event Create/Read for its approved publisher/subscriber,
not direct Vehicle Edit. Existing legacy writers must not acquire new notification permissions
merely to keep their accepted reservation behavior: enqueue failures are counted/logged and do
not roll back an otherwise valid reservation. Event delivery after enqueue is not guaranteed by
the application; use manual refresh. No durable outbox, callback retry or external consumer exists.

## Evidence boundary

Tests prove the minimal payload builder, 200-record trigger/counter path, no neutral-update
events, legacy writer compatibility and failure reporting. Client state tests prove stale-response
protection, explicit refresh and subscription cleanup. Native after-commit metadata compiles.
These do not establish multi-session browser delivery, reconnect-gap recovery or production
throughput. No page activation, subscription as a live user or persistent test reservation occurred.

## CDC and external Pub/Sub

No Change Data Capture object was enabled. CDC would represent underlying row changes rather
than this business-specific reservation hint. No external Pub/Sub API client, replay checkpoint,
integration user, managed credentials or external transport was configured. Replay retention,
subscriber identity, deduplication, limits and privacy require explicit design/approval before an
external consumer is introduced. Source-of-truth reads still enforce the caller's data access.
Native Platform Events are real metadata; the VIN provider remains a mock, and licensed stock
photos are separately deployed. Browser/gallery/event acceptance, operational access and VIN
credentials remain deferred; Batch 1 is not owner-accepted. None is a functioning CDC integration.
