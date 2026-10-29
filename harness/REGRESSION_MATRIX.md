# Salesforce regression matrix

This maps **existing** checks; names are not proof of execution or complete coverage. Preserve
the original criteria in the [current register](../evidence/UAT/FULL_PROJECT_2026-10-28/UAT_REGISTER.md)
and its [phase/lane map](../docs/planning/UAT_ORCHESTRATION.md). No new application tests invented.

## Validation levels and approvals

| Level | Entry / scope | Boundary |
|---|---|---|
| L0 fast local | `bash harness/check.sh` or `focused harness`: links, syntax, historical receipt consistency, existing offline orchestration/regression guards | No org/auth/browser; historical failure remains failure |
| L1 focused local | `bash harness/check.sh focused portal\|finance\|inventory\|presentation` | Existing Node mocks/static tests; presentation also existing Python metadata tests; no DOM/browser/Jest or Apex claim |
| L2 Salesforce server-side | Separately approved exact tests/manifest on verified ng-demo / `00Daj00001Ae3iWEAR`; identity SELECT before any test/check-only call | Not implemented in check.sh; rollback fixtures and test-result records are server effects. Stop on failure; no retry/repair/grant. Never ng-dev |
| L3 full regression/acceptance | `bash harness/check.sh full` covers all allowlisted **local** checks only. Real L3 additionally needs approved Apex, scoped metadata dry-run, strict DQ/coverage and actual-persona/browser/owner criteria | Local full PASS is not L3 PASS. Reuse applicable receipts, retain exceptions. Deployment and Git operations separately approved |

For L2, owner-approved commands must explicitly identify `--target-org ng-demo`; never rely on a
default or accept arbitrary alias equivalents. Salesforce auth unavailable = BLOCKED/SKIPPED,
not PASS. Inspect CLI result completion, failures and coverage, not only exit code. Check-only
receipts must say `checkOnly: true`, `status: Succeeded`, zero errors and expected scope/test totals.
Review the whole dirty-tree bundle against its captured before-state before selecting a manifest.

## Existing tests → protected workflows

Apex names below resolve under `force-app/main/default/classes/` with `.cls`; tests run on the
server only after approval. Node/Python tests below resolve under `scripts/tests/`.

| Area / backlog | Existing Apex tests (L2) | Local checks (L0/L1) / remaining L3 criteria |
|---|---|---|
| Foundation, lead, booking, triggers P1/P2/P7 | `VinValidatorTest`, `LeadRoutingHandlerTest`, `LeadEnrichRooftopServiceTest`, `LeadConvertGuardTest`, `TestDriveBookingGuardTest`, `TestDriveFollowUpTest`, `P2BulkTest`, `P7TriggerArchitectureTest` | Harness offline guards protect command order/identity/stop behavior, not business logic. D04 remains FAIL; actual Sales conversion, Task/email and contention require approved workflows |
| CP2 pricing / quote generation P3 | `QuotePricingServiceTest`, `QuoteBuilderControllerTest`, `QuoteSummaryControllerTest`, `QuoteTradeInGuardTest`, `QuoteTriggerEnforcementTest`, `TradeIn_Calc_EquityTest` | `d08_quote_presentation.test.mjs` (presentation). Protect precedence, unique primary Vehicle_Trim, signed premiums/discounts, rounding/zero list, blocked stamps and one-Quote guard. Actual print/PDF, line fidelity and browser pricing are separate; no historical repricing |
| Discount approvals P3 | `DiscountApprovalTest` | <=5 none, >5–10 manager, >10 VP; no self-approval, individual ActorId, write-back/locks. Active definition inventory is not live routing acceptance |
| Financing/delivery P4 | `PaymentCalculatorServiceTest`, `RateTableServiceTest`, `FinanceApplicationControllerTest`, `FinancingStatusServiceTest`, `FinancingApprovalTest`, `DeliveryCompletionGuardTest`, `DeliveryCloseServiceTest`, `LoyaltyEnrolmentServiceTest`, `FinancingFlsEnforcementTest` | `finance_launch_context.test.mjs`; cent payments, signed equity, table/manual rates, draft idempotency, independent finance approval, funded/checklist/Closed Won/enrollment gates. D09 compliant actual Finance session still needed |
| Service appointments/history P6/P8 | `ServiceVisitCapacityGuardTest`, `ServiceIntakeCaseServiceTest`, `CaseServiceHistoryControllerTest`, `VehicleServiceHistoryControllerTest`, `CaseEscalationStampBatchTest`, `CaseMilestoneServiceTest`, `OwnerPortalVehicleBrokerTest` | `p8_broker_ui.test.mjs`; Toronto-day capacity, independent service authority, idempotency and queue linkage. Live concurrency, four-hour escalation and 4/48 business-hour SLA remain separate operational gates; D01 retained |
| Loyalty/consent P6/P8 | `LoyaltyLedgerServiceTest`, `LoyaltyAccrualServiceTest`, `LoyaltyAccrualBatchTest`, `LoyaltyTierEvalBatchTest`, `RedemptionServiceTest`, `Loyalty_ExpiryBatchTest`, `ConsentGateServiceTest`, `NurtureAudienceServiceTest`, `RepeatPurchaseSignalServiceTest` | Portal state mocks are not D06 repair. Preserve stored balances/provenance, independent consent/deny precedence and inactive operations; no activation/jobs/backfill to pass |
| Customer ownership/authorization P8 | `OwnerPortalOwnershipTest`, `OwnerPortalShareReconcilerTest`, `OwnerPortalVehicleBrokerTest` | `p8_broker_ui.test.mjs`; exact Contact/half-open expiry, conflicting/revoked/foreign entitlements, separate service authorization, bounded DTOs/native denial. D01/D02 unresolved test fixtures, no privilege revocation workaround |
| Experience Cloud permissions P8 | `OwnerPortalFoundationControllerTest`, `OwnerPortalBatchBControllerTest`, `OwnerPortalEmailCapabilityTest` | `p8_batch_b_ui.test.mjs`, `p8_batch_c_ui.test.mjs`, `p8_broker_ui.test.mjs`; actual A/B/guest/same-Account isolation, native writes denied, active Network/custom permission/FLS. D03 blocked assertions, D06/D07 open; mock PASS is not security certification |
| LWC inventory/calculator/photo/picker P2/P7 | `InventoryGalleryControllerTest`, `OpportunityCalculatorControllerTest`, `VehicleReservationEventPublisherTest`, `VinDecoderServiceTest`, `InventoryReconciliationJobTest` | `p7_batch1_ui.test.mjs`, `vehicle_photo_header.test.mjs`, `test_drive_vehicle_picker.test.mjs`; labels, fallback, state/error paths. No repository browser E2E/Jest configuration identified; desktop/mobile/focus and multi-session event delivery remain actual-persona checks |
| Reports/dashboards P3–P7 | `Batch3ReportingAccessTest`, `ExecutiveServiceMetricsPublisherTest` | `d08_metadata_test.py` for scoped geometry/list metadata only. D03 fixture contention, D05/D11 canonical/storage gaps, D12 CSI exception retained. Intended reader/folder/running user/lookup-target Read/source-filter-tile parity requires approved live evidence |
| Metadata deployment | Tests selected by affected manifest, not every file in dirty tree | `p7_regression_test.py` tests runner safety using fake results; `uat_orchestration_test.py` tests collection/allowlists. Existing scoped manifests in `manifest/` and raw check-only receipts are reused, not executed by wrapper. L2 source compilation/dependency/coverage is still required before any deployment approval |

## Local mode mapping

- Every mode: required harness documents/local links; Bash/Python syntax; existing orchestrator
  `reuse()`/`coverage()` in memory; `uat_orchestration_test.py` and `p7_regression_test.py` offline.
  Also `harness/test_preservation.py` synthetic concurrent-change contracts and before/after
  selected-input preservation via `harness/preservation.py`. Required-input drift invalidates
  results; unrelated concurrent changes are INFO/unknown, not a blanket failure. See
  [baseline policy](BASELINE.md) for owned paths, presence-only checks and fingerprint limitations.
- `portal`: `p8_batch_b_ui`, `p8_batch_c_ui`, `p8_broker_ui` Node suites.
- `finance`: `finance_launch_context` Node suite.
- `inventory`: `test_drive_vehicle_picker`, `p7_batch1_ui`, `vehicle_photo_header` Node suites.
- `presentation`: `d08_quote_presentation`, `finance_launch_context` Node suites plus
  `d08_metadata_test.py` (source XML only).
- `full`: union of the above once, not repeated focused invocations.

Excluded by design: `scripts/test.sh --run`, live `scripts/verify.sh`, anonymous Apex/setup/probe/
backfill/persona/reset/deploy helpers, broad `npm run data:test`, dependency installs and old CI.
Inspect any additional tool before reuse; “test”, “probe” or “dryrun” in a filename is not safety proof.
Current known failures must remain visible in reused receipts; neither a successful collection nor
a local suite run changes their status. Report raw evidence using the [template](RUN_TEMPLATE.md).
