# Owner Portal structural redesign — local implementation record

**Date:** 2026-10-28
**Mode:** local implementation only. **No org access, dry-run, deployment, Builder assignment,
publication, data change or Git write was performed.** Rendered/browser acceptance is **SKIPPED**,
not passed.

Target (for a future, separately approved deployment): `ng-demo` / `00Daj00001Ae3iWEAR` only.
`ng-dev` is untouched and unauthorized.

## 1. Files created or modified

### Created — Experience Cloud layouts

```text
force-app/main/default/aura/ngOwnerThemeLayout/ngOwnerThemeLayout.cmp
force-app/main/default/aura/ngOwnerThemeLayout/ngOwnerThemeLayout.css
force-app/main/default/aura/ngOwnerThemeLayout/ngOwnerThemeLayout.cmp-meta.xml
force-app/main/default/aura/ngOwnerContentLayout/ngOwnerContentLayout.cmp
force-app/main/default/aura/ngOwnerContentLayout/ngOwnerContentLayout.css
force-app/main/default/aura/ngOwnerContentLayout/ngOwnerContentLayout.cmp-meta.xml
```

### Modified — portal shell (presentation/navigation only)

```text
force-app/main/default/lwc/ownerPortalHome/ownerPortalHome.js
force-app/main/default/lwc/ownerPortalHome/ownerPortalHome.html
force-app/main/default/lwc/ownerPortalHome/ownerPortalHome.css
```

### Modified — local tests (intentional architecture change, not removed expectations)

```text
scripts/tests/p8_portal_presentation.test.mjs
scripts/tests/p8_batch_c_ui.test.mjs
scripts/tests/p8_batch_b_ui.test.mjs
```

### Created — proposed manifest and this record

```text
manifest/owner-portal-structural-local.xml
docs/planning/OWNER_PORTAL_STRUCTURAL_REDESIGN_2026-10-28.md
```

### Unchanged

All five child LWC bundles (`ownerPortalVehicles`, `ownerPortalAppointment`,
`ownerPortalHistory`, `ownerPortalCases`, `ownerPortalLoyalty`) — **JavaScript byte-identical**
(hashes enforced by `p8_portal_presentation.test.mjs`). No Apex, permissions, profiles, sharing,
records, pricing, approvals, authentication, Network membership or Site.com archive changes.

The portal LWC bundles remain **untracked** in this shared working tree, as they were before this
task. Nothing was staged, committed or pushed.

## 2. Layout architecture

| Layer | Component | Effect |
|---|---|---|
| Theme layout (Home override) | `ngOwnerThemeLayout` (`forceCommunity:themeLayout`) | Charcoal brand header, native `profileMenu` (account/logout), `{!v.body}` with no centered 1140px wrapper |
| Content layout (Home page) | `ngOwnerContentLayout` (`forceCommunity:layout`) | One full-width `content` region; no sidebar, no column gutters |
| Page component | `ownerPortalHome` | Multi-view application shell; renders one view at a time |

The 1140px cap measured in the live site came from `.siteforceServiceBody .cCenterPanel`, i.e. the
built-in `siteforce:serviceBody` theme, not from the LWC. Replacing the theme layout removes that
ancestor instead of fighting it with `100vw`, negative margins or overrides of Salesforce internals.
The shell itself uses `max-width: none` and `width: 100%`; readable measure is limited only inside
specific text/form blocks where appropriate.

**Theme layout assignment is per page.** Experience Builder theme layouts group pages and can be
overridden in a single page's properties ("Override the default theme layout for this page"), so the
new theme layout is applied to Home only. The existing Default and Login theme layouts are left
untouched; login, password and error pages keep their current structure and authentication flow.

## 3. Navigation architecture

Five primary views — Dashboard, My Garage, Service, Support, Rewards.

| View | Content |
|---|---|
| Dashboard | Hero, next appointment summary, open-Case count, stored loyalty balance, garage shortcut, ownership/eligibility message, clearly non-interactive "Planned experiences" list |
| My Garage | `ownerPortalVehicles` (lazy-mounted on first visit) |
| Service | Sub-views: **Appointments** summary, **Request service** (`ownerPortalAppointment`), **History & mileage** (`ownerPortalHistory`) |
| Support | `ownerPortalCases` (Case list, published comments, forms) |
| Rewards | `ownerPortalLoyalty` (read-only membership/activity) |

### URL and history contract

- View state lives in namespaced query parameters on the same authenticated page:
  `?c__view=<dashboard|garage|service|support|rewards>` and, for Service,
  `?c__service=<appointments|booking|history>`.
- `CurrentPageReference` (wire) reads state on load, refresh, deep link and browser Back/Forward.
- `NavigationMixin.Navigate` writes history; no custom router or `popstate` handler is installed.
- Target construction is type-aware:
  - `comm__namedPage` / `standard__namedPage` → router `state` object.
  - `standard__webPage` → the same parameters carried in the URL (that reference type has no state
    channel). The rendered `href` fallback is identical, so open-in-new-tab, refresh and copied
    links work even if the router chooses a full navigation.
- Unknown/malformed targets fall back to Dashboard with a customer-safe announcement. Links cannot
  navigate to a view outside the allowlist.

### State retention and focus

- A child is mounted on first visit and then kept mounted; inactive panels use `hidden` plus
  `[hidden] { display: none !important; }`, so they leave layout, tab order and the accessibility
  tree while retaining drafts, selected Case, in-flight requests, booking `requestKey`, review state
  and receipt.
- Navigating back to a previously visited view reuses the same child instance; it is not recreated.
- After a genuine view change, focus moves to the new view heading (`tabindex="-1"`), and a polite
  live region announces the view name.
- Mobile: 44px menu button with `aria-expanded`/`aria-controls`, Escape closes and restores focus to
  the toggle. Desktop navigation is always visible and uses `aria-current="page"`.

## 4. Visual direction

- Charcoal `#171a1f` navigation/header, near-black `#20242a` hero, light neutral `#f5f7fa` canvas.
- Electric-blue accent `#135de6` (hover `#104cbf`); blue-tinted focus rings.
- System/Salesforce Sans typography, tightened heading tracking, restrained radii and borders.
- Responsive: single column below 40rem; 2-up summaries at 40rem; 4-up at 64rem; hero splits at
  48rem. Mobile-first CSS; no fixed pixel minimum widths.
- Vehicle imagery remains the existing component's truthful handling: selected photo when
  available, neutral fallback and illustrative-photo disclosure. No stock recolouring.

## 5. Validation performed (local only)

| Check | Result |
|---|---|
| `node --test scripts/tests/{p8_portal_presentation,p8_batch_b_ui,p8_batch_c_ui,p8_broker_ui}.test.mjs` | **37/37 pass** |
| `bash harness/check.sh focused portal` | **26/26 pass**, preservation PASS |
| `bash harness/check.sh` (fast) | PASS, preservation PASS |
| Child JS byte-preservation | Enforced by test (five hashes unchanged) |
| Five views reachable | Source: allowlist/panel/wiring tests pass; **rendered reachability SKIPPED** |
| Back/Forward, refresh, deep link | Source: state contract tested; **runtime SKIPPED** |
| Booking review → receipt | Appointment JS byte-preserved; **runtime flow SKIPPED** |
| Form state across view changes | Mount-retention flags tested; **runtime SKIPPED** |
| Keyboard/screen reader | Source ARIA/focus rules tested; **actual assistive-technology pass SKIPPED** |
| Apex contract/security tests | **SKIPPED** — no server-side validation authorized |
| Metadata dry-run / deployment | **SKIPPED** — not authorized |
| LWC/Aura compilation | **SKIPPED** — no local compiler; source-level checks only |
| 320/768/1440 rendered layout | **SKIPPED** — no deployment/publication |
| Logged-in A/B isolation and journeys | **SKIPPED** — no org interaction |

Source assertions cover: allowlisted navigation, invalid-target fallback, mounted-child retention,
handler wiring, balanced templates, unique IDs, resolvable ARIA references, non-interactive planned
features, contrast arithmetic, breakpoint structure, and absence of Apex writes or open redirects.

### Rendered evidence

**No screenshot or rendered preview is available.** The LWC/Aura runtime, Experience Builder and org
deployment are not available locally, and org interaction is not authorized in this task. Visual,
responsive and screen-reader acceptance must be captured after a future approved
deployment/publication; this record makes no visual acceptance claim.

## 6. Proposed deployment manifest (not executed)

```text
manifest/owner-portal-structural-local.xml
```

Contains exactly: `ngOwnerContentLayout`, `ngOwnerThemeLayout` (AuraDefinitionBundle) and the six
`ownerPortal*` LightningComponentBundles. No Apex, permissions or site metadata.

Recommended order, each step separately approved:

1. Check-only / dry-run of the manifest against verified `ng-demo`.
2. Deploy the two Aura bundles alone (unassigned; inert until Builder uses them).
3. Deploy the six LWC bundles, ideally in the same approved window as the Builder change, because
   `ownerPortalHome` changes behavior immediately for the Live Aura site.
4. Builder configuration, preview, then publication.

## 7. Exact Builder steps (future, separately approved)

Preconditions: deployment complete; owner has approved the Home-only layout override.

1. Open Experience Builder for **Northgate Owner Portal** (`Northgate_Owner_Portal1`, Aura/Live).
2. **Settings | Theme | Configure → New Theme Layout** (a theme layout type, e.g. **Owner**), and
   assign **Northgate Owner Experience** (`ngOwnerThemeLayout`) as its theme layout component.
   - Keep the **User Profile Menu** component for the `profileMenu` region; it provides the native
     account/profile/logout control.
   - Do not add a search component or a Navigation Menu component to this theme layout.
3. **Home → Page Actions → Page Settings → Properties:** select **Override the default theme layout
   for this page** and choose **Owner**. Leave the existing **Default** and **Login** theme layouts
   unchanged so login, password and error pages are untouched.
4. **Home → Page Actions → Change Layout:** select **Northgate Owner Experience: one full-width
   content region** (`ngOwnerContentLayout`).
5. Confirm `ownerPortalHome` sits in the `content` region. The previous sidebar placements
   (Recommendations, Reputation Leaderboard) and standard community footer are not rendered by this
   layout; no replacement component is needed.
6. Do **not** add an Experience Builder navigation menu, search component or additional portal
   components; the shell owns navigation.
7. Preview: sign-in page is unchanged and sign-in succeeds; all five views open; `?c__view=support`
   deep link works; Back/Forward works; refresh retains the view; 320/768/1440 widths are usable.
8. **Publish** only after those checks pass.

No Site.com archive was or should be hand-edited. No ExperienceBundle metadata was enabled.

## 8. Post-publication verification (required before acceptance is claimed)

1. Authenticated A session: every view, every existing child workflow, booking review → receipt,
   Case comment, loyalty read-only states.
2. Deep link, refresh, Back/Forward, invalid `c__view`, open-in-new-tab.
3. Confirm the navigation mechanism actually updates the view in the Aura runtime without a full
   reload (the `standard__webPage` branch is the fallback; if the router performs a full navigation,
   drafts are lost and the state-retention claim must be re-evaluated).
4. Keyboard-only and screen-reader pass; hidden panels absent from the accessibility tree.
5. B/C identities: no cross-customer data; ownership and servicing authorization unchanged.
6. Confirm D06 loyalty read/FLS and D07 Case-comment defects are unchanged — this work neither fixes
   nor conceals them.

## 9. Remaining owner decisions

- Confirm that the Home page, and only Home, overrides the default theme layout (the approved
  architecture); other owner pages can adopt it later if needed.
- Approve removal of the Recommendations, Reputation Leaderboard and standard community footer from
  this portal.
- Decide whether `/owners/s/` remains the public URL.
- Decide whether D06/D07 are addressed separately.

## 10. Rollback

Builder: reassign the previous theme layout and Home content layout, restore the sidebar widgets and
publish. Source: revert the six LWC bundles and remove the two Aura bundles in a separately approved
change. No data migration is involved.
