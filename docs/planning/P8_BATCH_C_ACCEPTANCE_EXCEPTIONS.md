# P8-10 / P8-11 local delivery and acceptance boundaries

**Current §66 supersedes deployment-approval/local-only status below:** Batch C six bundles deployed
`0Afaj00000pOUsQCAW` (6/6, zero errors/tests). Actual accessibility/real-persona acceptance remains
pending. Operational preparation/register: `P8_OPERATIONAL_COMPLETION_REGISTER.md`. Do not request
or rerun the completed Batch C deployment. Ownership, native sharing/authorization, identities,
Builder Save, publication and write-UAT remain distinct gates. No exceptions are silently closed.

## P8-10 — implemented locally, acceptance incomplete

Six existing bundles receive responsive, single-column-first layouts. Summary cards switch at
40rem/64rem; native Case actions work without mobile-unsupported Lightning datatables. History
uses native dated lists and a captioned, locally scrollable mileage table; loyalty uses reflowing
lists. Long words wrap; native navigation/Case buttons have 44px minimum heights. No new image,
third-party logo, JavaScript framework, public data surface or ownership access is introduced.

Northgate-owned text wordmark and a proposed navy/teal/neutral palette use #15324f, #006c70,
#1f2937, #ffffff and #f3f6f8. Source contrast arithmetic passes AA text/focus thresholds for the
tested pairs. Formal brand/visual approval is pending; no manufacturer/third-party art or invented
corporate logo is used. No actual logo file exists in this scope.

Keyboard/accessibility implementation: skip link and labelled navigation/main/sections; whitelisted
section focus; native buttons; expanded-state/comment-panel relationship; focus after Case selection
or input errors; input labels/help/required validation; status/error announcements; busy state;
native table caption/column headers; reduced-motion-safe navigation. Base Lightning controls keep
platform semantics/styles; their real shadow DOM, target size and AT behavior still need browser UAT.

Local Node tests cover state/focus invocation and source contracts, not physical keyboard navigation,
rendered breakpoints, screen-reader output, browser layout or full WCAG compliance. Real responsive
screenshots and viewport/zoom/AT verification remain NOT RUN. Do not call P8-10 accepted.

## P8-11 — preparation delivered, execution not passed

- `evidence/DEMO_SCRIPTS/portal.md` opens with Activate persona, uses separate external A/B identities
  and explicitly prohibits the internal role-switch script/admin context as proof.
- `evidence/P8/uat/PORTAL_UAT_MATRIX.md` retains per-object/same-Account negatives, positive own
  data, writes, empty/error/denied and keyboard/mobile/AT states. Every live row is BLOCKED.
- `evidence/P8/uat/README.md` specifies real evidence filenames/metadata without fake screenshots.
- `docs/architecture/EXPERIENCE_PORTAL.md` separates deployed native/custom capability, local polish,
  test fixtures, blocked ownership and actual operational acceptance. No simulation fallback selected.

## Exact next approvals — separate decisions

1. Six-bundle Batch C deployment, `manifest/p8-batch-c-local.xml`; no Apex/profile/permission/Network
   or data components. Review UI/brand changes and the successful check-only before approving.
2. Site page placement/configuration, separately scoped from those six component definitions.
3. Two named Plus identities, mailboxes, minimum permission assignments, membership and narrow
   per-object visibility after actual license/relationship review. No automatic sharing writer.
4. Approved ownership contract and evidence before any owned-vehicle/photo/appointment implementation.
   Do not create historical associations or treat a reservation as ownership.
5. Controlled site publication and actual persona UAT, with separate explicit Case/comment write
   test scope if needed. The Live-site gate means successful real positive endpoint UAT cannot
   be claimed on the present UnderConstruction site. Builder preview is not a workaround.
6. Owner acceptance of exceptions/results; no M4, clean release/Git tag or earlier-phase acceptance
   is inferred from deployment success. CP2 and existing functions remain protected.
