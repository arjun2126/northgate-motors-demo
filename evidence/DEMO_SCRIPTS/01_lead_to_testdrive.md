# Demo Script 01 — Lead → Test Drive → Opportunity (P2-15)

Time: < 5 minutes
Audience: dealer principal, GM, sales manager
Org: ng-dev (or ng-demo once parity is in place)
Login: `arjun.ngdev@northgate.demo` (admin) — or activate a persona.

## 0. Activate persona (1 min)

> Skip this step if running as a named persona (ngrep, ngsvc, ngpersona).

```bash
# In your terminal:
./scripts/persona.sh manager   # or `finance` — toggles ngpersona role + PSG
```

Sign in as `ngpersona@northgate.demo`. The Northgate Sales app is the default landing.

## 1. Web lead → rooftop routing (1 min)

1. From the App Launcher, open **Leads** → **New**.
2. Fill in:
   - Last Name: `Demo Lead`
   - Company: `Northgate Demo Co`
   - Postal Code: `M5V2T6`  (downtown FSA)
   - Lead Source: `Web`
3. Save.
4. Show: the Lead’s **Rooftop** field resolves to *Northgate Downtown*; the **Assigned Batch** is `M-R1`.
5. Create a second Lead with Postal Code `L4H1A1` (North). Show: rooftop = Northgate North, batch `L4H-R1`. Round-robin lane visible in **Assigned Batch** + **Owner**.

## 2. Conversion (1 min)

1. Open the second Lead. Click **Convert**.
2. The dialog **requires** an Account (the before-guard fires if you try to skip it).
3. Choose “Create new Account” → `Demo Converted Account`.
4. Convert. Show: a new Account, Contact, and Opportunity appear; the `Seed_Tag__c` is **cleared** on the converted records (the after-trigger does this) — only the original Lead carries a tag.

## 3. Test drive booking (1 min)

1. From the Opportunity, click **Schedule Test Drive**.
2. Pick a vehicle (filter Rooftop = Downtown), a contact, date tomorrow, 10:00–10:45.
3. Try to schedule a second Test Drive on the same vehicle at 10:30 — the overlap guard blocks it.
4. Schedule one at 11:00 instead — back-to-back is allowed.
5. Show the auto-created Task on the Test Drive record (Subject: “Test drive: Created …”).
6. Update Status = Completed — a follow-up Task is created.
7. Set Status back to Scheduled — a confirmation email is sent (may be suppressed in DE).

## 4. Opportunity stage movement (30 s)

1. On the converted Opportunity, advance stage: Prospecting → Qualification → Test_Drive → Appraisal → Quoting → Financing → Closed Won.
2. Show: each advance updates `Stage_Last_Changed__c` and writes the prior stage to `Previous_Stage__c`.
3. Show the **Pipeline by Stage** report (NG_01_Pipeline / Pipeline by Stage) — the matrix reflects the journey.

## 5. Reports and dashboard (30 s)

1. Open the **Pipeline by Stage** report (Run as `arjun.ngdev@northgate.demo`).
2. Open the **Lead Source Effectiveness** report (NG_02_Leads).
3. Open the **Sales Pipeline Snapshot** dashboard (NG_Sales) — the Bar chart tracks pipeline by stage; the Horizontal Bar tracks lead source.

## 6. Counters (15 s)

1. Open the rooftop record (Northgate Downtown). `Vehicles_On_Hand__c` reflects current count.
2. Open the model record. `Completed_Test_Drives__c` increments after each Completed test drive.

## 7. Close

Hand back to the persona. Click “Activate persona” again or log out.

**Dead-end check:** the demo should never require a manual edit or a click into Setup. If a step appears to lead to a wall (e.g. a missing report), log it and continue; the owner is creating the reports manually per the checklist.
