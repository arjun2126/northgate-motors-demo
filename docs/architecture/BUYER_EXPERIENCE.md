# Buyer experience architecture

Status: published 2026-11-01. Acceptance detail is in [acceptance status](../ACCEPTANCE_STATUS.md).

The public Buyer experience is an Aura Experience Cloud site using the Customer Service template.
One LWC, `ngBuyerSite`, renders all six public pages from an explicit `page` attribute rather than
URL parsing; `all` remains the legacy single-page fallback.

| Slug (`/owners/s/…`) | `ngBuyerSite.page` | Content |
|---|---|---|
| `buyer` | `home` | cinematic hero, range-by-family grid, trust strip |
| `buyer-inventory` | `inventory` | 87-listing catalogue (demo org data), six filters, 12 per page |
| `buyer-vehicle` | `vehicle` | detail via `?c__vehicle=<public DTO id>`; bare URL shows a Browse-inventory state |
| `buyer-studio` | `studio` | Apex Concept 3D studio, three finishes, Priority List |
| `buyer-about` | `about` | disclosure, Owner Portal entry |
| `buyer-contact` | `contact` | inquiry form, what-happens-next copy |

## Data and security

`BuyerShowcaseController.getShowcase` returns a public catalogue DTO — models, vehicles, choice lists
and counts. Guests receive no native object permissions and no record reads beyond that DTO.
`BuyerInquiryController.submit` validates a fixed field set, enforces the `.test` / `.example` demo
email rule, inserts a Lead in system mode to the queue named by custom label `Buyer_Lead_Queue_Id`,
and returns an `NG-XXXXXX` reference derived from the Lead Id. Read paths remain user-mode.

## 3D studio

`ngApexConcept3d` loads a pinned Three.js viewer and licensed glTF asset from static resources,
renders orbit/zoom/front-side-rear camera controls, and applies three visual paint finishes. It
degrades to a poster on touch or low-capability devices rather than rendering a blank stage. The
Priority List action carries only an allowlisted finish — never a vehicle, price or allocation.

## Inventory filters

Model options are scoped to the selected family, and a family change clears an incompatible model, so
the two dependent filters cannot combine into a guaranteed-empty result. Pagination resets on every
filter change; independent filters (body, colour, condition, price) are unaffected.

## Verification notes

Live results are summarised in [acceptance status](../ACCEPTANCE_STATUS.md). Validation receipts are
kept in the private engineering register and are not published with this repository.
