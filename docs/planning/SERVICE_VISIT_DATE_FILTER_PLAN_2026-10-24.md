# Service Visit calendar-day filtering — focused recommendation

Date: 2026-10-24. Target: `ng-demo`, `00Daj00001Ae3iWEAR` only.
Status: read-only investigation and local planning; no implementation or configuration saved.
Do not change the existing All list view or repeat P6-01/P6-02 live acceptance.

## Observed baseline

- Organization query returned `00Daj00001Ae3iWEAR`.
- Live Northgate Service browser view is `Service_Visit__c/list?filterName=All`.
  Columns: Service Visit Name, Rooftop, Scheduled Start, Status. Owner scope is All service
  visits; displayed filter is Rooftop equals Northgate Airport, with no saved date filter visible.
- Local `Scheduled_Start__c` metadata is required DateTime. No local date-only scheduling field
  or Service Visit list-view source exists. The trigger and capacity guard use Scheduled Start;
  do not replace that authoritative field or change capacity accounting.
- Lightning Calendar is available at `/lightning/o/Event/home`; browser inspection shows a
  native month/year date picker and calendar View selector. No Service Visit calendar exists
  in the visible My Calendars list. Object-calendar creation and Service Visit availability in
  its object selector were not verified; do not claim a configured working Service calendar.
- The Calendar screen shows GMT -4 for October. A fixed Toronto deployment must also use
  GMT -5 in winter; do not treat a single displayed offset as full timezone verification.

## Inspection limits and escalation

The list-view inventory SOQL attempted an unsupported field:
```text
No such column 'FilterScope' on entity 'ListView'.
```
That CLI inspection stopped without retry. Scope described above is browser evidence, not a
successful metadata retrieval. An Add Filter browser call timed out; a later snapshot showed
an unsaved New Filter draft. Nothing was saved. The draft was discarded by navigating afresh
to All, which again showed only the existing Rooftop filter. A Calendar options interaction
unexpectedly opened an unsaved New Event form; no fields were entered or saved, and navigation
returned to All. Do not rely on those interactions as proof of DateTime filter control behavior.
Salesforce Help fetches returned a CSS loading error, not usable product documentation.

Owner read-only follow-up: inspect the Scheduled Start filter editor on a draft without saving;
capture its value control, supported operators and date/time format. Also inspect Calendar >
My Calendars options > New Calendar's object selector without saving, if calendar UI is acceptable.
These checks resolve the remaining native-control uncertainty; no permission changes are needed
or authorized merely to inspect as the current owner.

## Smallest native path first

If the owner accepts a calendar instead of a tabular list, a native **object calendar** is the
first candidate: Service Visit as object, Scheduled Start as start field, Service Visit Name as
label, Day view selected through the native date picker. Do not create duplicate Event records.
First verify this object/start-field combination is supported in this org and respects access.
Calendar dates follow the viewing user's timezone; verify America/Toronto for each intended
operator. This is not an independently fixed-Toronto filter for users in other timezones.
Creating a saved object calendar or adding Calendar to app navigation needs owner approval.
No Apex, formula, Flow, custom LWC or backfill is needed if this native UX satisfies the owner.

For the existing tabular list, first verify whether its native Scheduled Start filter can express
a full day using date-only values or a half-open local DateTime range. Do not assume an equals
comparison to a DateTime means the whole day. A verified native range would be the smallest
list-only solution for Toronto-timezone users, saved in a NEW view, not All.

## Proposed date-only list solution if native controls do not meet the requirement

For a single date-equals filter whose meaning is always Toronto, add a derived stored Date:
**Scheduled Date (Toronto)**, API `Scheduled_Date_Toronto__c`. Keep Scheduled Start beside it.

Expected owner workflow after separately approved implementation/deployment/backfill:
1. Open Service Visits > new **Service Visits by Scheduled Date** list view.
2. Open Filters and set Scheduled Date (Toronto) equals November 28, 2026.
3. Retain/add Rooftop equals Northgate Airport when desired. Do not add a status restriction
   for an all-visits-by-date view; completed/cancelled visits belong in the result too.
4. Use Salesforce's native Date value control; if that editor provides only formatted date
   entry rather than a popup picker, state that limitation. Do not promise a custom picker.
5. See all accessible visits for that Toronto date, sorted by Scheduled Start, at any time.

Before insert/update, derive the Date using the named timezone:
```apex
Date.valueOf(visit.Scheduled_Start__c.format('yyyy-MM-dd', 'America/Toronto'))
```
Handle null start as null and let existing required-field validation act. Keep this small
projection in the existing trigger's before context, before the trigger-bypass return, so it
remains derived for legitimate loader operations too. Do not add another trigger or change
the capacity guard, intake service, status policy or timing validation.
The user cannot edit the helper independently; expose Read-only FLS to the approved operators.

Do not use `DATEVALUE(Scheduled_Start__c)` as an unverified Toronto conversion, a constant
minus-four/minus-five-hour formula, or the viewer's `.date()` conversion. DateTime formula
conversion can use UTC semantics; fixed offsets fail DST. The named timezone conversion above
handles historical/current platform timezone rules without a hand-coded DST formula.

### Exact proposed source boundary

- Add `force-app/main/default/objects/Service_Visit__c/fields/Scheduled_Date_Toronto__c.field-meta.xml`.
- Update only the small before-context projection in `triggers/ServiceVisitTrigger.trigger`.
- Add `classes/ServiceVisitScheduledDateTest.cls` and its metadata.
- Add `objects/Service_Visit__c/listViews/By_Scheduled_Date.listView-meta.xml` (new view only).
- Add `permissionsets/PS_Service_Visit_Date_Filter.permissionset-meta.xml` with only required
  object Read/derived-field Read; no field Edit or broad service access. Any assignment is separate.
- Add `manifest/service-visit-date-filter-check.xml` when implementation is approved.

No metadata is created by this plan. If a native-only option works, do not build these files.
No change to Northgate Service app, existing All, guard/intake production classes, layouts or
record types is otherwise required for the date-only-field proposal.

### Historical-data dependency

Stored fields are blank on existing records until populated. A metadata-only deployment cannot
make historical filtering complete. A one-time, separately approved update must populate only
the derived Date, preserving original Scheduled Start, status, Rooftop, Case and references.
Existing past Scheduled visits can fail the timing validation even on neutral updates. Do not
disable that rule or change permissions; establish an explicitly authorized backfill actor/path
using existing access, dry-run the proposed projection, and stop on unexpected failure.
Do not describe the field solution as fully working before backfill is approved and verified.

## Validation after implementation authorization

- Isolated tests: winter/summer dates; UTC instants immediately before/at Toronto midnight;
  2026 spring-forward and fall-back days; both repeated fall-back hours; non-Toronto actor;
  null required start; changed start; attempted independent helper edit; 200 rows; bypass path.
- Independently verify November 28 boundaries are 2026-11-28T05:00:00Z inclusive through
  2026-11-29T05:00:00Z exclusive; summer midnight uses 04:00Z. DST days can be 23 or 25 hours.
- Confirm existing All unchanged, Date FLS and sharing respected, standard native filter control
  usable, no implicit status filter, and helper equality matches correct UTC-range membership.
- Run focused new tests and the existing capacity/intake regressions in test isolation only;
  exact scoped check-only after authorization. Do not rerun live acceptance or insert fixtures.
- Backfill requires separate data approval; compare every original scheduling/linkage value
  before/after and verify no new Cases. No unapproved live writes, permission changes or cleanup.

Decision: establish the native-control evidence first. Use the native calendar/range if adequate;
otherwise the Date-only projection plus native list filter is the smallest reliable fixed-Toronto
tabular solution. A custom LWC is not justified by the current evidence.

## Overnight disposition — configuration-only owner steps

Keep this usability item out of Batch 2 source. After separate configuration approval, the owner
opens `/lightning/o/Event/home`, uses My Calendars > New Calendar, chooses Service Visit,
names it `Service Visits — Toronto`, selects Scheduled Start for the start and Service Visit
Name for the label, and leaves the optional end field blank. If Service Visit/start is not
offered, cancel and report that exact limitation; do not create Event copies. Select an approved
Service Visit list filter if rooftop restriction is wanted, without editing All. Save only after
the owner approves the new calendar. Use Day view and the sidebar picker for November 28, 2026.
Verify the operator's existing timezone is America/Toronto and the winter display is GMT -5;
compare late-evening/midnight and DST boundaries before accepting this UX. Calendar follows the
viewer timezone, so it is not a fixed-Toronto solution for other-timezone operators. No app
navigation edit, calendar creation, record write or date-helper metadata was performed overnight.
If a fixed-Toronto tabular filter is mandatory, the separately scoped projection proposal above
remains pending; do not expand this task into a new UI build or unauthorized backfill.
