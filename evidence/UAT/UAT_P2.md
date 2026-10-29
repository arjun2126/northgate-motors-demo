# UAT — Phase 2 Vertical Slice (P2-14)

> **Status 2026-10-20: UNSIGNED TEMPLATE.** No tester, date, result, screenshot, or
> sign-off row has been completed. This file does not prove Phase 2 UAT passed. The
> `demo/v0.1` tag does not substitute for UAT evidence. See
> `docs/planning/PHASE2_SIGNOFF_RECONCILIATION_2026-10-20.md`.

Date: 2026-10-08 (template; fill in during UAT pass)
Org: ng-dev (`arjun.ngdev@northgate.demo`)
Tester: ________________
Run as: ngrep (Sales Rep) by default; switch to ngpersona manager/finance via `scripts/persona.sh`

## Pre-flight

- [ ] Bypass switches in `Automation_Settings__c` are OFF (Bypass_Validation, Bypass_Flows, Bypass_Triggers all `false`).
- [ ] No P1 trigger-bypass permission assigned to the test user.
- [ ] Reports `Pipeline by Stage` and `Lead Source Effectiveness` exist in folders `NG_01_Pipeline` and `NG_02_Leads`. (Owner click steps in `evidence/P2/blocked-metadata/REPORTS_DASHBOARDS_checklist.md`.)
- [ ] Dashboard `Sales Pipeline Snapshot` exists in folder `NG_Sales`.

## 1. Web lead intake (P2-01 — Flow pending; Apex round-robin staged)

1. Log in as ngrep.
2. Create Lead with LastName = `UAT Lead One`, Company = `UAT Co`, PostalCode = `M5V2T6` (Downtown FSA), Source = `Web`.
3. Expect: Lead saved with Rooftop__c = Northgate Downtown, Assigned_Batch__c = `M-R1` (or `M-R2`), OwnerId = ngrep.
4. Create second Lead, PostalCode = `L4H1A1` (North). Expect Rooftop__c = Northgate North, Assigned_Batch__c = `L4H-R1`, OwnerId = ngrp svc.
5. Create third Lead, PostalCode = `K1A0A1` (no match). Expect Assigned_Batch__c = `UNROUTED`, OwnerId = Inbound Leads queue.
   - (Pending) Flow source is not yet deployable; behaviour is documented but not enforced in org until P2-01 Flow is built. Mark as **DEFERRED** and continue.

## 2. Lead conversion guidance (P2-02)

1. As ngrep, create Lead A with LastName = `UAT Conv A`, Company = `UAT Conv A Co`, Status = `Open`.
2. Attempt to convert Lead A without selecting an Account (Convert Lead dialog, leave Account blank). Expect: clear error message “Convert with an Account selected…”.
3. As ngrep, create Lead B with LastName = `UAT Conv B`, Company = `UAT Conv B Co`, Status = `Open`, Seed_Tag__c = `SEED-UAT-01`.
4. Convert Lead B selecting an existing Account. Expect: converted Account, Contact, Opportunity created; the converted Account/Contact/Opportunity have Seed_Tag__c cleared (only the Lead retains its tag).
5. Capture screenshot → `evidence/P2/uat/conversion.png`.

## 3. Test drive booking (P2-03, P2-04)

1. As ngrep, open a Vehicle (Status = Available, Rooftop = Downtown) and a Contact.
2. Schedule a Test Drive for today + 2 days, 10:00–10:45.
3. Attempt to schedule a second Test Drive on the same Vehicle overlapping (10:30). Expect: error “That vehicle is already booked for the selected time.”
4. Schedule a back-to-back Test Drive 11:00–11:45. Expect: succeeds.
5. Capture screenshot → `evidence/P2/uat/testdrive_conflict.png`.

## 4. Opportunity stage model (P2-05)

1. As ngrep, create an Opportunity, advance stage from Prospecting → Qualification. Expect: Stage_Last_Changed__c = now; Previous_Stage__c = Prospecting.
2. Advance to Test_Drive. Expect: Previous_Stage__c = Qualification, Stage_Last_Changed__c updates.
3. Capture screenshot → `evidence/P2/uat/stages.png`.

## 5. Vehicle reservation (P2-06)

1. As ngrep, create a Vehicle (Status = Available). Create a Contact.
2. Set Vehicle.Reserved_By__c = Contact. Save. Expect: Status__c = Reserved, Reserved_On__c populated.
3. Try to set Reserved_By__c = different Contact. Expect: error “That vehicle is already reserved by another customer.”
4. Capture screenshot → `evidence/P2/uat/reserve_block.png`.

## 6. Task auto-creation (P2-07) + email (P2-08)

1. As ngrep, create a Test Drive (Scheduled). Expect: Task with Subject `Test drive: Created …` linked via WhoId = Contact.
2. Update Test Drive Status = Completed. Expect: second Task created.
3. Set Status to Scheduled (from another value) and verify `Messaging.sendEmail` is invoked. Email deliverability may be System-Only in DE; record success or skip.
4. Capture screenshot → `evidence/P2/uat/tasks.png` and `evidence/P2/uat/confirm_email.png` (if delivered).

## 7. Reports and dashboard (P2-09, P2-10, P2-11)

1. Run `Pipeline by Stage` from folder `NG_01_Pipeline` as `arjun.ngdev@northgate.demo`. Expect: matrix grouped by Stage × Owner, with Amount totals; row order matches the 8 DATA_MODEL §7 stages.
2. Run `Lead Source Effectiveness` from folder `NG_02_Leads`. Expect: summary grouped by LeadSource with conversion counts.
3. Open `Sales Pipeline Snapshot` dashboard in folder `NG_Sales`. Expect: Bar chart of pipeline by stage; Horizontal Bar of lead source. Screenshot → `evidence/P2/uat/dash_pipeline.png`.

## 8. Counters (P2-12)

1. Insert a Vehicle in rooftop Northgate Downtown. Expect: Rooftop__c.Vehicles_On_Hand__c increments by 1.
2. Complete a Test Drive on that Vehicle. Expect: Vehicle_Model__c.Completed_Test_Drives__c increments by 1.
3. Screenshot → `evidence/P2/uat/counters.png` (optional).

## 9. Person a switch (P1-21 / P2-15)

1. Run `./scripts/persona.sh manager` against ng-dev. Expect: ngpersona role = Sales_Manager_Airport, PSG = PSG_Manager.
2. Run `./scripts/persona.sh finance`. Expect: ngpersona role = Finance_Manager, PSG = PSG_Finance.
3. Re-run each of the reports above while logged in as ngpersona (the dashboard's specified user is admin; reports can be re-run as ngpersona). Screenshot → `evidence/P2/uat/persona_view.png`.

## 10. Regression checklist

- [ ] All 17 validation rules from DATA_MODEL §9 still trigger on bad data (negative test one per rule group).
- [ ] `Bypass_Automation` permission still skips VRs/Flows/Triggers (positive test: assign PS_Bypass_Load to a runner user, insert a Lead with bad email, expect success).
- [ ] Round-robin Apex action yields the same owner sequence when invoked twice in a single transaction (covered by LeadRoundRobinTest).

## Sign-off

| Tester | Date | Pass / Fail | Notes |
|---|---|---|---|
| | | | |
