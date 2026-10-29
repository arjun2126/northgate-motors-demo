# P7-22 — real stock-photo sourcing, package and validation

## Owner scope and outcome

The owner explicitly replaces the planned AI-photo requirement with appropriately licensed real
automotive stock photography. Authorized: research, suitable downloads, local processing,
static-resource preparation and scoped check-only against ng-demo only. No actual deployment,
image/model record changes, permissions or Git staging/commit/push. Existing gallery source and
all inventory/VIN/image paths are unchanged.

**All 30 required photographs are complete locally, licensed, visually reviewed and packaged.**
No image/rights gap remains. Deployment and live browser/Salesforce rendering are deferred, not
passed. The prior Batch 1 application validation is reused; no Apex tests were rerun.

## Source/license research and selection

Sources reviewed:

- Pexels license: `https://www.pexels.com/license/`; terms:
  `https://www.pexels.com/terms-of-service/` (reported update October 20, 2026). Its current
  systematic-copying/standalone-redistribution and branded-use restrictions make it a poor fit
  for this reusable package. No Pexels photograph was downloaded for reuse or redistributed.
- Unsplash license/search/terms requests returned HTTP 401. No login/download control bypass
  or guessed CDN-photo substitution was attempted; no Unsplash photograph is used.
- Wikimedia Commons public imageinfo/search API supplies the selected photographs and explicit
  rights metadata. Every selected file has LicenseShortName=CC0, a CC0 1.0 URL on
  creativecommons.org and a nonempty photographer credit. Full per-file metadata snapshots
  remain under `photo_sources/<pageId>.json`.
- Official rights basis: `https://creativecommons.org/publicdomain/zero/1.0/` permits copying,
  modification and redistribution, including commercial use, without copyright permission.
  It does not grant trademark/patent/personality rights or endorsement. The package preserves
  incidental OEM badges and explicitly labels photographs as illustrative of fictional models,
  not exact inventory or manufacturer/photographer endorsement.

No copyrighted manufacturer press photography, unverified source, generative advertisement,
stock watermark, fake image or deceptive logo removal is included. The selected Commons pages
credit the individual photographers; exact original/download URLs and license URLs are recorded
per image, not inferred from a generic website permission.

Human visual review checked the entire source set and the processed contact sheet. Six candidates
were rejected for company-door branding, conspicuous show signage/crowds, weak distant view or
incomplete utility-truck presentation. Preferred front-three-quarter whole-vehicle shots dominate;
the registry openly records a rear-wagon and several side/elevated alternatives. Year matches
are approximate/generation-based where identified, not a claim that a real photograph depicts
the fictional named model or an exact real model year.

## Delivered artifacts

| Artifact | Path / contents |
|---|---|
| Thirty-row human inventory | `docs/assets/P7_VEHICLE_PHOTO_INVENTORY.md` — mapped filename/model/body, actual source photograph, photographer, license and size |
| Machine-readable source/license register | `docs/assets/P7_VEHICLE_PHOTO_SOURCES.json` — 30 original image URLs, download variants, photographer/source/CC0 records, dates, matching rationale, review notes and source/output hashes |
| Existing mapping, preserved keys | `docs/assets/P7_VEHICLE_IMAGE_MAP.json` — exact 30 filenames/model/body mapping, owner sourcing amendment; no record IDs or DML |
| Decomposed static resource | `force-app/main/default/staticresources/NG_VehicleImages/` plus `NG_VehicleImages.resource-meta.xml` |
| Deliverable ZIP | `evidence/P7/NG_VehicleImages.zip` — thirty root WebP files plus ATTRIBUTION.md and licenses.json |
| Visual review | `evidence/P7/photo_sources/contact-sheet.jpg` and `processed-contact-sheet.jpg` |
| Processing/research helper | `scripts/assets/vehicle_stock_photos.py` — public Commons API curation, selected downloads, full-frame conversion and inventory generation |
| Scoped verifier | `scripts/tests/check_p7_vehicle_photos.py` — complete assets/rights/ZIP checks and optional read-only target/path validation |
| Exact check-only manifest | `manifest/p7-22-images-check.xml` — NG_VehicleImages StaticResource only |

The original/downloaded candidate files are local research cache; only selected optimized WebP
files and the two attribution/register documents enter the resource. Rejected files never enter
the ZIP. CC0 avoids a new gallery attribution UI requirement; credits are still preserved in the
bundle and source register as requested. No gallery markup, behavior or component metadata changed.

## Download/processing controls

Downloads use the public Commons API-provided URLs and normal verified HTTPS. Python's local
certificate setup initially failed verification; OS curl uses its normal TLS trust store instead.
No certificate checking was disabled. A Commons 429 stopped fetching; collection paused for
cooldown, then resumed at a slower sequential cadence. Code rejects access/rate errors without
changing identities, cookies, hosts or credentials to bypass them. Only transient connection
failures have bounded retries. No restricted-site scraper or paid service was used.

Pillow verifies source decodability, applies EXIF orientation, proportionally resizes the entire
frame onto an 800×600 white canvas and encodes genuine WebP. No subject crop, logo removal,
background replacement or fake WebP extension. Quality search targets about 42–55 KiB where
practical, with a quality floor of 60 and ceiling of 90. Complex scenes remain larger rather
than aggressively destroying detail to force a nominal target. No artificial padding/noise is added.

## Final local and live-path validation

Command:

```sh
python3 scripts/tests/check_p7_vehicle_photos.py --live
```

CONFIRMED — raw final output:

```json
{
  "status": "PASS",
  "photos": 30,
  "distinctPhotographs": 30,
  "cc0Verified": 30,
  "dimensions": "800x600",
  "webpEncoding": "RIFF/WEBP + Pillow verified",
  "minBytes": 45640,
  "medianBytes": 54114.0,
  "maxBytes": 118278,
  "totalImageBytes": 1797730,
  "zipBytes": 1808049,
  "zipSha256": "67f1710386db658283f2d0649110128407c39bef9e28573ceccff805c0dffd7d",
  "rootFilenamesAndZipIntegrity": true,
  "livePathCompatibility": true,
  "salesforceRecordChanges": 0
}
```

The verifier checks distinct Commons IDs and source/output hashes, all expected names/no extras,
explicit source-page/license domains, visual-review records, real RIFF/WEBP magic and decoded
format/dimensions, one frame, output hashes/size, ZIP testzip/root entries and exact ZIP/source
byte equivalence. The live portion confirms Organization ID and all 30 model/body/path matches
through queries only. It does not render or deploy the resource.

## Resource limits

Official Salesforce source:
`https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_resources.htm` states
5 MB per resource and 250 MB total org static resources. The final 1,808,049-byte ZIP and its
uncompressed contents are below the individual limit.

CONFIRMED — raw org static-resource aggregate, query `SELECT COUNT(Id),SUM(BodyLength) FROM StaticResource`:

```json
{"expr0":0,"expr1":null}
```

Current static-resource usage is zero; the projected package is safely below the separate
250 MB total. Additional read-only org limits show FileStorageMB max=20/remaining=20, but that
is not substituted for the dedicated static-resource limits. No quota was consumed by deployment.

## Final scoped Salesforce check-only

Command:

```sh
sf project deploy start --target-org ng-demo --dry-run --manifest manifest/p7-22-images-check.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw final result excerpts:

```json
"id": "0Afaj00000p4yTFCAY",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-25T15:35:56.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 1,
"numberComponentsTotal": 1,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"componentFailures": [],
"warnings": []
```

Returned StaticResource NG_VehicleImages success=true. This is simulated/check-only creation,
not actual deployment. An earlier successful request `0Afaj00000p4wpdCAA` preceded two final
provenance-rationale clarifications; it is superseded by the final request above. No resource
content changed after final validation. The archive hash identifies the delivered local ZIP;
Salesforce CLI repacks decomposed source, so byte identity with its stored ZIP is not asserted.

No Apex is in this one-component package, so NoTestRun is appropriate. Existing application
validation `0Afaj00000p2bfeCAA` (21 components/163 tests) remains unchanged and is reused.
There is no claim of a combined 22-component validation or new browser/Apex acceptance.

## Preservation and remaining gates

All thirty existing Salesforce Image_Path__c values match the completed filenames unchanged;
Vehicle Photo__c and existing VIN/inventory/model fields are unchanged. No Salesforce deployment,
record mutation, permission change, gallery redesign, activation, Git staging/commit/push or
ng-dev access. Phase 6 acceptance/exceptions and unrelated dirty work remain preserved.

No genuine local sourcing/rights/encoding/package gap remains. Actual resource deployment and
live gallery/formula image rendering still need separate approval/evidence. P7-22 is locally
complete under the owner-approved stock-photo criterion, not live-deployed or owner-accepted.
The other previously documented Batch 1 credential/principal/browser gates remain unchanged.
