# P7-22 — licensed real-photo package deployed

The approved Batch 1 source implementation targets ng-demo only. No image path or VIN record
is changed. Current 30 model paths already use `/resource/NG_VehicleImages/<make>_<trim>.webp`.
Six fictional makes are Aurelia, Cascadia, Halcyon, Kestrel, Meridian and Vantage; each has EX,
Limited, LX, Premium and Sport. Keep these exact lowercase filenames when assets are supplied.
The exact model/filename/body-style snapshot is `P7_VEHICLE_IMAGE_MAP.json`; it contains no record
IDs, VINs or write instructions.

## Owner-approved sourcing change and result

The owner replaced planned AI-generated photographs with appropriately licensed real automotive
stock photography. That resolves the earlier unavailable-generation-tool blocker without pretending
stock photographs were AI-generated. Thirty distinct real photographs are now sourced, reviewed,
converted and packaged, with explicit CC0 1.0 Commons records. They illustrate the fictional
Northgate models, not exact manufacturer/year identity or endorsement. OEM badges are retained.

Complete local source: `force-app/main/default/staticresources/NG_VehicleImages/` plus its
resource metadata. Deliverable archive: `evidence/P7/NG_VehicleImages.zip`. The archive has all
30 exact root filenames, ATTRIBUTION.md and licenses.json. No gallery code was redesigned.

Source/rights inventory: `P7_VEHICLE_PHOTO_INVENTORY.md` and `P7_VEHICLE_PHOTO_SOURCES.json`.
Each selected photograph records its source page, original image URL, photographer, applicable
license, original/download variant, verification time, hashes and matching/visual rationale.
Six unsuitable candidates were rejected, not retouched to remove branding or hide composition.

Required files are the Cartesian product of:

```text
aurelia cascadia halcyon kestrel meridian vantage
ex limited lx premium sport
```

All files are genuine 800×600 WebP. Full source frames are proportionally resized/letterboxed;
no cropping, logo removal or background replacement. Median size is 54,114 bytes; range
45,640–118,278 bytes. Larger complex scenes retain a quality floor rather than excessive
compression to force 50 KB. Total images: 1,797,730 bytes. Local ZIP: 1,808,049 bytes, below
the native 5 MB resource limit. The predeployment org check found zero static resources; the
approved deployment subsequently created NG_VehicleImages with BodyLength=1,807,209 bytes.

## Validation and remaining boundary

`python3 scripts/tests/check_p7_vehicle_photos.py --live` passes all 30 encodings/dimensions,
unique source/output hashes, explicit licenses, exact filenames, ZIP integrity/root layout and
live model/body/path comparison. Zero Salesforce record changes. Processed contact sheet:
`evidence/P7/photo_sources/processed-contact-sheet.jpg` was visually reviewed.

Asset-only manifest `manifest/p7-22-images-check.xml`, final request `0Afaj00000p4yTFCAY`:
Succeeded, checkOnly=true, one/one StaticResource, zero errors. No Apex tests were needed or
rerun. The earlier check `0Afaj00000p4wpdCAA` predates a final provenance-text clarification and
is superseded. Final package SHA-256:
`67f1710386db658283f2d0649110128407c39bef9e28573ceccff805c0dffd7d`.

## Authorized deployment and remaining acceptance

The owner subsequently authorized standard deployment of the same two manifests after Quick
Deploy was unavailable. Photos deployed first, followed by the separate 21-component application.

CONFIRMED — raw deployment result excerpts:

```json
{"id":"0Afaj00000p7373CAA","status":"Succeeded","checkOnly":false,"numberComponentsDeployed":1,"numberComponentsTotal":1,"numberComponentErrors":0,"numberTestsCompleted":0}
{"id":"0Afaj00000p738fCAA","status":"Succeeded","checkOnly":false,"numberComponentsDeployed":21,"numberComponentsTotal":21,"numberComponentErrors":0,"numberTestsCompleted":0}
```

Both Developer Edition deployments used NoTestRun. Prior 163/163 application validation remains
separate evidence, not a new test run or a combined 22-component validation.

The authenticated deployed archive contains all thirty exact approved photographs and the full
licenses.json register: 31 files, 1,807,209 bytes. Existing `.forceignore` excludes optional
ATTRIBUTION.md through its `*.md` rule; the local deliverable remains 32 files. No photo is missing,
and no source or ignore rule was changed. All thirty photo hashes, encodings/dimensions and
existing model/body/image-path matches passed deployed archive verification. No path-data
migration or Salesforce record change was required.

No asset sourcing/license gap remains. Browser/front-end image rendering remains unverified:
the direct API-host stream probe returned no usable image; authenticated archive verification
does not establish browser rendering. Gallery/reservation/event acceptance, operational access,
page placement and VIN credentials remain deferred. Batch 1 is deployed, not owner-accepted.
Full evidence: `evidence/P7/BATCH1_STANDARD_DEPLOYMENT_2026-10-25.md` and
`evidence/P7/DEPLOYED_RESOURCE_VERIFICATION_2026-10-25.json`.
