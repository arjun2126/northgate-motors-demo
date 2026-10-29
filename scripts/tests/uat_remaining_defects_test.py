"""Focused offline permission-candidate checks using scoped before-state and read-only receipts."""
from copy import deepcopy
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'force-app/main/default'
OUT = ROOT / 'evidence/UAT/FULL_PROJECT_2026-10-28/REGRESSION_CLOSURE'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
NAME = 'PS_Owner_Portal_Dashboard_Runtime'
TRANSACTION_FIELDS = {'Loyalty_Transaction__c.Points__c', 'Loyalty_Transaction__c.Type__c'}
METRIC_FIELDS = {'Executive_Service_Metrics__c.' + field for field in
                 ['Overdue_Count__c', 'CSI_Score_Total__c', 'CSI_Response_Count__c']}


def value(node, name):
    return node.findtext('m:' + name, namespaces=NS)


def structure(node):
    return (node.tag, (node.text or '').strip(), tuple(structure(c) for c in node))


class RemainingDefectChecks(unittest.TestCase):
    def test_d06_exact_three_entry_addition_and_all_previous_grants_preserved(self):
        relative = f'force-app/main/default/permissionsets/{NAME}.permissionset-meta.xml'
        baseline = ET.parse(OUT / 'before' / relative).getroot()
        candidate = ET.parse(ROOT / relative).getroot()
        added_fields = [p for p in candidate.findall('m:fieldPermissions', NS) if value(p, 'field') in TRANSACTION_FIELDS]
        self.assertEqual({value(p, 'field') for p in added_fields}, TRANSACTION_FIELDS)
        self.assertEqual(len(added_fields), 2)
        for p in added_fields:
            self.assertEqual(value(p, 'readable'), 'true')
            self.assertEqual(value(p, 'editable'), 'false')
            candidate.remove(p)
        added_objects = [p for p in candidate.findall('m:objectPermissions', NS) if value(p, 'object') == 'Loyalty_Transaction__c']
        self.assertEqual(len(added_objects), 1)
        self.assertEqual(value(added_objects[0], 'allowRead'), 'true')
        for flag in ['allowCreate', 'allowEdit', 'allowDelete', 'viewAllRecords', 'modifyAllRecords']:
            self.assertEqual(value(added_objects[0], flag), 'false')
        candidate.remove(added_objects[0])
        self.assertEqual(structure(candidate), structure(baseline))

    def test_required_transaction_fields_get_no_speculative_fls(self):
        schema = json.loads((ROOT / 'evidence/UAT/FULL_PROJECT_2026-10-28/D08_READINESS/Loyalty_Transaction__c_describe.json').read_text())['result']['fields']
        permissionable = {f['name']: f['permissionable'] for f in schema}
        for field in ['Id', 'Loyalty_Member__c', 'Transaction_Date__c']:
            self.assertFalse(permissionable[field])
        for field in ['Points__c', 'Type__c']:
            self.assertTrue(permissionable[field])
        tree = ET.parse(BASE / f'permissionsets/{NAME}.permissionset-meta.xml').getroot()
        self.assertEqual(len(tree.findall('m:objectPermissions', NS)), 4)
        self.assertEqual(len(tree.findall('m:fieldPermissions', NS)), 11)

    def test_loyalty_native_sharing_and_contact_guards_remain(self):
        relationship = ET.parse(BASE / 'objects/Loyalty_Transaction__c/fields/Loyalty_Member__c.field-meta.xml').getroot()
        self.assertEqual(value(relationship, 'type'), 'MasterDetail')
        source = (BASE / 'classes/OwnerPortalBatchBController.cls').read_text()
        loyalty = source.split('@TestVisible private static LoyaltyPage loyalty', 1)[1].split('@TestVisible private static Id createOwnCase', 1)[0]
        self.assertIn('requireCaller(contactId)', loyalty)
        self.assertEqual(loyalty.count('Loyalty_Member__r.Contact__c = :contactId'), 2)
        self.assertIn('page.members.size() > 1', loyalty)
        self.assertIn('LIMIT 21', loyalty)
        self.assertEqual(loyalty.count('WITH USER_MODE'), 3)

    def test_executive_candidate_is_only_three_read_fields_no_other_capability(self):
        tree = ET.parse(BASE / 'permissionsets/PS_Executive_Service_Field_Read.permissionset-meta.xml').getroot()
        self.assertEqual({c.tag.split('}')[-1] for c in tree}, {'description', 'fieldPermissions', 'hasActivationRequired', 'label'})
        fields = tree.findall('m:fieldPermissions', NS)
        self.assertEqual(len(fields), 3)
        self.assertEqual({value(p, 'field') for p in fields}, METRIC_FIELDS)
        for p in fields:
            self.assertEqual(value(p, 'readable'), 'true')
            self.assertEqual(value(p, 'editable'), 'false')

    def test_saved_live_reader_evidence_supports_missing_field_not_repricing_fix(self):
        self.assertEqual(json.loads((OUT / 'metric_reader_fls.json').read_text())['result']['records'], [])
        for name in ['Executive_Service_CSI', 'Executive_Service_Overdue']:
            body = json.loads((OUT / (name + '_describe.json')).read_text())['result']['body']
            self.assertNotIn('FORMULA1', body['reportMetadata']['aggregates'])
            columns = {key for category in body['reportTypeMetadata']['categories'] for key in category['columns']}
            self.assertFalse(columns & METRIC_FIELDS)
            live = ET.parse(OUT / f'live-source/reports/NG_04_Service/{name}.report-meta.xml').getroot()
            candidate = ET.parse(BASE / f'reports/NG_04_Service/{name}.report-meta.xml').getroot()
            self.assertEqual(value(live.find('m:aggregates', NS), 'calculatedFormula'), value(candidate.find('m:aggregates', NS), 'calculatedFormula'))

    def test_separate_one_component_manifests(self):
        for filename, member in [('uat-executive-field-read.xml', 'PS_Executive_Service_Field_Read'),
                                 ('uat-d06-loyalty-read.xml', NAME)]:
            tree = ET.parse(ROOT / 'manifest' / filename).getroot()
            types = tree.findall('m:types', NS)
            self.assertEqual(len(types), 1)
            self.assertEqual(value(types[0], 'name'), 'PermissionSet')
            self.assertEqual([n.text for n in types[0].findall('m:members', NS)], [member])
            self.assertEqual(value(tree, 'version'), '68.0')

    def test_current_comment_guards_and_user_mode_are_not_bypassed(self):
        source = (BASE / 'classes/OwnerPortalBatchBController.cls').read_text()
        self.assertIn('Id = :caseId AND ContactId = :contactId WITH USER_MODE', source)
        self.assertIn('insert as user row', source)
        self.assertIn('IsPublished = true', source)
        self.assertIn('LIMIT 20', source)


if __name__ == '__main__':
    unittest.main(verbosity=2)
