# P7-14 — Field Service seam

This build uses custom Service_Visit__c and Test_Drive__c, not licensed Salesforce Field Service.
Standard Case, queues, native escalation/entitlements/milestones and reports are real Salesforce
features; custom service history, intake and capacity logic do not make them a Field Service install.

ServiceVisitCapacityGuard locks rooftops and counts consuming visits by America/Toronto day.
It enforces daily capacity, including move/release/partial-save semantics, not technician skill,
travel-time or overlapping resource appointments. ServiceIntakeCaseService creates/links a
Service Case in Q_Service_Intake for eligible new visits. History controllers enforce their
accepted access/pagination boundaries. Native SLA uses the approved business-hours calendar,
not a universal elapsed-hours clock. P6-E02/E03/E04/E11/E12/E13 remain acceptance limits.

TestDriveBookingGuard checks future dates and persisted/same-batch vehicle overlaps; future-date
validation remains active under the hierarchy bypass. Its overlap query is not an exclusive
vehicle scheduling lock. Follow-up tasks/notifications and existing model counters remain domain
services behind the consolidated trigger handler, not a resource-dispatch system.

Licensed Field Service adds work orders, service appointments/resources/territories, skills,
dispatch optimization, travel and mobile/offline execution. No package, optimization service,
mobile rollout, auto-dispatch, scheduling job or paid product is introduced here. Sales Territory
NG_Rooftops is an unrelated Planning-state sales-sharing model, not Field Service territory setup.

Future integration must map Contact/Account/Vehicle identity, authoritative booking states,
timezone/calendar, idempotency, capacity versus resource contention and narrow permissions before
any new write. Preserve current intake, service history, approvals and consent; do not replace
accepted services or add a Flow fallback. Real browser/concurrency/resource behavior needs its
own approval and evidence, not an architecture note or administrator-only test.
