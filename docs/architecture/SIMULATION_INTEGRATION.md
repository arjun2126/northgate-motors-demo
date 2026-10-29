# P7-14 — Integration seam

The native pieces are Apex HttpRequest/HttpCalloutMock, Platform Events with PublishAfterCommit,
USER_MODE refresh queries and LWC lightning/empApi subscription. These are real platform APIs,
not an installed MuleSoft integration or a functioning external CDC/Pub/Sub consumer.

VinDecoderService is a read-only simulation preview. VinValidator remains the checksum authority;
the optional local Python mock provider returns explicitly fictional values. NG_VIN_Mock Named/
External Credential/principal and reachable-host setup remain absent/deferred. No VIN, model,
image path, price or customer record is enriched. API_CONTRACT.md defines the bounded request,
schema, timeout/error and no-retry/no-write behavior. Loopback provider tests do not prove a live
Salesforce callout or a real manufacturer decoder.

VehicleTriggerHandler invokes VehicleReservationEventPublisher after counter maintenance. A
successful reservation transition can enqueue a Vehicle_Reserved__e refresh hint with vehicle
ID/time only. It is not authority to reserve/read another row. Publish failures are log-only;
manual refresh remains the fallback. No durable outbox, external consumer, replay checkpoint or
universal delivery guarantee exists. Batch 1 browser/gallery/event acceptance remains deferred.

CDC is not enabled. No integration-user creation, credentials, tunnel, subscriber, scheduler,
paid endpoint, external data export or message delivery occurred. A future native/external seam
needs explicit identity/CRUD/FLS, payload/PII, auth/secrets, retries/idempotency, replay/retention,
limits and observability decisions. Consent previews do not authorize outbound marketing.

Contracts: docs/integration/API_CONTRACT.md and EVENTS_CDC_PUBSUB.md. Deployment/check-only receipts
are not remote-transport or operational-persona acceptance. Batch 2 preserves the reservation/
event behavior while consolidating entry points; it does not resolve the live credential or
browser gates. No completed pricing/finance/service/loyalty flow is redesigned for this seam.
