# P7-12 — native territory capability gate

## Current status — reverified 2026-10-26 UTC

The owner enabled Sales Territories through Setup. Read-only settings retrieve confirms
enableTerritoryManagement2=true; all four required objects are exposed and SOQL-queryable.
Models/types/territories and Account/User association inventories are empty. The earlier
capability blocker below is cleared, not P7-12 acceptance. Configuration, assignment, activation,
sharing/persona decisions and rendered-tree evidence remain outstanding and unauthorized.
Current evidence/actions: `P7_12_READ_ONLY_REVERIFICATION.md` and
`P7_12_TERRITORY_REVERIFICATION.json`. No successful Batch 2 tests were repeated.

## Historical pre-enablement audit

The authorized read-only audit queried the expected ng-demo Organization ID and ran the native
global object inventory through `sf sobject list --sobject all --target-org ng-demo --json`.

CONFIRMED — raw audit projection:

```json
{
  "requiredObjects": ["ObjectTerritory2Association", "Territory2", "Territory2Model", "Territory2Type"],
  "exposedObjects": [],
  "missingObjects": ["ObjectTerritory2Association", "Territory2", "Territory2Model", "Territory2Type"],
  "configurationChanges": 0,
  "accountAssignments": 0,
  "renderedTreeAcceptance": "NOT VERIFIED",
  "disposition": "BLOCKED: required native territory objects are not exposed; owner capability disposition required."
}
```

This establishes unavailable API capability in the current authenticated context, not a claim
that the feature can never be licensed/enabled. No territory metadata, substitute sharing
implementation, four synthetic territory records or Account assignments were created.

Owner action: inspect Setup > Territory Settings in ng-demo, confirm whether Sales Territories
is available/enabled, and either disposition P7-12 as deferred/unavailable or separately authorize
the capability/configuration decision. Do not enable the feature under check-only authorization.
If supported later, the approved design remains four rooftop-aligned native territories with
explicit Account mapping, rendered-tree evidence and no unintended access widening. Inactive
metadata alone would not pass that acceptance.
