# React (Salesforce Multi-Framework) — Conditional Proposal for P7-18 Owner Portal

**Status:**
> "React via Salesforce Multi-Framework is under evaluation.
> Existing Experience Cloud/Lightning fallback remains authoritative until
> eligibility, licensing, security, and implementation cost are confirmed."

**Scope of this note:** Candidate 1 only — the P7-18 Owner Portal ("Northgate Owner Portal":
service history, appointments; 5 External Identity licences; Phase 7 / M3). This is a
conditional proposal, **not** an approved architecture or scope replacement. It does not
add a Deal Desk requirement, does not migrate any record-page LWC
(`quoteBuilder`, `quoteSummary`, planned `P4-02`, `P7-01/02/23`), and does not change
Phase 3 scope or repair (`P3-04..P3-12` handoff stays authoritative).

## 1. Why candidate 1

Multi-Framework **external** React apps are GA (July 16, 2026, Summer '26 baseline) and are
built for exactly this shape: a custom-branded, full-screen, customer-facing SPA surfaced
through an Experience Cloud site. React wins where LWC stays the default — record pages,
Flow screens, admin-configured surfaces. P7-18 is none of those. Record-page components in
this project remain LWC.

## 2. Pre-adoption conditions — every item must resolve before any adoption decision

| # | Condition | What to verify | Fail if |
|---|---|---|---|
| 1 | Target-org eligibility | `ng-dev` and `ng-demo` hosted on **Hyperforce** (instance name `Aaa123` pattern); org **default language is English** (`en_US` usable); on **Summer '26 or later** | Non-Hyperforce instance, or non-English default language |
| 2 | External-user licensing | **Digital Experiences enabled**; external portal users' licence type supports an *authenticated* portal. Salesforce docs name Customer Community / Customer Community Plus (B2C) and Partner Community (B2B) — **do not assume the available External Identity licences suffice** | Confirmed licence mismatch |
| 3 | Customer data access | `Case`, `Service_Visit__c`, `Vehicle__c`, `Loyalty_Member__c` (and related lookups) readable for external users under the sharing model; supported by **UI API / GraphQL** operations. **Do not assume every proposed object is supported** — test each | Any required object/operation unsupported for external users |
| 4 | Apex invocation options | Multi-Framework apps **cannot call `@AuraEnabled` Apex** (e.g. `QuoteBuilderController`, `QuotePricingService`). Only GraphQL via UI API and allow-listed Apex REST endpoints through the Data SDK (`sdk.fetch`) | Required logic has no GraphQL or `@RestResource` path |
| 5 | Domain / Edge configuration | The **Salesforce app domain** (`*.salesforce.app`) enablement is **one-way / irreversible**; **Edge Network required** for internal apps. Record current toggle states before any enablement decision | Irreversible setting cannot be accepted |
| 6 | Toolchain, testing, CI, maintenance | Repo has **no Node/npm/Vite toolchain today**; adding one is a project-level decision. Runtime deps: Node + Vite + `@salesforce/platform-sdk`. Tests use **Vitest, React Testing Library, Playwright** (not LWC Jest). CI `validate.yml` impact; **one UIBundle per push**; packaging/Translation unsupported | Toolchain/maintenance cost not accepted |

## 3. Internal vs external apps — keep enablement separate

| | Internal (B2E) app | External (B2C/B2B) app — the P7-18 candidate |
|---|---|---|
| Audience / auth | Employees, Salesforce credentials (SSO supported) | Experience Cloud guest or authenticated login |
| Access point | App Launcher (desktop + Salesforce mobile) | Experience Cloud site URL |
| Required org setup | Salesforce app domain enable (irreversible) + Edge Network; `CustomApplication` + permission set | Digital Experiences + external-user licences (verify, §2.2) |
| Template | `reactinternalapp` | `reactexternalapp` |
| Metadata types | UIBundle + CustomApplication | UIBundle + Experience Cloud site metadata (DigitalExperience, DigitalExperienceConfig, Network, CustomSite) |

## 4. Capability labels (as of this note)

- **GA:** Multi-Framework runtime (React); internal and external app patterns; Salesforce
  Data SDK (`@salesforce/platform-sdk`, GraphQL via UI API).
- **Beta:** UI Embedding / microfrontends — embedding a deployed UIBundle inside Lightning
  Experience or Experience Cloud pages via `lightning-ui-embedding`.
- **Developer Preview:** micro-frontend sample recipes.
- **Roadmap:** Angular support, managed packages, localization / Translation Workbench,
  App Manager management.

## 5. Sources (official)

- Salesforce Multi-Framework Overview —
  https://developer.salesforce.com/docs/platform/multiframework/guide/reactdev-overview.html
- Configure Your Org for React Development —
  https://developer.salesforce.com/docs/platform/multiframework/guide/reactdev-setup.html
- GA announcement (July 16, 2026) —
  https://developer.salesforce.com/blogs/2026/07/build-with-react-on-salesforce-multi-framework-is-now-ga
- Data-access contract for UI bundles (`@salesforce/platform-sdk`) —
  https://github.com/forcedotcom/sf-skills/blob/main/skills/experience-ui-bundle-salesforce-data-access/SKILL.md
- `@salesforce/vite-plugin-lwc-ui-bundle` limitations (Apex REST only; no `@AuraEnabled`) —
  https://cdn.jsdelivr.net/npm/@salesforce/vite-plugin-lwc-ui-bundle@12.8.0/docs/limitations.md

## 6. References

- Backlog: `DEMO_ORG_BACKLOG.md` P7-18 (owner portal).
- Architecture: `DEMO_ORG_MASTER_PLAN.md` §4.1 (Experience Cloud — BUILD NATIVE row),
  §11 A10; `docs/architecture/AUTOMATION_DIRECTION.md` (wizard/UI direction).
- Fallback (unchanged): permission-set-restricted Lightning app + self-service screen flow
  (`MASTER_PLAN.md` §4.2 fallback row), plus the P7-18 acceptance wording in the backlog.

Nothing in this note is an approved scope change. Adoption proceeds only after the §2
conditions resolve and the owner approves an amended P7-18 plan.