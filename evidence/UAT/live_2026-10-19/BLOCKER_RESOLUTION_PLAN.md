# Northgate Motors — Final UAT Blocker Resolution Plan

Date: 2026-10-19. Org: `ng-demo` (`00Daj00001Ae3iWEAR`) only. This pass is **read-only** against
Salesforce plus local preparation. No Price Book activation, ManagerId change, group/folder-share
change, persona switch, record creation, approval submission, DML, deploy, commit, or push was made.

## 1. Verified root causes

### Area 1 — Quote Builder
- `QuoteBuilderController.standardPricebookId()` selects `Pricebook2 WHERE IsStandard = true AND IsActive = true` and returns `null` when none match (`force-app/main/default/classes/QuoteBuilderController.cls:206-214`). `getCatalog` and `createQuote` then fail: `Standard Price Book is not active. Activate it before creating quotes.`
- Live: `Standard Price Book` `01saj00000NvczOAAR` has `IsStandard=true`, `IsActive=false`. CONFIRMED.
- Reconciliation with "30 active vehicle products and PricebookEntries": all 30 rows are present and correct but point at that inactive book. `Product2` active `Vehicle_Trim` = 30; active `PricebookEntry` in `01saj00000NvczOAAR` = 77 total, 77 active, 30 vehicle-trim. CONFIRMED.
- Separate active book named "Standard" `01saj00000NvczNAAR` (`IsStandard=false`, 17 entries, `Category__c` null, 0 vehicle entries) is unused by any Quote. All 60 historical Quotes reference `01saj00000NvczOAAR`. CONFIRMED.
- So the products/entries were never the problem; the Price Book object was deactivated. No repo code deactivates it (only test/backfill references found). Root cause is an out-of-band deactivation of the standard book.

### Area 2 — Manager approval
- Manager tier (>5% to 10%) is `adhoc`; the controller sets the next approver to `UserInfo.getUserId()`→`User.ManagerId` and throws `No manager found for the submitter.` when null (`QuoteBuilderController.cls:312-317`). Approval process `Opportunity.Opportunity_Discount_Approval` entry criteria `>5 AND <=10`, `allowedSubmitters=owner`.
- Live active users holding any manager role: only `ngpersona.ngdemo@northgate.demo` (`VP_Sales`). `arjun.ngdemo@northgate.demo` has no role and ManagerId null. CONFIRMED.
- `allowedSubmitters=owner`, so the submitter must own the Opportunity. `ngpersona` cannot be both submitter and approver (controller `Submitter cannot be the approver`). No second non-admin Salesforce user exists to be a genuine rep submitter.
- Therefore the only way to test the real manager-assignment path with a genuine manager *persona* approver is: submitter = `arjun` (admin, temporary `ManagerId` set), approver = `ngpersona` in a manager role. The approver remains the Sales Manager persona, not the admin.

### Area 3 — Persona UI and approval decisions
- `System.runAs` works only in Apex test context, so no CLI/anonymous path can render or act as `ngpersona`. CONFIRMED earlier. All persona-context UI and approval decisions require an owner browser session (Setup "Login As" or credentials).

### Area 4 — Dashboard and report access
- Public group `PG_All_Sales` `00Gaj00000ZYYhUEAX` (Regular) has 0 members. CONFIRMED.
- Dashboard folder `NG_Sales` is shared View to `PG_All_Sales` (plus `arjun` Manage); dashboards inside: `DM_DealDesk`, `wmJfrbDSELUkweOHuzWNpCXeWLvZue`, `wvxnHhLpnwXIYyamDoGiPgxGwmyscn`. With the group empty, `ngpersona` cannot see them. CONFIRMED live (metadata retrieve).
- Report folders live shares: `NG_01_Pipeline`, `NG_02_Leads`, `NG_05_DataQuality` = `arjun` Manage only; `NG_03 Inventory`, `NG_04 Service`, `NG_06 Loyalty` = no shares. All 23 NG reports live in these six folders. CONFIRMED live (metadata retrieve).

## 2. Exact minimum changes

Persistent (P) / Temporary (T):

| # | Change | Scope | Type |
|---|---|---|---|
| 1 | `Pricebook2` `01saj00000NvczOAAR` `IsActive = true` | 1 record, 1 field | P |
| 2 | `GroupMember` add user `005aj00000gE0b3AAC` to group `00Gaj00000ZYYhUEAX` (`PG_All_Sales`) | 1 row | P |
| 3 | Folder share `View` to `PG_All_Sales` on `NG_01_Pipeline`, `NG_02_Leads`, `NG_03 Inventory`, `NG_04 Service`, `NG_05_DataQuality`, `NG_06 Loyalty` | 6 shares | P |
| 4 | `User` `arjun.ngdemo@northgate.demo` `ManagerId = 005aj00000gE0b3AAC` | 1 field | T |
| 5 | Switch `ngpersona` role/PSG for the UAT phases | via `scripts/persona.sh` | T |

No object permissions, profiles, or admin grants change. `PG_All_Sales` membership grants only the
folder shares above; it carries no object access by itself. Prefer the existing group over per-user
folder shares (change #3 targets the group, not `ngpersona` directly).

Conditional (only if the manager approval item is not visible to `ngpersona` after submission):
temporarily set `ngpersona` role to `Sales_Manager_Downtown` (`00Eaj00000QCxlOEAT`) instead of
`Sales_Manager_Airport`. Try the airport role first; the approval share is expected to grant record
access.

Not done / not required: activating book `01saj00000NvczNAAR`, editing Product2 or PricebookEntry,
editing historical Quotes, OWD changes, sharing rules.

## 3. Persist vs temporary

- Persist: #1 (the standard book must stay active for the builder and is already the book all Quotes reference), #2 (dashboard access), #3 (report access).
- Temporary and must be reverted: #4 and #5.
- `scripts/persona.sh` already guarantees persona restoration and blocks switching while any approval is pending.

## 4. Rollback and restoration

Pre-state capture (before any change, CLI): re-run baseline capture; snapshot `Pricebook2` `01saj00000NvczOAAR`, `GroupMember` for `00Gaj00000ZYYhUEAX`, the six folder-share sets, and `arjun` `ManagerId`.

- #1 rollback: set `IsActive=false`. Note this returns to the current broken builder state; not planned after acceptance.
- #2 rollback: delete the `GroupMember` row for user `005aj00000gE0b3AAC`.
- #3 rollback: remove the `PG_All_Sales` share from each folder (revert the six `*.reportFolder-meta.xml`).
- #4 rollback: set `arjun` `ManagerId` back to `null`.
- #5 rollback: `scripts/persona.sh restore`; verify role `VP_Sales`, `ManagerId` null, profile `00eaj00000TnZaFAAV`, no persona PSGs, exactly one active VP, 0 pending approvals.
- Verify after rollback: Quote count 60, Financing 62, no leftover pending approvals, baseline SHA256 `e62b6a75f5e0757b99a93a0d0e1a197abfe45987` unchanged.

## 5. Dependency-ordered execution sequence

CLI-capable steps run as admin; owner steps need a browser session.

1. **Preflight (CLI, read-only).** Confirm 0 pending approvals, capture pre-state, confirm `ngpersona` baseline.
2. **Persistent config (CLI/admin DML).** #1, #2, #3. Verify: builder returns a non-null pricebook id and a 30-item vehicle catalog; `PG_All_Sales` shows 1 member.
3. **Manager path (mixed).** Set `arjun` `ManagerId` = `ngpersona` (T). CLI switch `ngpersona` → `manager`. Owner Login As `ngpersona`: approve the 7% Opportunity. Verify `Approval_Status__c = Approved`. Resolve to 0 pending. Clear `arjun` `ManagerId` (T rollback).
4. **Rep + Quote Builder (owner).** CLI switch `ngpersona` → `rep`. Owner Login As: create a Quote in the builder, confirm line items and CP2 pricing. This is the persisted-CP2 acceptance the earlier pass could not run.
5. **VP path (mixed).** Create/own a >10% Opportunity as `arjun`; CLI switch `ngpersona` → `vp`; submit (admin, approver = VP `ngpersona`); owner Login As `ngpersona` to approve. Verify. Resolve to 0 pending.
6. **Finance exception (mixed).** Create a `Financing__c` exception as `arjun`; CLI switch `ngpersona` → `finance`; submit so it routes to `Q_Finance_Approvals`; owner Login As `ngpersona` to approve. Verify flag/date. Resolve to 0 pending.
7. **Delivery + Loyalty (owner).** Reuse controlled UAT records; owner Login As `ngpersona` (`rep`) to view Delivery/Loyalty results in the UI.
8. **Restore (CLI).** `scripts/persona.sh restore`; verify baseline and 0 pending approvals; remove any temporary config not marked persist.

Ordering constraints: the VP tier needs an active `VP_Sales` user, so it must run while `ngpersona` is
`vp`; the manager tier runs while `ngpersona` is `manager` (VP routing is then intentionally
unavailable). Do not cross-run these. The script refuses to switch while an approval is pending, so
each phase must finish its approval first.

## 6. Consolidated owner approval request

Approve, as one bundle, for `ng-demo` only:

1. Activate `Standard Price Book` `01saj00000NvczOAAR` (persistent).
2. Add `ngpersona.ngdemo@northgate.demo` to public group `PG_All_Sales` (persistent).
3. Share report folders `NG_01_Pipeline`, `NG_02_Leads`, `NG_03 Inventory`, `NG_04 Service`, `NG_05_DataQuality`, `NG_06 Loyalty` View-only to `PG_All_Sales` (persistent).
4. Temporarily set `arjun.ngdemo@northgate.demo` `ManagerId` to `ngpersona` for the manager test, then clear it.
5. Authorize the persona switch sequence in the plan (`rep`/`manager`/`vp`/`finance`/restore) and temporary controlled UAT records and approval submissions.
6. Provide an owner browser session (Setup Login As `ngpersona`) for the steps marked owner.
7. Optional decision: purchase/allocate one additional Salesforce license to create a genuine Sales Rep submitter user, which removes the admin-submitter compromise (item 4).

## 7. Owner browser UAT checklist (concise)

1. Activate the Standard Price Book (or confirm CLI did).
2. Login As `ngpersona` (`manager`): My Approvals shows the 7% discount item; Approve; stage/flags update.
3. Login As `ngpersona` (`rep`): Quote Builder loads a 30-vehicle catalog; create a Quote; line items and CP2 pricing correct; historical quote still opens.
4. Login As `ngpersona` (`vp`): approve the >10% item.
5. Login As `ngpersona` (`finance`): approve the financing exception; flag/date set.
6. Login As `ngpersona` (`rep`): Delivery shows Completed, opportunity Closed Won, loyalty member present.
7. Login As `ngpersona`: open `NG_Sales` dashboards and the NG reports successfully.
8. After UAT, confirm restore: role `VP_Sales`, ManagerId null, 0 pending approvals.

## 8. License and tooling limitations

- Salesforce licenses are fully used (4/4: arjun, ngpersona, epic, roger); Platform/Force.com have no usable Opportunity access. No free license exists to add a genuine Sales Rep submitter user. This is why the manager/VP/finance submissions use the admin as submitter while the approver remains the correct persona.
- `System.runAs` is test-only, so persona-context execution cannot be driven from CLI; only the owner browser Login As can.
- Approver record visibility under Private Opportunity OWD relies on the approval share; if `ngpersona` cannot see the pending item, apply the conditional Downtown role change.
- `ngpersona` profile object-level Read for every report's underlying object is not yet verified at runtime.
- The working tree already contains pre-existing uncommitted changes (29 files, e.g. username `ngdev`→`ngdemo`, dashboards, layouts, tests) that predate this pass; they were not touched by this investigation.
