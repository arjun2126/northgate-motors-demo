# Salesforce Platform screenshot inventory

[Return to the project gallery](../../../README.md#salesforce-platform-gallery)

All 21 November 9, 2026 uploads were inspected. The descriptively named files in the six
subdirectories below are **sanitized gallery copies**, not renamed originals. Original
`Screenshot 2026-11-09 at … PM.jpg` uploads remain byte-for-byte unchanged in the private source
checkout, not this published gallery. They contain identifying information and are not published.
The source timestamps below map each copy to its original; originals are deliberately not linked.

## Scope and privacy

- Browser tabs, org URLs, URL record IDs, bookmarks, avatars and device notifications are cropped out.
- Modal captures exclude background lists and embedded screenshot previews. Other captures are
  reframed to remove previews, detail tables and vehicle photography (including potential plates).
- Solid dark masks remove personal/audit names, contact values, member identifiers, VINs, street
  addresses/postal codes, quote references and report staff names where retained in the crop.
  Even apparently synthetic person/vehicle identifiers are treated conservatively.
- Demo object numbers, seed tags, the explicitly named test Account/persona, fictional location
  labels and illustrative prices remain. These are not credentials or publication approval.
- Copies are RGB progressive JPEGs, quality 86, with no inherited EXIF, XMP, ICC, comments or
  embedded thumbnails. Maximum width is 1,600 px; maximum height is 1,800 px. Open an image
  directly for legible field labels; the README uses smaller side-by-side previews.
- Copies total **1,873,187 bytes**, versus **14,002,019 bytes** for the originals: **86.6% smaller**.
  Keeping originals means these copies add storage; they do not shrink the local source archive.
- Local OCR plus visual review is a scoped privacy check, not proof that the entire repository
  is publication-safe. Existing website screenshots and documentation are unchanged, including
  their existing privacy warnings. GitHub-hosted rendering awaits separately approved publication.

## Sales and delivery

**Consultant skills:** lead lifecycle, customer context, test-drive intake, appraisal and handoff
requirements. **Developer skills:** standard Lightning record UI, custom objects, lookup fields,
financial field presentation and checklist layouts.

| ID / original time (PM) | Sanitized image / feature | Dimensions | Bytes | Additional privacy treatment |
|---|---|---|---:|---|
| 01 / 4.47.04 | [Lead Path and activity](sales/lead-path-and-activity.jpg): native status path, activities, duplicate and campaign panels | 1600 × 506 | 66,965 | Lead name and email masked |
| 02 / 4.47.43 | [Account details](sales/account-record-details.jpg): native Account layout and activity workspace | 1600 × 770 | 84,914 | Audit identities masked; explicit test Account retained |
| 03 / 4.48.29 | [New Test Drive](sales/test-drive-create.jpg): custom vehicle/contact, scheduling, outcome and feedback fields | 1116 × 1466 | 110,788 | Owner masked; background contact list and IDs excluded |
| 04 / 4.48.36 | [New Trade-In](sales/trade-in-create.jpg): custom appraisal, payoff, condition and wholesale fields | 1116 × 1457 | 109,059 | Owner masked |
| 05 / 4.48.42 | [Trade-In equity details](sales/trade-in-equity-details.jpg): stored appraisal, payoff and equity presentation | 1600 × 852 | 75,471 | Contact, opportunity, appraiser, owner and audit values masked |
| 06 / 4.48.46 | [Delivery handoff](sales/delivery-handoff-details.jpg): custom status and documents/inspection/walkthrough/signature checklist | 1600 × 869 | 68,725 | Household opportunity and audit identities masked |
| 07 / 4.48.51 | [New Delivery](sales/delivery-create.jpg): custom relationships, accessories multi-select and checklist | 1116 × 1681 | 113,056 | Modal-only crop excludes background and capture thumbnail |

## Inventory and locations

**Consultant skills:** stock status, location hierarchy and service capacity requirements.
**Developer skills:** custom-object list views, pricing/aging field presentation and lookup modeling.

| ID / original time (PM) | Sanitized image / feature | Dimensions | Bytes | Additional privacy treatment |
|---|---|---|---:|---|
| 08 / 4.48.56 | [Vehicle list](inventory/vehicle-list-statuses.jpg): custom inventory status list | 1600 × 1287 | 108,337 | Entire VIN column and capture thumbnail cropped out |
| 09 / 4.49.00 | [Vehicle details](inventory/vehicle-record-details.jpg): custom model, pricing, stock status and inventory age | 1600 × 752 | 65,539 | VIN masked; vehicle photo and capture thumbnail excluded |
| 10 / 4.49.07 | [Rooftop details](inventory/rooftop-record-details.jpg): custom location type, activity flag and service capacity | 1600 × 631 | 54,971 | Street/postal code, owner and audit identities masked |

## Loyalty

**Consultant skills:** membership lifecycle, rewards tiers and ledger requirements.
**Developer skills:** member/transaction relationships and audit-oriented data modeling.
These are custom objects, **not Salesforce Loyalty Management**. The transaction's displayed
type/reason and dates are captured as-is; no ledger correctness or accrual execution is inferred.

| ID / original time (PM) | Sanitized image / feature | Dimensions | Bytes | Additional privacy treatment |
|---|---|---|---:|---|
| 11 / 4.49.11 | [Member details](loyalty/loyalty-member-details.jpg): tier, balance and lifetime activity | 1600 × 710 | 59,342 | Contact/member number masked; audit section excluded |
| 12 / 4.49.15 | [New Loyalty Member](loyalty/loyalty-member-create.jpg): enrollment, tier and lifetime fields | 1116 × 1328 | 95,208 | Modal-only crop |
| 13 / 4.49.22 | [Transaction details](loyalty/loyalty-transaction-details.jpg): points, type, reason, expiry and related records | 1600 × 593 | 50,877 | Audit names masked; personal device notification excluded |

## Finance and approvals

**Consultant skills:** financing estimates, draft workflows and approval requirements.
**Developer skills:** custom Financing object, LWC quick action, Apex-backed estimates and native
approval integration. Illustrative demo rates are not lending offers; the approval dialog does
not prove submission, routing, locking or approval completion.

| ID / original time (PM) | Sanitized image / feature | Dimensions | Bytes | Additional privacy treatment |
|---|---|---|---:|---|
| 14 / 4.49.33 | [Financing details](finance/financing-record-details.jpg): stored amount, term, interest, payment and rate-source fields | 1600 × 395 | 42,830 | Opportunity, applicant and quote reference masked |
| 15 / 4.49.37 | [Finance Application](finance/finance-application-action.jpg): existing draft, quote selection, rate choices and estimate | 1116 × 1353 | 112,651 | Selected quote and applicant values masked; modal-only crop |
| 16 / 4.49.42 | [Submit for Approval](finance/financing-submit-for-approval.jpg): native comments/submission dialog | 1116 × 729 | 34,901 | Dialog crop excludes identifying background values |

## Analytics

**Consultant skills:** KPI design, stakeholder reporting and interpreting cached data.
**Developer skills:** native matrix report groupings, aggregate measures and dashboard components.
Historical dashboard snapshots have different refresh dates and populations; totals should not
be read as reconciled live metrics. Neither viewer access nor service SLA/CSI correctness is
proved by a screenshot. The executive service metrics are cached proxies, not live monitoring.

| ID / original time (PM) | Sanitized image / feature | Dimensions | Bytes | Additional privacy treatment |
|---|---|---|---:|---|
| 17 / 4.50.17 | [Pipeline by Stage](analytics/pipeline-by-stage-report.jpg): native stage × sales-staff matrix with sums/counts | 1523 × 678 | 156,514 | Staff header names masked; all detail rows excluded |
| 18 / 4.50.41 | [Executive operations](analytics/executive-operations-dashboard.jpg): pipeline, inventory aging, service and loyalty tiles | 1600 × 496 | 59,143 | Viewing-as identity masked |
| 19 / 4.50.57 | [Sales pipeline](analytics/sales-pipeline-dashboard.jpg): stage chart, opportunity count and lead-source conversion | 1600 × 995 | 145,131 | Viewing-as identity masked |

## Service

**Consultant skills:** workshop intake, staff assignments and scheduling requirements.
**Developer skills:** custom Service Visit versus standard Service Appointment modeling,
required fields and lookup relationships. The standard appointment form does **not** establish
a licensed Field Service deployment, dispatch optimization or successful booking.

| ID / original time (PM) | Sanitized image / feature | Dimensions | Bytes | Additional privacy treatment |
|---|---|---|---:|---|
| 20 / 4.51.09 | [New Service Visit](service/service-visit-create.jpg): custom vehicle/contact, staff, labour, parts and work fields | 1116 × 1670 | 127,819 | Owner masked; background scheduling records excluded |
| 21 / 4.51.20 | [New Service Appointment](service/service-appointment-create.jpg): standard parent record, time window, address and status fields | 1115 × 1800 | 130,946 | Modal-only crop excludes surrounding application |

## Review boundaries

Inventory links use relative, case-sensitive paths and browser-supported JPEGs. See the local
review package at `evidence/salesforce-gallery-review/` for original/copy SHA-256 hashes,
crop/mask coordinates, raw OCR, local checks and preservation receipts. That package contains
private originals-derived information and is **not** part of the publication-candidate gallery.
No Salesforce orgs were accessed and no application functionality was changed for this gallery.
