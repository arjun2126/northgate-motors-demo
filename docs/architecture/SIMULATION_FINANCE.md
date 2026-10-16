# SIMULATION_FINANCE

Demo note for the P4-01..P4-09 financing, approval, and delivery scope (M2/M3 workshop content).

## Scope seam

This package implements Northgate's **retail-deal financing lifecycle** in Salesforce:

- `PaymentCalculatorService` (P4-01): amortisation — principal, term, rate → monthly
  payment, total interest, correct to the cent.
- `RateTableService` (P4-04) + `Rate_Table__mdt` (30 active + 1 inactive records): credit
  tier × term → base rate mapping. Two rate sources: `Rate_Table` (default) and
  `Manual_Exception` (Finance Manager exception approval required).
- `FinanceApplicationController` (P4-02) + LWC `financeApplication` + QuickAction
  `Opportunity.Finance_Application`: captures amount, term, rate source, credit tier,
  co-signer, applicant; live payment preview.
- `FinancingStatusService` (P4-03) + `FinancingTrigger` + `VR_Financing_TermRequired`:
  status lifecycle `Draft → Submitted → Conditional → Approved → Declined → Funded`
  (or `Cancelled`); `Previous_Status__c` maintained for VR history; `Funded` requires
  `Previous_Status = Approved`.
- `Financing_Exception_Approval` approval process (P4-05) + `Financing.workflow`
  field updates: routes sub-prime tier or manual-exception rate requests to the
  Finance Manager via `Q_Finance_Approvals` (role `Finance_Manager`); approved sets
  `Finance_Exception_Approved__c = true` and `Decision_Date__c = today()`; rejected
  sets `Finance_Exception_Approved__c = false`. Two-process pattern (entry criteria
  carry the gate; `ifCriteriaNotMet = ApproveRecord`).
- `FinancingApprovalService`: idempotent submission helper that derives the approver
  from the queue and is a no-op if a Pending `ProcessInstance` already exists.
- `DeliveryTrigger` + `DeliveryCloseService` (P4-07) + `LoyaltyEnrolmentService`
  (P4-08): on `Delivery__c.Status__c = Completed` with the four checklist items
  checked, set `Opportunity.StageName = Closed Won` and
  `Opportunity.Delivery_Completed__c = true`; stamp `Delivery.Completed_Date__c`;
  increment `Contact.Lifetime_Vehicles_Owned__c`; auto-enrol the buyer in the
  loyalty program (Active / Bronze / 0 balance / auto `NG-####-####` member number).
  The late-Buyer enrollment path is also handled.
- Reports: `Financing_Mix_by_Status` (NG_01_Pipeline), `Funding_Lag` and
  `Financing_Approvals_Pending` / `Financing_Avg_Days_To_Fund` /
  `Financing_Declined_Count` / `Financing_Decided_Total` (NG_05_DataQuality).
- Dashboard: `DM_DealDesk` (NG_Sales, fixed running user) — pending approvals, avg
  days to fund, decline count and decided-total.

## What is simulated, and how

| Domain | Real finance/billing product | This demo |
|---|---|---|
| Payment calculation | `PaymentCalculatorService` on Apex (P4-01); live in wizard | No external billing engine; manual amortization via `PMT(rate/12, n, -P)` formula in code |
| Rate determination | Live rate sheet from lender; rate lock | `RateTableService` reads `Rate_Table__mdt` (30 active + 1 inactive records) keyed by credit tier × term |
| Credit decisioning / underwriting | External credit bureau, decision engine | No credit bureau; tier is sales-entered (`A / B / C / D / Sub_Prime`); exception path requires Finance Manager approval |
| Loan document / contract | Lender-generated PDF, e-sign | No loan document; the Financing record is the system-of-record (Opportunity-linked) |
| Funding / disbursement | Lender ACH / wire | `Status__c = Funded` is a stamp (`Funded_Date__c`); no actual cash flow |
| Servicing / payments | Servicing platform (loans, statements, delinquency) | None — `Financing__c` ends at Funded |
| Loyalty program | Real loyalty platform (points, tiers, accrual rules) | `Loyalty_Member__c` (Active / Bronze / 0 balance at enrollment); no accrual engine — points stay at 0 until P6-06 (loyalty accrual) |
| Approval routing | Workflow / process builder with email + Slack | `Financing_Exception_Approval` process routes to `Q_Finance_Approvals` (queue member = `Finance_Manager` role) |
| Tax / fees | Tax engine (Avalara, etc.) | Wizard excludes taxes/fees (documented in the LWC); not modelled |
| Amortization schedule | Lender amortization table | `PaymentCalculatorService` produces monthly + total interest only; no full schedule |

## Demo script (estimated 45-60 min)

1. Open the pre-staged Opportunity (P4-02 UAT path: `NG CP2 Browser UAT` Quote at $30,340; Annual Rate 5.49%; Term 60; Monthly $579.39; Total Interest $4,423.40).
2. As Finance Officer (Persona Switcher), open the Financing record. Change `Rate_Source__c = Manual_Exception` to trigger the exception path; set a Manual Annual Rate; enter an Exception Reason. Save.
3. Open the **Submit Exception Approval** QuickAction on the Financing record → submit. As Finance Manager (owner temporarily assigns `Finance_Manager` role to `ngadmin`), approve via the queue workitem. Verify `Finance_Exception_Approved__c = true` and `Decision_Date__c = today()`. Revert `ngadmin` role after UAT.
4. Move Status to Submitted → Conditional → Approved per the lifecycle; set `Funded_Date__c = today` and move to Funded.
5. As Sales Rep, create a Delivery record on the same Opportunity, tick all four checklist items, set `Status = Completed`. Save. Verify the Opportunity now shows `StageName = Closed Won` and `Delivery_Completed__c = true`; a new `Loyalty_Member__c` exists for the buyer.
6. Negative UAT (rep persona): set `Delivery.Status = Completed` with one checklist unchecked → `VR_Delivery_ChecklistBeforeCompleted` blocks with the documented error.
7. Reports: open `Financing_Mix_by_Status` (NG_01_Pipeline), `Funding_Lag` (NG_05_DataQuality), and `DM_DealDesk` (NG_Sales, fixed user) for pending approvals / avg days to fund / decline rate.

## Boundaries

- tl;dr this module: CUSTOM OBJECTS `Financing__c`, `Delivery__c`, `Loyalty_Member__c`,
  `Loyalty_Transaction__c`, `Contact` (Lifetime_Vehicles_Owned__c); Apex classes
  above; approval process; workflow field updates; reports/dashboard.
- Marked **SIMULATION** commercial space: tax calculation, invoice generation,
  payment capture, revenue recognition, dunning, credit decisioning, e-sign,
  servicing, and loyalty accrual are all out of scope for this DE build and would
  be supplied by a paid billing / lending / loyalty product in a real deployment.
  The seam between simulated and real is the `Financing__c` record (system-of-record)
  and the `Loyalty_Member__c` record (Active / Bronze / 0 balance at enrollment).
- Open P4 design notes: the true LTV source and valuation tool (referenced by P4-04
  but not built) remain a Phase 5+ decision; the late-Buyer enrollment path was
  added to `DeliveryCloseService` after the initial deploy; the `Finance_Manager`
  role is currently empty and requires a temporary assignment to a System
  Administrator user for UAT (preserves the established `ngpersona` persona).
