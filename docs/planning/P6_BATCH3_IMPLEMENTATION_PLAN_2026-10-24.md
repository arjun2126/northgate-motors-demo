# Phase 6 Batch 3 — bounded local execution plan

Owner authorizes P6-09–P6-12 local implementation, tests and exact check-only as one batch.
Target ng-demo / 00Daj00001Ae3iWEAR only. No deployment, records, live assignments, schedules,
page activation or Git publication. Batch 2 deployed as 0Afaj00000oya5SCAQ and remains inactive.

## File-level plan and routine decisions

- P6-09: new Service/Loyalty report types, reports and narrowly shared folders; new
  viewer-scoped DM_Service_Operations and fixed-user DM_Loyalty_Operations. Reuse native report
  conventions. Loyalty liability is stored balance times the approved configurable point value,
  not a historical-ledger reconstruction. Existing reports/dashboards remain untouched.
- Live inventory has four LoggedInUser dashboards, contrary to the old three-slot assumption.
  Prepare the required dynamic Service dashboard and let scoped validation establish eligibility;
  never delete or change an existing dashboard to free a slot. Quota failure blocks only that part.
- P6-10: SIMULATION_LOYALTY.md documents actual custom engines, source provenance, atomicity,
  active gate, historical limitations and differences from licensed Loyalty Management.
- P6-11: native Contact report with completed-Service and open-Opportunity buyer cross-filters.
  Use Quote.Buyer_Contact__c, the accepted explicit buyer path: live ContactRole count is zero
  but 60 open-Opportunity Quotes have an explicit buyer. Do not infer identity from Account.
  An additive Quote formula exposes open-Opportunity qualification for native cross-filter use;
  it does not reprice or alter existing Quote values. A small USER_MODE query service/test
  establishes the report's semantic/security reference. Signal means coexisting service/open
  opportunity, not proof of chronology, purchase intent, payment or a second completed sale.
- P6-12: opt-in Campaign metadata (default unmanaged) declares exact consent Purpose/Channel.
  Managed CampaignMember insertion requires an existing valid exact-tuple grant, no matching
  deny and no Email opt-out. Consent rows with Revoked/Expired, missing/future grant dates or
  a revocation date deny; deny wins conflicting rows. No consent creation, historical enrollment,
  email/SMS sending or nurture scheduler. Revoke/delete/expire/policy/opt-out changes suppress
  retained memberships rather than deleting history. Fresh audience reads recheck consent and
  accessible Contacts; stored eligibility is an administrative snapshot, never authority to send.
  Opt-in means existing unmanaged campaigns/seed BAD fixtures retain original behavior.

Implementation: consent service plus thin Consent/Campaign/CampaignMember/Contact triggers;
custom permission and narrow audience-reader set (local metadata only); native membership audit
report; focused consent, bulk, partial-save, security and reporting-access tests. No new Flow,
custom dashboard LWC or change to loyalty/CP2/Delivery/Service Visit production code.

## Transaction and security rules

Serialize relevant consent/membership work on Contact parents. Before member inserts, reject
unconsented managed rows with generic errors. Re-evaluation uses sparse internal membership
updates; it updates derived eligibility, not CampaignMember Status or existing Consent history.
All refresh DML is atomic and no errors are swallowed. Large fan-out remains subject to normal
governor limits and must fail clearly; never truncate a suppression set. Audience API requires
custom permission, USER_MODE Campaign/member/Contact reads and fresh internal tuple checks.
No raw private consent/evidence/email values are returned. No actual messages are sent.

## Coordinated validation

Test deny/missing/future/revoked/wrong tuple/Email opt-out/Leads, 200 members, partial-success
inserts and retry, consent update/delete/undelete/reparent, policy changes, retained suppression,
unmanaged legacy isolation, denied actor, role-scoped service access and stored-balance formula.
Run Batch 1/2 regression test sources in the same explicit package only where new triggers/formula
interactions justify them; include local test source. Validate native report/dashboard references
and runtime quota through exact manifest. No live report refresh, schedule or test data.

Browser rendering, advisor/manager comparison, fixed-user summary visibility, runtime audience
usage, new campaign opt-in, permissions and any data acceptance require owner authorization.
Never describe earlier deferred Batch 1/2 live acceptance as passed. Final evidence records actual
request IDs, failures, coverage and remaining gates. Do not begin P6-13 or later Batch 4 scope.
