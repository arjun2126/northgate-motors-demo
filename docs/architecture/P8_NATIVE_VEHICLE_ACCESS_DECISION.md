# One secure alternative for exact ownership-expiry enforcement

**Deployed (§71):** approved model shipped in exact Quick Deploy `0Afaj00000pPottCAC` (34/34,
zero errors), reusing the validated 43 tests. Native customer Vehicle/Model/ledger access and Visit
Create remain denied; no native Vehicle shares or reconciliation job needed for broker expiry.
Ledger empty, reviewer unassigned, portal unpublished; operational customer acceptance pending.
Evidence: `evidence/P8/BROKER_DEPLOYMENT/RESULT.md`. Local-only status below is historical.

**Approved and locally implemented (handoff §70):** owner approved this broker model. Check-only
`0Afaj00000pPiV7CAK` Succeeded, 34 components, 43/43 Apex tests; local UI tests 25/25. P8-05/07
source complete, not deployed/operationally accepted. Native Vehicle/Model/ledger CRUD and Visit
Create remain denied. No schedule is needed for broker expiry checks. Exact scope/security/results:
`evidence/P8/BROKER_COMPLETION/RESULT.md`, `manifest/p8-broker-local.xml`. Decision-pending text
below is historical and is not a request to approve this same architecture again.

Status: decision required, NOT implemented. The local ledger/reconciler now validates, but no
customer Vehicle grant, portal feature enablement, job activation or live configuration is approved.
Evidence: `evidence/P8/OWNERSHIP_RECOVERY/verification.json`.

## Established limitation

An Apex-managed Vehicle share is a native record grant, not a time-conditional ownership policy.
Explicit termination can remove application-owned grants synchronously, and reconciliation now
tests removal at a supplied expiry instant without editing ledger data. However, a sharing reason
or managed recalculation is not a clock-triggered access predicate. Salesforce Scheduled Apex/
Batch execution has no demonstrated hard start/completion deadline in this project. Until the
cleanup runs, a stale share remains a native grant if the user has Vehicle object/field access.
Preserving unrelated shares also means the ledger cannot subtract access those sources provide.
No source change can honestly make eventual cleanup an exact-expiry native API guarantee.

Current secure state is retained: customers have no Vehicle object access. Actual Plus runAs
tests deny a known foreign Vehicle read even when a deliberately misaddressed app share exists;
that is proof of the disabled native-access posture, NOT positive owned-Vehicle portal acceptance.

## Single recommended alternative: server-mediated Vehicle/booking capabilities

1. Keep external Vehicle, Vehicle Model and ownership-ledger object CRUD inaccessible. Keep
   Service_Visit Create/Edit/Delete unavailable externally. Do not introduce direct customer
   Vehicle shares, blanket record access, a permissive profile or an API Enabled workaround.
   Existing Contact-specific history/Case/loyalty USER_MODE read paths remain unchanged.
2. Resolve caller through the existing Foundation on EVERY request: exact active Plus identity,
   custom permission, own Contact/Account and exact Live Network. Never accept customer identity
   or ownership assertions supplied by a client.
3. Add a minimal, explicitly privileged Vehicle capability broker behind that with-sharing
   facade. It checks ALL current ledger ownership rows for conflicts and exact Contact, verified
   evidence and half-open effective/revocation times. Only then read the exact Vehicle in system
   mode and return a whitelist DTO (approved identity/year/colour/model and validated existing
   static-resource photo path). No raw SObject, arbitrary query, invoice/pricing/reservation/
   customer/finance/evidence fields or unbounded inventory enumeration.
4. Vehicle reads are authorized at request execution, never from a cached entitlement token.
   Expired/missing/ambiguous/revoked ownership produces no DTO. Prior delivered browser data
   cannot be remotely erased; logout/cache behavior requires actual-persona UAT, not a claim
   that revocation retracts already downloaded content.
5. Booking requires both current Ownership and independent Service_Authorization. Lock the
   Vehicle in the same order/path as revocation and recheck those predicates immediately before
   the write. Derive Contact, owner/routing, Requested status and allowed fields on the server.
   The tightly scoped broker inserts the permitted Visit explicitly in system mode because
   external native Create stays denied. Reuse existing ServiceVisitTrigger capacity/locking and
   intake Case/link behavior; no new Flow or second booking process. Add a durable per-customer
   idempotency contract and bind retries to the same canonical request payload.
6. Native REST/UI API bypasses are denied by absent object CRUD, independently of a clock job.
   Explicit ledger revocation remains synchronous for any legacy application grants; periodic
   pruning is defense-in-depth only, not the customer authorization boundary. Audit unrelated
   permission sets/native grant sources before enabling this broker; grant no customer generic
   Apex entry point or administrative entitlement-review capability.

## Exact decision / impact

Approve or decline this server-mediated model as the specific amendment to the current requirement
for USER_MODE Vehicle reads/appointment insertion. It introduces a privileged, tightly bounded
customer capability broker, not general CRUD/FLS bypass, and cannot be silently substituted for
the approved native sharing design. Do not relax expiry timing or enable Vehicle rights instead.

If approved, finish P8-05 list/detail/photos and P8-07 wizard/booking against that broker, with
actual Plus A/B and same-Account negatives, missing/future/expired/conflicting/revoked ownership,
separate service authority, foreign-ID and payload tampering, native read/write denial, financial
field exclusion, concurrency/idempotency, and affected capacity/intake regression. Validate the
frozen changed scope before a separate deployment decision. Real identities/page placement/site
publication/customer UAT remain separately authorized operations. No broker source or deployment
is included in the current validated ledger-only candidate.
