"""Run: python3 scripts/tests/executive_service_reporting.test.py.

These checks protect metadata/security scope. Salesforce check-only validation
must additionally accept report formulas and dashboard references.
"""
import hashlib
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2] / "force-app/main/default"
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}
OBJECT = "Executive_Service_Metrics__c"
AGE_FORMULA = f"(NOW() - {OBJECT}.Captured_At__c) * 24"


def read_xml(path):
    return ET.parse(ROOT / path).getroot()


def normalized(element):
    return (element.tag, (element.text or "").strip(), tuple(normalized(child) for child in element))


class ExecutiveServiceReportingTest(unittest.TestCase):
    def test_other_three_dashboard_components_and_running_user_are_preserved(self):
        dashboard = read_xml("dashboards/NG_Sales/DM_Exec_OperationsOverview.dashboard-meta.xml")
        self.assertEqual(dashboard.findtext("m:dashboardType", namespaces=NS), "LoggedInUser")
        self.assertIsNone(dashboard.find("m:runningUser", NS))
        components = dashboard.findall(".//m:dashboardGridComponents", NS)
        self.assertEqual(len(components), 5)
        protected = {
            "Pipeline Amount": "2803c7d4d2536398c6a764b3c6fb18cb71ba460ee9b675d1d1dc7a65a1f7e494",
            "Inventory Aged Over 60 Days": "5a2b1d2ccb40c7023e4627f7cce62ff579bd5c446176c2f5e33bad66ede89918",
            "Loyalty Members": "7f747ccac043648185080fe541628ae3b576d7d2bf337bf36b49f0dda8591772",
        }
        for component in components:
            title = component.findtext("m:dashboardComponent/m:header", namespaces=NS)
            if title in protected:
                self.assertEqual(hashlib.sha256(repr(normalized(component)).encode()).hexdigest(), protected[title])

    def test_service_metrics_use_validated_formula_references_not_record_count(self):
        dashboard = read_xml("dashboards/NG_Sales/DM_Exec_OperationsOverview.dashboard-meta.xml")
        for component in dashboard.findall(".//m:dashboardComponent", NS):
            title = component.findtext("m:header", namespaces=NS)
            if title in ("Overdue Service Visits", "CSI Proxy (Recorded Scores)"):
                self.assertEqual(component.findtext("m:chartSummary/m:column", namespaces=NS), "FORMULA1")
                self.assertIsNone(component.find("m:chartSummary/m:aggregate", NS))
                self.assertIn("24 hours", component.findtext("m:footer", namespaces=NS))
                report = read_xml("reports/" + component.findtext("m:report", namespaces=NS) + ".report-meta.xml")
                self.assertEqual(report.findtext("m:aggregates/m:developerName", namespaces=NS), "FORMULA1")
                self.assertNotIn("RowCount", report.findtext("m:aggregates/m:calculatedFormula", namespaces=NS))

    def test_overdue_expression_displays_stored_count_only_when_fresh(self):
        report = read_xml("reports/NG_04_Service/Executive_Service_Overdue.report-meta.xml")
        self.assertEqual(report.findtext("m:aggregates/m:calculatedFormula", namespaces=NS),
                         f"IF(CDF1:SUM <= 24, {OBJECT}.Overdue_Count__c:SUM, NULL)")

    def test_csi_expression_uses_total_over_scored_count_and_null_for_na(self):
        report = read_xml("reports/NG_04_Service/Executive_Service_CSI.report-meta.xml")
        self.assertEqual(report.findtext("m:aggregates/m:calculatedFormula", namespaces=NS),
                         f"IF(AND(CDF1:SUM <= 24, {OBJECT}.CSI_Response_Count__c:SUM > 0), "
                         f"{OBJECT}.CSI_Score_Total__c:SUM / {OBJECT}.CSI_Response_Count__c:SUM, NULL)")

    def test_reports_show_capture_time_and_age_without_hiding_stale_row(self):
        for name in ("Executive_Service_Overdue", "Executive_Service_CSI"):
            report = read_xml(f"reports/NG_04_Service/{name}.report-meta.xml")
            self.assertEqual(report.findtext("m:customDetailFormulas/m:calculatedFormula", namespaces=NS), AGE_FORMULA)
            self.assertEqual(report.findtext("m:showDetails", namespaces=NS), "true")
            self.assertIn(f"{OBJECT}$Captured_At__c", [e.text for e in report.findall("m:columns/m:field", NS)])
            filters = report.findall("m:filter/m:criteriaItems", NS)
            self.assertEqual(len(filters), 1)
            self.assertEqual(filters[0].findtext("m:column", namespaces=NS), f"{OBJECT}$Metric_Key__c")
            self.assertEqual(filters[0].findtext("m:value", namespaces=NS), "DEALERSHIP")

    def test_metric_schema_is_deidentified_and_key_is_unique(self):
        fields = ROOT / "objects" / OBJECT / "fields"
        self.assertEqual({p.name for p in fields.glob("*.xml")}, {
            name + ".field-meta.xml" for name in (
                "Metric_Key__c", "Overdue_Count__c", "CSI_Score_Total__c", "CSI_Response_Count__c", "Captured_At__c"
            )
        })
        for path in fields.glob("*.xml"):
            field = ET.parse(path).getroot()
            self.assertNotIn(field.findtext("m:type", namespaces=NS), ("Lookup", "MasterDetail"))
        key = read_xml(f"objects/{OBJECT}/fields/Metric_Key__c.field-meta.xml")
        self.assertEqual(key.findtext("m:unique", namespaces=NS), "true")
        self.assertEqual(key.findtext("m:externalId", namespaces=NS), "true")
        self.assertEqual(key.findtext("m:required", namespaces=NS), "true")

    def test_vp_set_grants_no_source_service_finance_or_write_access(self):
        permissions = read_xml("permissionsets/PS_VP_Executive_Reporting.permissionset-meta.xml")
        self.assertTrue(all(e.tag.split("}")[-1] in {
            "description", "hasActivationRequired", "label", "objectPermissions", "fieldPermissions"
        } for e in permissions))
        self.assertLessEqual(len(permissions.findtext("m:description", namespaces=NS)), 255)
        self.assertEqual({e.findtext("m:object", namespaces=NS) for e in permissions.findall("m:objectPermissions", NS)},
                         {OBJECT, "Opportunity", "Staff__c", "Rooftop__c"})
        for entry in permissions.findall("m:objectPermissions", NS):
            self.assertEqual(entry.findtext("m:allowRead", namespaces=NS), "true")
            for tag in ("allowCreate", "allowEdit", "allowDelete", "viewAllRecords", "modifyAllRecords"):
                self.assertEqual(entry.findtext("m:" + tag, namespaces=NS), "false")
        self.assertEqual({e.findtext("m:field", namespaces=NS) for e in permissions.findall("m:fieldPermissions", NS)},
                         {"Opportunity.Amount", "Opportunity.Sales_Staff__c", f"{OBJECT}.Overdue_Count__c",
                          f"{OBJECT}.CSI_Score_Total__c", f"{OBJECT}.CSI_Response_Count__c"})
        for entry in permissions.findall("m:fieldPermissions", NS):
            self.assertEqual(entry.findtext("m:editable", namespaces=NS), "false")
            self.assertEqual(entry.findtext("m:readable", namespaces=NS), "true")

    def test_operational_reports_are_byte_identical_and_publisher_has_no_ui_or_schedule_hook(self):
        protected = {
            "Service_SLA_Overdue": "735dc641682857dccab94310ad6a13292ebd17d63bbe78b3e3c99eed8fc3f324",
            "Service_CSI_Proxy": "3cc402ab353d0bf619f0e54006aa194ac2ec70687acb28a113ce905ad8007fe8",
        }
        for name, digest in protected.items():
            self.assertEqual(hashlib.sha256((ROOT / f"reports/NG_04_Service/{name}.report-meta.xml").read_bytes()).hexdigest(), digest)
        source = (ROOT / "classes/ExecutiveServiceMetricsPublisher.cls").read_text()
        for forbidden in ("@AuraEnabled", "@InvocableMethod", "@RestResource", "System.schedule("):
            self.assertNotIn(forbidden, source)
        self.assertIn("WITH USER_MODE", source)
        self.assertIn("Metric_Key__c = 'DEALERSHIP'", source)


if __name__ == "__main__":
    unittest.main()
