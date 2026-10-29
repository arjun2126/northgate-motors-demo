# Northgate Motors — consent and nurture simulation seam

P6-13. This build is a custom consent/audience simulation, not Marketing Cloud, Account
Engagement, Journey Builder or a message delivery service. Batch 3 deployed as
`0Afaj00000p19YXCAY`; this document does not authorize messaging or opt-in changes.

## Actual implementation

`Campaign.Nurture_Managed__c` defaults false. Managed Campaigns explicitly name a supported
consent Purpose/Channel. `ConsentGateService` and the thin Consent, Campaign, CampaignMember
and Contact triggers require an existing exact-tuple grant before managed membership insertion.
Missing/future grant dates, expired/revoked records, a revocation date or conflicting deny rows
prevent eligibility. Email opt-out also prevents Email eligibility. Leads do not inherit Contact
consent. Unmanaged historical Campaigns retain their previous behavior.

Consent changes, deletion, undelete, reparenting, policy changes and Contact Email opt-out
re-evaluate retained membership. Suppression changes derived eligibility, not CampaignMember
Status or membership history. A stored `Nurture_Eligible__c` value is an administrative snapshot,
not permission to send. Calendar-based expiry can make a snapshot stale without a DML event.

`NurtureAudienceService.preview` is uncached. Every invocation checks the custom permission,
USER_MODE Campaign/member/Contact access and fresh internal consent decisions. Its 200-candidate
cursor can return an empty eligible page with `hasMore=true`; callers must continue using
`nextId`, not infer completion from eligible row count. Hidden Contacts are filtered, and no raw
consent/evidence/email values are returned. Campaign Active FLS is read-only. Internal consent
queries use SYSTEM_MODE; Contact locks serialize relevant membership/consent writes.

No message sender, journey enrollment, schedule, tracking pixel, subscriber synchronization,
deliverability system, preference center, external portal or unsubscribe endpoint exists. No new
Flow was added. Bulk refresh fails atomically at governor limits rather than silently truncating
suppression; high fan-out is not a production throughput guarantee.

## Licensed-product boundary and future integration

Marketing Cloud supplies subscriber identities, channel delivery, suppression synchronization,
journey state, send deduplication, frequency policies and delivery/engagement tracking. Those are
not simulated by a CampaignMember row. A future sender must independently recheck consent and
access immediately before enqueue/send, enforce an idempotency key and handle revocation between
selection and delivery. Preview results are not a durable authorization token.

Use explicit Contact identity and purpose/channel mapping at the integration boundary. Preserve
deny precedence, retention and narrow access. Do not infer permission from account membership,
loyalty enrollment or an old audience export. Consent semantics are demonstration policy, not
proof of legal compliance. Production retention, identity, volume and race policies need an
approved architecture and security review before any real delivery integration.

## Evidence and deferred acceptance

`evidence/P6/BATCH3_EXECUTION_2026-10-24.md` records isolated grants/denials, revocation,
reparenting, partial saves, hidden Contacts, denied actors, pagination and no email invocation.
Live persona/browser use and any Campaign opt-in, assignments, sender or scheduling require
separate authorization. No end-to-end message delivery or Marketing Cloud integration is claimed.
