# Phase 2/5 scoped check-only resolution — 2026-10-20

## Final native results — CONFIRMED

Only existing manifests were used. Both final jobs are check-only, not deployments.

```json
{"id":"0Afaj00000oQSwkCAG","checkOnly":true,"status":"Succeeded","componentErrors":0,"testsRun":0}
{"id":"0Afaj00000oQNXGCA4","checkOnly":true,"status":"Succeeded","componentErrors":0,"testsRun":0}
```

Phase 2: all four components returned `success: true`:

- Flow `TestDrive_Book_Screen`
- PermissionSet `PS_Lead_Conversion`
- PermissionSet `PS_Test_Drive_Booking`
- PermissionSetGroup `PSG_Rep`

Phase 5: all 15 components returned `success: true`:

- CustomField `Vehicle__c.Reporting_Make__c`
- ReportTypes `ServiceVisitList`, `TradeInList`, `VehicleList`
- Reports `NG_03_Inventory/Inventory_Aging_60_120`, `NG_04_Service/Service_CSI_Proxy`,
  `NG_04_Service/Service_SLA_Overdue`, `NG_05_DataQuality/SEED98_Contacts`,
  `NG_05_DataQuality/SEED98_TradeIns`, `NG_06_Loyalty/Loyalty_Tier_Distribution`
- DashboardFolder `NG_Management`
- Dashboards `NG_Management/DM_Finance_Operations`, `NG_Management/DM_Sales_Operations`,
  `NG_Management/DM_Service_OperationsFixed`, `NG_Sales/DM_Exec_OperationsOverview`

This pass first ran changed scopes as `0Afaj00000oQh2vCAC` and `0Afaj00000oQh4XCAS`.
Those exposed self-contained CRUD dependencies and manual-column dashboard mode. Only
identified in-scope corrections were applied before the final successful jobs. No unchanged
package was repeatedly retried; no broader manifest, Apex test suite or org was used.

## Exact source files changed in this correction pass

All metadata paths below are under `force-app/main/default/`:

1. `permissionsets/PS_Lead_Conversion.permissionset-meta.xml`
2. `flows/TestDrive_Book_Screen.flow-meta.xml`
3. `reports/NG_05_DataQuality/SEED98_Contacts.report-meta.xml`
4. `reports/NG_05_DataQuality/SEED98_TradeIns.report-meta.xml`
5. `reportTypes/TradeInList.reportType-meta.xml`
6. `dashboards/NG_Sales/DM_Exec_OperationsOverview.dashboard-meta.xml`
7. `dashboards/NG_Management/DM_Sales_Operations.dashboard-meta.xml`
8. `dashboards/NG_Management/DM_Service_OperationsFixed.dashboard-meta.xml`
9. `dashboards/NG_Management/DM_Finance_Operations.dashboard-meta.xml`

Evidence/status updates: this file, `docs/planning/P2_P5_IMPLEMENTATION_2026-10-20.md`,
`docs/DATA_QUALITY.md`, `BUILD_STATUS.md`, and `NORTHGATE_PROJECT_HANDOFF.md`. No manifests, canonical CSVs,
seed targets, Apex guards, pricing classes, profiles, OWDs or sharing rules changed.

## Permission impact

Read-only live queries returned `PermissionsEditTask=false` and
`PermissionsConvertLeads=false` for PS_Sales_Rep, PS_Sales_Manager, NG_Sales profile's
PermissionSet, and NG_Lightning_Experience_Access. The intended rep PSG currently contains
only PS_Sales_Rep. The restored baseline has no assigned persona PSG.

After adding EditTask, native validation required these dependencies in the conversion
PermissionSet itself, even though the intended rep already has them through PS_Sales_Rep
and NG_Sales:

```text
Permission Convert Leads depends on permission(s): Create Account, Create Contact, Edit Account, Edit Contact, Edit Lead, Read Account, Read Contact, Read Lead
```

The supplemental set now repeats only Account/Contact Read/Create/Edit and Lead Read/Edit.
No Delete, View All, Modify All, View All Fields or FLS grants were added. This is not
literally a conversion-only set anymore; it contains platform-required dependencies.
For the intended rep, those CRUD entries add no effective object capability. EditTask is
a real new Task-edit capability, and ConvertLeads enables conversion. The previously
prepared booking set also grants RunFlow and booking Flow access. Existing record-level
sharing still applies. Do not assign the supplemental set indiscriminately to other users.

PSG references and names were already correct; its earlier failure was a consequence of
the invalid dependency PermissionSet. Keeping all four components in the same manifest
validated successfully after the PermissionSet became self-contained. No split actual
deployment or deployment-order workaround was needed.

## Flow and reporting changes

- Entry screen now allows Back and disallows Finish. Existing connector, inputs,
  date/duration validation, overlap query and Apex protection are unchanged.
- Both legacy reports retain their seed-tag filter and grouping. Removed the duplicate
  seed-tag detail column because the grouping already displays it.
- TradeInList now exposes CreatedDate, making the existing all-time date field reference
  valid; report timeframe intent did not change.
- All 12 new metric components use supported colors from existing DealDesk metadata:
  low `#C23934`, middle `#CA8501`, high `#00716B`. Manual chartSummary definitions require
  `autoselectColumnsFromReport=false`; this is now explicit. Source reports, measures,
  running users, folder security and summary calculations are unchanged.

`xmllint --noout` and `git diff --check` returned no errors. Permission XPath returned
EditTask, ConvertLeads, and zero true ViewAll/ModifyAll/ViewAllFields flags. No Apex tests
ran: changes were metadata-only and existing Apex was preserved. Browser/runtime acceptance
remains outstanding.

## Eight-record discrepancy — evidence-based reconciliation

The original committed per-object table is internally consistent. Summing its 27 rows in
`git show HEAD:DEMO_ORG_SYNTHETIC_DATA_PLAN.md` §2.1 produced:

```json
{"rows":27,"originalClean":1843,"originalFull":2123,"originalProduct2":40,"originalDelivery":40,"currentAdjustment":{"Product2":"+20 (40 to 60)","Delivery__c":"-28 (40 to 12)","net":-8},"reconciledClean":1835,"reconciledFull":2115}
```

Sources agree on the cause:

- Original master-plan change log, lines 871–877, retains about 1,873 non-activity records
  plus 250 activities. Master §8 delegates volume details to the data plan.
- Original backlog P5-03 still specifies 1,843 clean + 30 legacy + 250 activities = 2,123.
- Current uncommitted data-plan diff changes Product2 40 to 60 and Delivery 40 to 12.
  Net change: `+20 - 28 = -8`; revised total is 2,115.
- Generator emits 30 trims, 5 packages and 25 accessories. Delivery generator still has a
  40 cap but restricts eligibility to the 12 Closed Won Opportunities, producing 12 rows.
- Loader/verifier per-object manifests use 60 Product2 and 12 Delivery. CSV line counts
  are 61 and 13 including headers, confirming those actual row allocations.
- `NEXT_SESSION_HANDOFF.md` lines 840–853 records exactly these two row changes and totals.
  Its later summary contains double-counting wording; it is not an independent allocation.
- SEED_VERSION retains original EXPECTED_TOTAL_RECORDS=2123 and EXPECTED_TOTAL_KB=4026
  alongside LOADED_RECORDS=2085 and the separately recorded 2115 per-object/legacy total.

Conclusion: **historical allocation changes with unsynchronized planning/version references**, not an
unidentified object allocation or an arithmetic mistake in the original table. The difference
is explained, but governing acceptance allocations are not silently changed. This pass leaves
both targets, all CSVs and strict original-target gating intact. Owner must explicitly settle
the original-versus-revised row allocations; inserting eight arbitrary records would not
reconcile the original per-object criteria. SEED-98's 30 rows remain mandatory either way.

## Remaining release/acceptance gates

Phase 2 metadata is check-only validated, not deployed or owner-UAT accepted. Release needs
explicit deployment, rep activation/data/UAT authorization, actual Flow overlap/free-slot
verification and guarded baseline restore. Phase 5 still needs ledger evidence, SEED-98 data
approval/parent maps/bypass controls, expected-count evidence, folder/FLS/persona verification,
joined report usability, exact storage screenshot and complete reset/burst safeguards.

New dashboard compilation is not proof of correct runtime totals or legitimate access for
both executive personas. Management folder remains unshared in source. No broad permission
or sharing workaround is part of this release. Phases 6–8 were not started.
