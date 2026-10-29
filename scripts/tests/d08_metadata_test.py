"""Offline metadata/preservation checks; not server schema validation or browser rendering."""
import hashlib
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
OBJECTS = ['Financing__c', 'Trade_In__c', 'Delivery__c', 'Loyalty_Member__c', 'Loyalty_Transaction__c', 'Consent__c']
BASE = ROOT / 'force-app/main/default'


class MetadataTests(unittest.TestCase):
    def test_dashboard_geometry_and_semantics(self):
        tree = ET.parse(BASE / 'dashboards/NG_Sales/DM_Exec_OperationsOverview.dashboard-meta.xml')
        self.assertEqual(tree.findtext('m:dashboardType', namespaces=NS), 'LoggedInUser')
        self.assertIsNone(tree.find('m:runningUser', NS))
        components = tree.findall('m:dashboardGridLayout/m:dashboardGridComponents', NS)
        expected = [('NG_01_Pipeline/Pipeline_by_Stage', 'AMOUNT', 'Sum'),
                    ('NG_03_Inventory/Inventory_Aging_60_120', 'RowCount', None),
                    ('NG_04_Service/Executive_Service_Overdue', 'FORMULA1', None),
                    ('NG_06_Loyalty/Loyalty_Tier_Distribution', 'RowCount', None),
                    ('NG_04_Service/Executive_Service_CSI', 'FORMULA1', None)]
        occupied = set()
        self.assertEqual(len(components), 5)
        for component, (report, column, aggregate) in zip(components, expected):
            col, row, width, height = [int(component.findtext('m:' + key, namespaces=NS))
                                       for key in ['columnIndex', 'rowIndex', 'colSpan', 'rowSpan']]
            self.assertGreaterEqual(width, 6)
            self.assertGreaterEqual(height, 3)
            self.assertLessEqual(col + width, 12)
            cells = {(x, y) for x in range(col, col + width) for y in range(row, row + height)}
            self.assertFalse(cells & occupied, 'overlapping grid rectangles')
            occupied |= cells
            tile = component.find('m:dashboardComponent', NS)
            self.assertEqual(tile.findtext('m:report', namespaces=NS), report)
            self.assertEqual(tile.findtext('m:chartSummary/m:column', namespaces=NS), column)
            self.assertEqual(tile.findtext('m:chartSummary/m:aggregate', namespaces=NS), aggregate)
            if 'Executive_Service_' in report:
                self.assertIn('24 hours', tile.findtext('m:footer', namespaces=NS))
                self.assertGreaterEqual(height, 4)

    def test_six_additive_context_views_no_grants_or_record_renames(self):
        for name in OBJECTS:
            tree = ET.parse(BASE / f'objects/{name}/listViews/NG_Overview.listView-meta.xml')
            self.assertEqual(tree.findtext('m:fullName', namespaces=NS), 'NG_Overview')
            self.assertEqual(tree.findtext('m:filterScope', namespaces=NS), 'Everything')
            self.assertIsNone(tree.find('m:sharedTo', NS))
            columns = [node.text for node in tree.findall('m:columns', NS)]
            self.assertEqual(columns[0], 'NAME')
            self.assertGreaterEqual(len(columns), 6)
            self.assertNotIn('Annual_Rate__c', columns)
            self.assertNotIn('Evidence__c', columns)
            for field in columns[1:]:
                self.assertTrue((BASE / f'objects/{name}/fields/{field}.field-meta.xml').is_file(), field)

    def test_manifest_is_exactly_nine_presentation_components(self):
        tree = ET.parse(ROOT / 'manifest/d08-presentation-local.xml')
        types = {node.findtext('m:name', namespaces=NS): [m.text for m in node.findall('m:members', NS)]
                 for node in tree.findall('m:types', NS)}
        self.assertEqual(types, {'LightningComponentBundle': ['quoteSummary', 'financeApplication'],
                                'Dashboard': ['NG_Sales/DM_Exec_OperationsOverview'],
                                'ListView': [name + '.NG_Overview' for name in OBJECTS]})

    def test_preexisting_apex_permissions_and_quote_builder_bytes_unchanged(self):
        before = json.loads((ROOT / 'evidence/UAT/FULL_PROJECT_2026-10-28/D08_LOCAL/before_hashes.json').read_text())
        allowed = {'force-app/main/default/lwc/quoteSummary/quoteSummary.html',
                   'force-app/main/default/lwc/financeApplication/financeApplication.html',
                   'force-app/main/default/lwc/financeApplication/financeApplication.js',
                   'force-app/main/default/dashboards/NG_Sales/DM_Exec_OperationsOverview.dashboard-meta.xml'}
        changed = {name for name, sha in before.items() if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != sha}
        self.assertEqual(changed, allowed)


if __name__ == '__main__':
    unittest.main(verbosity=2)
