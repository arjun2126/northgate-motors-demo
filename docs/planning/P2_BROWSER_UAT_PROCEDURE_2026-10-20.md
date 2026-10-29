# Phase 2 browser UAT — genuine Sales Rep session

**Prepared only. No persona switch, Lead creation, conversion or booking is authorized by
this document.** Owner must explicitly start the next controlled UAT window. Use `ng-demo`
only. Do not run `p2_setup.apex` as admin, remove its bypass guard, or use admin saves as
Sales Rep evidence. Phase 2 remains UNVERIFIED until the owner completes this procedure.

## Responsibilities and safe session setup

| Actor | Action |
|---|---|
| Authorized CLI agent, after owner starts window | Compare live user and all assignments with `evidence/UAT/persona_baseline.json`. Capture unrelated assignments, public-group memberships, bypass settings, permissions and existing UAT tags. Verify zero submitted Pending/Started approvals and zero assigned work items. Run `finance_pre_restore_guard.apex`; run `scripts/persona.sh --dry-run rep`, then `scripts/persona.sh rep`. |
| CLI agent | Verify PSG_Rep `Updated`, actual assignment, Sales_Rep role, NG_Sales profile, ManagerId null, EditTask/ConvertLeads/RunFlow, booking Flow access and no bypass on the actual rep. Confirm the inbound and service queues support Lead ownership before testing their routes. Stop on an unexpected security issue. |
| Project owner, browser | Log in as administrator, use Setup → Users → Northgate Persona → Login, or log in through the owner's normal `ngpersona.ngdemo@northgate.demo` session. Open Northgate Sales. Confirm Northgate Persona identity and the actual rep configuration. Do not use the admin tab to save UAT records. |

CLI authentication is still admin authentication after a persona switch. The switch changes
the demo user's configuration; it does not authenticate CLI calls as that user. If rep
browser interaction is unavailable, stop and restore instead of substituting anonymous Apex.

## 1. Create ten controlled Leads — OWNER BROWSER

First have CLI check that no `UAT-P2-20261020-*` Leads exist. If any exist, inventory them;
do not duplicate or overwrite a previous run. Create Leads individually through Leads → New,
using Retail when available. Use the allowed initial status presented for that record type,
Lead Source Web, Canada/Ontario, fictional company `P2 UAT Company NN`, last name
`P2 UAT Buyer NN`, phone `4165550101`, email `p2.uat.NN@northgate-demo.test`, and the exact
tag below in Seed Tag. Use real required UI fields; stop rather than bypassing an error.

| NN / tag suffix | Postal code | Expected routing observation |
|---|---|---|
| 01 | M5V2T6 | Downtown, M route |
| 02 | M4C1B5 | Downtown, M route |
| 03 | L4H1A1 | North, L4H route |
| 04 | L4H2R5 | North, L4H route |
| 05 | L5V1M5 | Airport, L5V route |
| 06 | L5V2N5 | Airport, L5V route |
| 07 | L1G1A1 | Service Centre, L1G route; requires verified Lead-capable queue |
| 08 | L1G2H1 | Service Centre, L1G route; same precondition |
| 09 | K2A9J1 | UNROUTED; record actual owner/fallback behavior |
| 10 | P1B1A1 | UNROUTED; record actual owner/fallback behavior |

Tags: `UAT-P2-20261020-01` through `UAT-P2-20261020-10`. Eight mapped/two unmatched is
postal/rooftop consistency, not an 80/20 rep/queue split. Individual browser transactions
may repeat R1: cross-transaction durable rotation is an existing recorded limitation.
Do not claim R2 rotation or queue behavior that the actual saves do not demonstrate.

**CLI, read-only:** retrieve IDs, tags, owner, rooftop, assigned batch, status, tasks and
`UserRecordAccess` for the actual rep. Capture the 10-row routing table and any failure.
**Owner:** reopen the owned/queue Leads using All Open Leads, verify discovery and screenshot
the resulting routes. Private sharing and every pre-existing owner remain unchanged.

## 2. Qualify and convert one Lead — OWNER BROWSER

1. Open the new owned Downtown Lead 01. Use a permitted working/qualification status;
   record the actual label. Do not invent a picklist value absent from this record type.
2. Verify required contact/company details and actual follow-up Task ownership/due date.
3. Convert using the UI. Create **new** UAT Account, Contact and Opportunity. Give Account
   and Opportunity unique `P2 UAT 20261020` names; use the new UAT Contact only.
4. Never select a canonical or historical existing Account/Contact/Opportunity: the existing
   conversion trigger clears Seed Tag on linked converted records.
5. Capture conversion confirmation and all three new IDs. Do not convert another Lead.

**CLI, read-only:** verify IsConverted, ConvertedAccountId/ContactId/OpportunityId, owners,
relationships and no propagated Seed Tags. Confirm no old record was selected. Verify the
new Opportunity's actual Stage/Previous Stage/Stage Last Changed as relevant.

## 3. Book through TestDrive_Book_Screen — OWNER BROWSER

Before starting, CLI proposes an exact approved Vehicle, checks Available status, rep read
access and free future intervals. Do not reserve, complete or change canonical Vehicle data.
Owner approves the Vehicle ID and local-time test date explicitly.

1. Open `/flow/TestDrive_Book_Screen` in the genuine rep session.
2. Select approved Vehicle and newly converted Contact; schedule a future 45-minute slot
   (example: 10:00–10:45, at least two days ahead in the displayed timezone).
3. Save once. Capture confirmation and booking ID.
4. Start another interview for the same Vehicle/Contact, same date, start 10:30, duration
   45. Expect the visible conflict message. **No record must be created.** Capture screenshot.
5. Book a free non-overlapping slot, for example 11:00–11:45. Capture second saved ID.
   If a back-to-back boundary is explicitly chosen instead, 10:45 is allowed by strict
   overlap bounds; first verify no other booking conflicts with that interval.
6. Do not complete bookings, submit approvals or repeat Quote UAT.

**CLI, read-only:** verify exactly two new bookings, correct Contact/Vehicle/status/start,
duration and formula end; confirm rejected attempt added no row. Verify actual follow-up
Tasks, counters and related records. Owner checks actual email receipt or records a
deliverability blocker; swallowed email errors are not proof of delivery.

## 4. Opportunity and related-record checks — OWNER + READ-ONLY CLI

Owner advances only the new Opportunity through Prospecting → Qualification → Test_Drive
using actual allowed stage labels. Capture stamps and follow-up Tasks. Associate the new
bookings to the new Opportunity if that separate edit is included in the approved window;
the booking Flow itself does not currently ask for Opportunity. CLI verifies IDs/links and
actual behavior. Missing stage-driven Tasks or required links are defects, not automatic PASS.

Reservation, vehicle-counter and completion tests require a separately approved controlled
Vehicle/record and appropriate actor. Rep must not gain Vehicle edit merely to force a test.
Complete `evidence/UAT/UAT_P2.md` with tester/date, per-check outcomes, screenshots, IDs and
any unmet original requirements. A subset of this procedure does not sign the whole phase.

## 5. Restoration — AUTHORIZED CLI, INCLUDING FAILURE

1. Stop further writes. Owner leaves Login As. Inventory partial UAT records; no deletion
   or retry is implied. Report exact error and IDs without changing permissions or bypass.
2. Verify zero pending approvals submitted by or assigned to persona. Run established
   `scripts/uat/finance_pre_restore_guard.apex`. If either guard blocks, escalate; do not
   strand an approval by force-restoring or reject it without authorization.
3. Run `scripts/persona.sh restore` after guards pass.
4. Verify exact captured baseline: VP_Sales (`00Eaj00000QCxlLEAT`), NG_Sales profile
   (`00eaj00000TnZaFAAV`), ManagerId null, no managed persona PSGs; unchanged unrelated
   assignments and public-group memberships. Capture raw query/script output.

This document performs none of these live actions. Owner browser steps cannot be replaced
by admin-context inserts, a disabled bypass guard or claimed-but-unobserved Flow screens.
