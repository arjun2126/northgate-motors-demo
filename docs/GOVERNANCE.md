# Northgate governance and review checklist

## Naming and architecture

- Reuse existing object/field API names, domain services and test conventions. Apex classes use
  PascalCase, LWC bundles camelCase, and existing PS_/PSG_ names remain authoritative.
- Use one entry trigger per object where consolidation is required. `<Object>TriggerHandler`
  routes contexts to existing services. Keep validation before side effects and count maintenance
  before reservation refresh publication. Do not add a transaction-wide run-once flag.
- Preserve each documented bypass boundary; bypasses are not authorization for user-facing APIs.
  Test-drive future-date validation deliberately runs before its hierarchy-setting bypass.
- CP2 pricing, financing identities and accepted lifecycle services remain authoritative. No new
  project-owned Flows. Use native Salesforce features and existing LWC/Apex patterns.

## Review checklist

1. Identify the backlog IDs, actual callers, current handoff and exact changed/deleted components.
2. Review only the bounded diff against the preserved working baseline, including pre-existing
   changes. Avoid unrelated repairs or blanket deployment of this dirty tree.
3. Check CRUD/FLS, sharing and business authorization at trust boundaries. Verify operational
   access with `System.runAs` using the actual persona; administrator access is not persona proof.
4. Check 200-row processing, repeated saves, partial-save retries, transition predicates and
   authoritative cache semantics. Test async work with `Test.stopTest()` in isolation.
5. Run focused checks and affected regressions, including CP2 when shared triggers are involved.
   Include trigger removals atomically in scoped check-only validation with their replacements.
6. Record raw command output, job IDs, selected scope and actual acceptance evidence. Mark
   verification claims CONFIRMED or REFUTED; distinguish deferred checks from passing checks.
7. Stop affected work on unexpected failures or uncertain diagnosis. Report the exact error,
   changed files, last known-good result and the concrete owner action needed. Do not retry
   speculatively or weaken tests to force a pass.

## Deployment and data boundary

Implementation/test/check-only approval is not deployment approval. Use explicit manifests from
`force-app/`, never broad source deployment or data-as-metadata. Only ng-demo is permitted;
never access ng-dev. Destructive manifests require explicit removal scope in deployment approval.
Records, permission assignments, page activation, credentials, platform enablement, publication,
jobs, Git staging/commit/push and other external changes need separate owner authorization.
Never include secrets or personal identity data in source or generated evidence.

## Definition of done

A block is complete only when its actual acceptance criteria have evidence, or the owner explicitly
dispositions a documented exception. Compilation is not browser acceptance; enqueue success is
not event delivery; an assignment snapshot is not usage telemetry. No fabricated screenshots.
Reuse unchanged valid evidence while stating its date/scope; do not describe old tests as rerun.
Every batch records its exact deployable scope, validation result and unresolved gates.

Phase 6 remains OWNER-ACCEPTED WITH DOCUMENTED EXCEPTIONS — October 24, 2026; retain P6-E01–E14.
Batch 1 browser/gallery/event acceptance, operational access/page placement and VIN credentials
remain deferred. Batch 1 is not owner-accepted. See `docs/TECH_DEBT.md` and handoff §38.

This checklist governs Batch 2 review. The backlog and minimal root README link this pack.
The full release/presentation README remains the separately planned P7-20 block.
