# Activate persona — Northgate Owner Portal

**Preparation only. Customer-login UAT has not run.** Use a separately approved Customer
Community Plus customer A or B in an isolated browser profile. No such identities are currently
provisioned. Do not substitute System Administrator or run the internal `scripts/persona.sh`
switcher as a portal persona: internal role/profile swaps do not prove external access.

**Current §66:** Batch C six-bundle polish is deployed (`0Afaj00000pOUsQCAW`), not local-only.
Use `evidence/P8/uat/OPERATIONAL_CUSTOMER_UAT.md` for the ordered actual-customer execution
script and `docs/planning/P8_OPERATIONAL_COMPLETION_REGISTER.md` for authority/dependencies.
Older local-evidence walkthrough wording below describes preparation, not current deployment state.

## 1. Authorization gate

Before executing any customer step, obtain explicit approval for the specific external identities,
permission assignments, site membership, narrow record visibility, page placement and controlled
site publication needed. Existing Network `0DBaj000006bf3xGAA` is UnderConstruction, never
activated. `OwnerPortalFoundationController` deliberately rejects a non-Live site. Builder preview,
admin access and mock/local state tests are not successful customer login.

No user creation, invitation, membership/share change, data repair or publication is authorized by
this script. Even Case/comment submission requires a separate approved write-UAT/data scope.
Never access ng-dev or use an API/session token as a demo persona credential. Store no credentials
in evidence. Keep A and B in separate browser profiles and sign out between identity changes.

Approved synthetic Contact references (not login credentials or ownership proof):
- A: `003aj00002Xl4IfAAJ`, Account `001aj000049ZoXNAA0`.
- B: `003aj00002Xl4IgAAJ`, Account `001aj000049ZoXOAA0`.

Neither pair has verified vehicle ownership/service history. Do not attach old deliveries,
reservations, appointments or loyalty transactions merely to fill a demo screen.

## 2. Current evidence-only walkthrough — safe now

1. Review Batch B deployment receipt `evidence/P8/BATCH_B_DEPLOYMENT/quick_deploy.json` and
   effective readback: both email flags false, base Case Create/Edit off, no customer assignments.
2. Review the 9/9 Apex / 86.667% and previous 12/12 UI-state validation receipts. Explain that
   positive tests use rolled-back Plus users, real permission checks and USER_MODE queries.
3. Show the six local Batch C bundles/source and focused 19-test receipt. Do not claim local
   state/contrast arithmetic is rendered-browser or actual-persona acceptance.
4. Review the explicit ownership warning/disabled appointment step in source; it is a genuine
   dependency, not an available booking feature. No fake ownership/appointment success screen.

## 3. Future approved authenticated walkthrough

Execute only after gate 1 is satisfied. Use the actual owner-approved site URL/route; do not
invent a portal component route. Record the deployed build ID and browser/persona first.

1. As guest, verify no customer widgets/data/Apex results appear. Sign in as A using the approved
   normal login. Record actual license/user type/Contact and current site membership evidence.
2. Follow the skip link and section navigation with keyboard only. Check focus lands at the
   requested section, headings remain readable at 200% zoom and no color-only status is used.
3. Review A's dashboard: visible open-Case count, next own eligible appointment, stored points/tier.
   Denied data must say unavailable; missing eligible data must not invent history or balances.
4. Review service visits and dated mileage. Values belong to A's Contact; a linked Case must also
   belong to A. Loaded readings are not a single-vehicle odometer curve or ownership proof.
5. Review own Case list/status and published comments. Internal notes must not appear. If write
   UAT is separately approved, submit one approved test Case/comment and verify Contact/account,
   Service record type, service queue and read-back. Do not close/reassign/edit existing Cases.
6. Review stored loyalty balance and paged transactions; do not accrue, redeem, expire, recalculate
   or rewrite ledger entries. Test an actual missing/denied state without broadening permissions.
7. Confirm Vehicles/appointment creation remain disabled until ownership is explicitly approved.
   Do not describe a Case submission as a service booking or reservation as ownership.
8. Sign out; open B's isolated browser profile. Execute the per-object negative matrix using known,
   approved foreign IDs and compare real results, not empty-seed assumptions. An empty dataset
   alone cannot prove isolation. Record failures without broad grants as a workaround.

## 4. Responsive and accessibility evidence

Capture real approved-persona screens at 320px, 768px and 1440px; test 200% zoom, keyboard order,
focus after Case selection/form errors, reduced motion and a screen reader. Use filenames in
`evidence/P8/uat/README.md`. Avoid credentials/tokens or unnecessary customer details in captures.
Do not create placeholder screenshots or label an admin/local mock as customer evidence.

## 5. Close without self-acceptance

Fill `evidence/P8/uat/PORTAL_UAT_MATRIX.md` with the actual actor, timestamp, build, raw response
or screenshot and PASS/FAIL/BLOCKED. Record every skipped prerequisite. No publication rollback,
data cleanup, profile swap or Git release action is implied. Owner acceptance and M4 remain
separate; preserve all Phase 5–7 and ownership exceptions.
