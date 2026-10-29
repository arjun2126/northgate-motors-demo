# Automation Direction — no new project-owned Salesforce Flows

**Status:** Owner-ratified architecture baseline. Apples to the whole remaining build
(Phases 3–7). Both agents follow this file as the shared baseline; planning files
(`DEMO_ORG_BACKLOG.md`, `DEMO_ORG_DATA_MODEL.md`, `DEMO_ORG_MASTER_PLAN.md`) still describe
the pre-ratification Flow shape and are provisional where a row says `FLOW`.

## Direction

1. **No new project-owned Salesforce record-triggered/auto-launched Flows.**
2. **Preserve the accepted P3-01 appraisal screen Flow (`Trade_In_Appraisal`).** Do not
   rebuild or remove working automation merely to satisfy this direction.
3. **P3-02 stays Apex:** thin `QuoteTrigger` (`before insert`) → `QuoteTradeInGuard`.
4. "No new Flows" does **not** mean "rebuild everything in Apex."
   - **Preserve native Salesforce features** that are not Flows and need no replacement:
     Approval Processes, Escalation Rules, Entitlements + Milestones, Knowledge,
     Duplicate Rules, formula fields, declarative picklists, reports/dashboards,
     Experience Cloud, Agentforce/Prompt Builder, Data Cloud, Platform Events, queues.
   - **Distinguish backend automation from user-facing wizard screens.** A record-trigger
     or before-save Apex service replaces a *backend rule* (capacity checks, status
     transitions, roll-up stamps, auto-create). It does **not** replace an *interactive
     wizard* (quote builder, finance application). Interactive screens become **LWC** or
     are flagged as exceptions below.
5. Reactivation/rollback of any Flow already in the org uses its documented
   deactivate/reactivate path (`DEMO_ORG_MASTER_PLAN.md` §7.6); no Flow is deleted without
   explicit owner approval.

## Implementation map (remaining backlog)

Backend rows move to Apex trigger → service/guard, reusing existing patterns. Wizard rows
need custom UI (LWC). Native rows are untouched.

### Backend automation — Apex trigger + service replacement

| Item | Proposed non-Flow implementation | Reuse existing components |
|---|---|---|
| P3-02 Appraisal-before-quote gate | `QuoteTrigger` (`before insert`) → `QuoteTradeInGuard` (reads `Opportunity.Has_Trade_In__c`; blocks unless any child `Trade_In__c` is `Accepted`) | `Quote` object in source; guard pattern `TestDriveBookingGuard.cls`; bypass header `LeadRoutingTrigger.trigger` |
| P4-03 Financing status lifecycle | `FinancingTrigger` (`before insert/update`) → `FinancingStatusService`: block invalid transitions, maintain `Previous_Status__c` | stamp pattern `OpportunityStageStamp.cls`; `VR_Financing_FundedRequiresApproved` stays |
| P4-06 Delivery checkpoint block | Keep `VR_Delivery_ChecklistBeforeCompleted` (already enforces); drop redundant before-save flow | existing VR |
| P4-07 Delivery closes opportunity | `DeliveryTrigger` → `DeliveryCloseService`: Closed Won, `Delivery_Date__c`, `Contact.Lifetime_Vehicles_Owned__c`, loyalty enrolment | `OpportunityStageStamp.cls`; `VR_Opportunity_ClosedWonNeedsDelivery` stays |
| P4-08 Loyalty enrolment on delivery | Part of `DeliveryCloseService` (above) | `P2TestDataFactory` for fixtures |
| P6-01 Service visit capacity | `ServiceVisitTrigger` (`before insert/update`) → `ServiceVisitCapacityGuard`: open bookings vs `Rooftop__c.Service_Capacity__c` | overlap-query guard `TestDriveBookingGuard.cls` |
| P6-02 Service intake case flow | `ServiceVisitTrigger` (`after insert`) → auto-create `Case`, owner `Q_Service_Intake` | case creation pattern `TestDriveFollowUp.cls`; queue lookup pattern `LeadRoutingHandler.resolveLane` |
| P6-08 Redemption + expiry | Apex `RedemptionService` + existing `Loyalty_ExpiryBatch`; `VR_Loyalty_NonNegativeBalance` stays | existing VR, batch pattern `LoyaltyTierEvalBatch` |
| P6-12 Consent + nurture gate | `ConsentTrigger` guard on `Consent__c` → campaign-membership inclusion/exclusion | guard pattern `VehicleReservationGuard.cls` |

### Native Salesforce features — preserved, not Flows (no replacement)

| Item | Feature to preserve |
|---|---|
| P3-06 Discount approval process | Native Approval Process (manager >5%, director >10%) |
| P4-05 Finance approval record path | Native Approval Process (finance manager) |
| P6-03 Escalation rule | `ER_Case_HighPriority_4h` escalation rule |
| P6-14 Entitlements + Milestones | Native entitlement + milestone objects |
| P6-15 Knowledge | Native Knowledge |
| P3-08, P3-09, P3-10, P4-09, P4-10, P5-09…P5-15, P6-09, P6-11, P7-11 | Reports + dashboards (native) |
| P7-15 Agentforce + Prompt Builder | Native Agentforce; *fallback below* |
| P7-16 Data Cloud | Native data space |
| P7-18 Experience Cloud | Native portal |
| P7-03, P7-05, P7-08 | REST callout, Platform Event, Queueable (already Apex/native) |

### User-facing wizard screens — need custom UI, not Apex triggers

| Item | Proposed implementation | Scope note |
|---|---|---|
| P3-04 Quote-from-opportunity wizard | LWC quote builder: pick pricebook lines, call `QuotePricingService` (`Price_Rule__mdt`), create `Quote` + `QuoteLineItem` | **Scope change:** backlog says "via Flow"; now LWC. Acceptance wording must move to LWC evidence, pending approval (P3-02's screenshot waiver rule applies unchanged). |
| P4-02 Finance application screen | LWC form: amount, term, credit tier, co-signer; live payment via `PaymentCalculatorService` (P4-01) | **Scope change:** Flow → LWC. Composes with planned P7-02 payment/trade-in LWC widget. |
| P3-07 Quote document | LWC + standard Quote PDF (already non-Flow; unchanged) | — |
| P7-01, P7-02, P7-23 | LWC (already LWC; unchanged) | — |

### Accepted exception (working automation preserved)

- **P3-01 `Trade_In_Appraisal` screen Flow** stays as-is. Ratified by owner; not rebuilt.

### Genuine exceptions requiring owner approval

1. **P3-04 and P4-02** wizard screens: choose LWC (recommended, scope/effort change +
   evidence re-wording) **or** keep small screen Flows as an exception to the direction.
2. **P7-15 fallback** "simulated triage flow, kept and labelled": decide Apex/LWC fallback
   (recommended) **or** retain one small Flow as the labelled fallback.

## Governance note

When a backlog item's acceptance mentions a Flow, the wording is provisional until this
baseline is edited into the planning files. Editing `DEMO_ORG_BACKLOG.md` / `DEMO_ORG_DATA_MODEL.md`
(`FLOW` tags and §5.6 map rows) is a separate approved doc-change; not done here.