# Minimal Northgate Owner Portal placement plan

**Current §71:** final broker package is deployed `0Afaj00000pPottCAC`; owned detail/photo and
appointment requests are implemented behind current server ownership/service-consent checks.
Empty/no-entitlement states remain safe. Only Home is exposed and composes all sections; no
Builder Save/placement/navigation/publication has occurred. Older disabled/local-only feature
notes below are historical. Operational data/identity/access and explicit Builder/publication
approvals are still required; broker deployment is not page placement or actual-customer UAT.

**PLAN ONLY — no Builder save, page assignment, theme change or publication.**
Target Network `0DBaj000006bf3xGAA`, Customer Service (Aura), existing `/owners` domain.
Live Network/CustomSite/NavigationMenu XML retrieved read-only under
`evidence/P8/OPERATIONAL_PREPARATION/configuration/`. Builder visual inventory remains BLOCKED:
Browser MCP has no connected tab. No guessed ExperienceBundle/routes metadata is generated.

## Placement supported by the deployed source

Only `ownerPortalHome` has `isExposed=true`, target `lightningCommunity__Page`. All five child
bundles have `isExposed=false`. Therefore the smallest supported first release is **one authenticated
Home page with one Northgate Owner Home component**, NOT six standalone Builder page placements.
Home already composes the five children; duplicating them or inventing routes is unnecessary.

| Logical page/section | Component placed/rendered | Proposed navigation |
|---|---|---|
| Customer Home (existing Home page, intended `/owners/s/`) | Place `ownerPortalHome` once in the main content region | Native site menu: `My portal` → Builder's Home page reference |
| Overview | Home dashboard: open Cases, next own appointment, stored loyalty, ownership warning | Existing component `Overview` action focuses dashboard |
| My Vehicles | Nested `ownerPortalVehicles` | Component `Vehicles` action; remains ownership-unconfigured |
| Service history | Nested `ownerPortalHistory` | Component `Service history` action; own dated visits/mileage/linked Cases |
| Appointment request | Nested `ownerPortalAppointment` | Component `Appointments` action; disabled, no booking claim |
| Support / My Cases | Nested `ownerPortalCases` | Component `Cases` action; own published comments only |
| Loyalty & rewards | Nested `ownerPortalLoyalty` | Component `Loyalty` action; read-only stored values |
| Login / forgot password | Existing native login/reset pages, no custom business component | Standard native login and reset links |
| Logout | Native authenticated user/menu logout action | End site session, return to native login; verify with real persona |

The section action targets (`dashboard`, `vehicles`, `history`, `appointments`, `cases`, `loyalty`)
are handled inside the LWC using its whitelisted focus handler. They are not independent
Experience routes. Do not put unverified `#cases` deep links in the native site menu or promise
startup hash handling. No `/vehicles`, `/appointments` or `/loyalty` route currently demonstrated.
Separate routed pages would require a new explicit scope, exposure metadata, navigation changes
and tests; they are not necessary for the minimal release.

## Exact future Builder procedure (requires category-specific approval)

1. Connect the authenticated ng-demo browser. Setup → Digital Experiences → All Sites →
   Northgate Owner Portal → Builder. Read-only first: capture page list, Home route, login/reset/
   error/registration routes, theme regions, current navigation, component instances, access settings
   and publish status. Record actual routes; if no suitable Home page, return a bounded amendment.
2. Only after explicit Builder-save approval: place Northgate Owner Home once on Home, mark the
   intended customer content page login-required using the native available setting, retain native
   login/reset/error pages and disable self-registration. No standard record-detail/list components,
   inventory search/feed/record pages or public dealership-data surfaces added.
3. Replace the current default Topics navigation item only if included in that approval; native
   menu should be `My portal` plus native authenticated profile/logout control. Record actual
   native menu/page references; do not deploy invented NavigationMenu/ExperienceBundle identifiers.
4. Retain native accessible shell, remove only redundant template content/search/feed widgets
   specifically enumerated from step 1. No broad template/page deletions. Scope exact metadata
   after authorized Save, retrieve to evidence, diff/verify the intended change only. No publish.
5. Check desktop/mobile preview for layout only; admin preview does NOT pass Foundation or
   customer data UAT. Foundation intentionally rejects non-Live/internal contexts. Keep that gate.
6. Separate publication approval later: backup snapshot, verify permissions/shares/guest review,
   controlled publish/activation, immediately execute real A/B tests with stop/rollback criteria.

## Smallest branding and UX change

Reuse the deployed Northgate text wordmark, navy `#15324f`, teal `#006c70`, neutral `#1f2937`,
white and `#f3f6f8`. No corporate logo asset exists in this package. Do not add manufacturer
branding or assume an approved image logo. Owner approves text brand/palette visually before
publication; no new CSS/global theme overrides until actual shell mismatch is observed.

Mobile first: stacked sections, 40rem/64rem summary breakpoints; desktop summary grid. Native
Case/loyalty/history lists avoid mobile datatable issues. Mileage table scrolls locally. Verify
320/768/1440px, long content, 200% zoom and no page-wide clipping with real external personas.
Loading: status/live messages and aria-busy; errors: generic alert, no stale customer records;
eligible-empty: truthful no-history/no-member/unconfigured; denied: unavailable, never zero balance.
Guest Home renders sign-in-only branch; child direct Apex endpoints deny guest/internal/wrong-site.
Case/comment actions need approved write entitlement; read-only pilot must not be sold as end-to-end
self-service. Preserve skip link, section focus and input validation. Actual shell focus/AT behavior
and native logout/session caching still require browser tests.

No supported editable Builder source has been established in the available connected tools.
Local page metadata is deliberately not fabricated. Existing LWC metadata is the supported local
source; already deployed bundles are not modified or redeployed for this plan. SiteDotCom hash
investigation remains closed to further work absent new evidence; see prior focused findings.
