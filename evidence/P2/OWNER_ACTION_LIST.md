# Owner Action List — Phase 2 consolidated

All independent agent work continues in the background (Flow XML for P2-01 still blocked, see
`evidence/P2/blocked-metadata/flows/`). The items below need a human in Setup.

## A. P2-09 / P2-10 / P2-11 — Reports and dashboard (BLOCKING M1)

The folder records exist in ng-dev (created via API earlier; see checklist for IDs).
Author each report/dashboard in the Report Builder / Dashboard Builder, then say
**done**. The agent will retrieve, validate, and commit the XML.

- Folders: `NG_01_Pipeline` (Report, currently Hidden), `NG_02_Leads` (Report, Hidden),
  `NG_Sales` (Dashboard, Hidden). Set **Public** sharing before continuing.
- Full report/dashboard spec (columns, groupings, summaries, running user, folder sharing):
  `evidence/P2/blocked-metadata/REPORTS_DASHBOARDS_checklist.md`

## B. P2-01 — Lead Enrich Rooftop flow (BLOCKING M1)

The Flow XML fails Metadata API schema validation when hand-written.
Source path: `force-app/main/default/flows/Lead_Enrich_Rooftop.flow-meta.xml.blocked`
(quarantined). The routing table (`customMetadata/Lead_Routing__mdt.*.md-meta.xml`) and the
`LeadRoundRobin` invocable Apex action are already deployed and working.

Steps for the owner:
1. Open **Setup → Flows → New Flow**.
2. Type: **Record-Triggered Flow**, Object: **Lead**, Trigger: **A record is created**, Entry
   Conditions: `PostalCode IsNull = false`. Run Mode: **Fast Field Updates** (before-save).
3. Decisions and Apex action wiring are documented in
   `evidence/P2/p201_blocked.txt`. The Apex action `LeadRoundRobin` is already deployed.
4. Activate. Or export the Flow XML and commit to
   `force-app/main/default/flows/Lead_Enrich_Rooftop.flow-meta.xml`.

## C. CI validation (already green)

`validate.yml` runs `sf project deploy start --dry-run --test-level RunLocalTests` and
currently passes (run 37779791983, head `9074a9e`). The trigger to start the workflow is
`workflow_dispatch` (manual). Re-run after each P2 owner step.

## D. P1-15 follow-up after OrgFarm EPIC deactivation (done)

`scripts/persona.sh manager` and `finance` were verified for `ngpersona`. No further
owner action.

## E. Phase 2 exit gate (M1)

When A and B are done, the agent will:
1. Retrieve folders, reports, and the dashboard into source.
2. Validate dry-run + tests (≥90% coverage).
3. Run DQ release-gate checks.
4. Produce the Phase 2 exit report and a tag `demo/v0.1`.

Until A and B land, M1 is held.
