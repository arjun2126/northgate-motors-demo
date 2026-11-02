# Acceptance status

As of 2026-11-01. Scope: the Northgate Motors demo org (`ng-demo`, Developer Edition) and the
published Buyer experience.

PASS means the stated check was executed and observed. It does not mean the whole product is
accepted. Where a check was not run, it is listed as deferred rather than assumed. Validation
receipts live in the private engineering register and are not published with this repository.

## Buyer experience — accepted

| Requirement | Status | How it was verified |
|---|---|---|
| Six public routes exist and render their own mode | **PASS** | Anonymous browser probe of `/buyer`, `/buyer-inventory`, `/buyer-vehicle`, `/buyer-studio`, `/buyer-about`, `/buyer-contact`: distinct heading, one component instance each, zero horizontal overflow at 1440 and 390 |
| Navigation between pages | **PASS** | Five-hop click walk, each destination resolved with the expected heading |
| Inventory catalogue, six filters, pagination | **PASS** | 87 listings, 12 per page, 8 pages, filters narrow and Clear resets |
| Dependent family/model filters | **PASS** | Defect reproduced live (family 11 → foreign model 0), fixed, redeployed and re-verified: scoped model list, family switch clears an incompatible trim |
| Vehicle details and deep links | **PASS** | `?c__vehicle=` renders title, price, seven specifications and actions; bare and invalid ids show a Browse-inventory state without error |
| 3D Studio | **PASS** | Hardware WebGL canvas 818×512, drag changed 21% of canvas pixels, wheel zoom 25%, Pearl finish selected and reflected in the Priority List |
| Priority List handoff | **PASS** | Prefill carries only the allowlisted finish; no vehicle, price or allocation; disclaimers visible |
| Guest inquiry end-to-end | **PASS (once)** | One synthetic submission, reference `NG-APJEAW`, exactly one Lead created, no duplicate after reload |
| Lead routing | **PASS, documented** | Owner = `Inbound Leads` queue. The active `Standard` assignment rule did not apply to the Apex insert; noted for future changes |
| Guest isolation | **PASS** | Buyer routes public; `/owners/s/`, `/owners/s/login` and every `c__view` deep link (`dashboard`, `garage`, `support`, `rewards`, `service&c__service=booking`) redirect to login with no portal component rendered (seven probes) |
| Source parity after deployment | **PASS** | 8/8 normalised files match the reviewed source |
| Local regression | **PASS** | 80/80 Buyer contracts, full harness PASS, preservation conflicts none |

Known cosmetic issues, not acceptance blockers:

- No `<link rel="icon">`, so browsers request `/favicon.ico` and log a 404.
- At 320 px the Studio camera toolbar uses two rows (deliberate layout, slightly tight).
- Some demo vehicles have no listing for a given trim (`Aurelia Sport`), which shows the honest empty
  state. A future enhancement could hide zero-listing trims.

## Owner Portal — previously accepted, not retested this cycle

| Requirement | Status | Note |
|---|---|---|
| Portal is login-gated | **PASS (anonymous)** | Root and every `c__view` deep link redirect to login |
| Authenticated dashboard, garage, service, support, rewards | **NOT RETESTED** | Accepted at Core 1.0; latest code was not changed by Buyer 3.1 deployments |
| Customer Case creation | **DEFERRED** | Accepted deferral D07; Case remains read-only for customers |

## Core 1.0 accepted exceptions (unchanged)

| ID | Accepted | Still not claimed |
|---|---|---|
| D05 | Missing canonical `data/csv/` accepted | CSV provenance not restored |
| D07 | Published-comment submit/readback verified; Apex/client fixes deployed | Live Case creation and negative foreign-Case security not executed |
| D08-a | Print correction deployed and observed | Residual print/PDF shell formatting |
| D08-b/c/d | Finance banner, Executive layout, licensed stock accepted | — |
| D09 | Conditional live-persona limitation accepted; automated security evidence retained | Live Finance/Service/dual-role app acceptance |
| D10 | Consent/service/SLA/loyalty/Knowledge automated requirements retained | Loyalty jobs, SLA timers, Knowledge publication, consent writes remain disabled |
| D11 | 4.2 MB storage accepted against a 5.0 MB limit | Report/tile parity and historical provenance |
| D12 | Rich Text N/A workaround verified read-only | Static copy does not refresh automatically |
| D13 | Capability seams reconciled | Live VIN transport, territory activation, Agentforce, Data Cloud |
| D14 | 381/381 controlled regression, 92% org coverage | 19 classes below 90% individually (org gate met) |

## Deferred or unverified

- Screen-reader output (VoiceOver/NVDA), keyboard-only walkthrough at 200% zoom, reduced-motion
  behaviour.
- Safari/WebKit on macOS and iOS; real Android and iOS devices.
- Direct anonymous Apex/REST probing of portal endpoints (route-level denial was verified; object-level
  guest permissions were accepted as zero at Core 1.0).
- A second inquiry submission or any test of duplicate-submission suppression beyond the single
  accepted run.
- Live VIN transport, territory activation, Agentforce, Data Cloud, loyalty jobs and SLA automation.

## Open defects

None open for the Buyer experience. The items under "known cosmetic issues" are recorded as
enhancements, not defects awaiting a fix.
