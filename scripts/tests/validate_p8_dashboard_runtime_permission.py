"""Local-only exact-scope checks for the proposed P8 dashboard runtime PermissionSet.

No Salesforce calls, deployments, assignments or fixture writes. Static checks do not replace
Salesforce validation, actual-license runAs tests, or native/customer-session security UAT.
"""
import hashlib
import json
import re
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'evidence/P8/PORTAL_PERMISSION_FIX'
NAME = 'PS_Owner_Portal_Dashboard_Runtime'
SOURCE = ROOT / 'force-app/main/default/permissionsets' / (NAME + '.permissionset-meta.xml')
MANIFEST = ROOT / 'manifest/p8-dashboard-runtime-permission.xml'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
EXPECTED_OBJECTS = {'Case', 'Service_Visit__c', 'Loyalty_Member__c'}
DASHBOARD_FIELDS = {'Case.ContactId', 'Service_Visit__c.Status__c', 'Service_Visit__c.Service_Type__c',
                    'Loyalty_Member__c.Points_Balance__c', 'Loyalty_Member__c.Tier__c', 'Loyalty_Member__c.Status__c'}
HISTORY_FIELDS = {'Service_Visit__c.Mileage_At_Checkin__c', 'Service_Visit__c.Case__c'}
CASE_FIELDS = {'Case.Subject'}
EXPECTED_FIELDS = DASHBOARD_FIELDS | HISTORY_FIELDS | CASE_FIELDS
EXPECTED_METHODS = {'getDashboard', 'getHistory', 'getCases', 'getLoyalty', 'getVehicles',
                    'getVehiclePage', 'getAppointmentOptions', 'bookAppointment', 'requestAppointment',
                    'createCase', 'addComment', 'getComments'}


def text(element, name):
    return element.find('m:' + name, NS).text


class RuntimePermissionChecks(unittest.TestCase):
    def setUp(self):
        self.permission = ET.parse(SOURCE).getroot()

    def test_only_one_permission_set_in_manifest(self):
        package = ET.parse(MANIFEST).getroot()
        types = package.findall('m:types', NS)
        self.assertEqual(1, len(types))
        self.assertEqual('PermissionSet', text(types[0], 'name'))
        self.assertEqual([NAME], [row.text for row in types[0].findall('m:members', NS)])
        self.assertEqual('68.0', text(package, 'version'))

    def test_only_facade_class_access(self):
        access = self.permission.findall('m:classAccesses', NS)
        self.assertEqual(1, len(access))
        self.assertEqual('OwnerPortalBatchBController', text(access[0], 'apexClass'))
        self.assertEqual('true', text(access[0], 'enabled'))

    def test_exact_three_read_only_objects(self):
        objects = self.permission.findall('m:objectPermissions', NS)
        self.assertEqual(3, len(objects))
        self.assertEqual(EXPECTED_OBJECTS, {text(row, 'object') for row in objects})
        for row in objects:
            self.assertEqual('true', text(row, 'allowRead'))
            for flag in ['allowCreate', 'allowEdit', 'allowDelete', 'viewAllRecords', 'modifyAllRecords']:
                self.assertEqual('false', text(row, flag))

    def test_exact_nine_read_only_fields(self):
        fields = self.permission.findall('m:fieldPermissions', NS)
        self.assertEqual(9, len(fields))
        self.assertEqual(EXPECTED_FIELDS, {text(row, 'field') for row in fields})
        for row in fields:
            self.assertEqual('true', text(row, 'readable'))
            self.assertEqual('false', text(row, 'editable'))

    def test_live_describe_confirms_minimal_permissionable_fields(self):
        inventory = json.loads((OUT / 'dashboard_field_inventory.json').read_text())
        needed = {obj + '.' + field for obj, fields in inventory.items() for field, data in fields.items()
                  if data['permissionable']}
        self.assertEqual(DASHBOARD_FIELDS, needed)
        self.assertFalse(inventory['Case']['IsClosed']['permissionable'])
        self.assertFalse(inventory['Service_Visit__c']['Scheduled_Start__c']['permissionable'])
        self.assertFalse(inventory['Service_Visit__c']['Contact__c']['permissionable'])
        self.assertFalse(inventory['Loyalty_Member__c']['Contact__c']['permissionable'])

    def test_history_fields_are_permissionable_in_saved_live_schema(self):
        describe = json.loads((OUT / 'operations/describe_Service_Visit__c.json').read_text())['result']
        fields = {field['name']: field for field in describe['fields']}
        for qualified in HISTORY_FIELDS:
            self.assertTrue(fields[qualified.split('.', 1)[1]]['permissionable'], qualified)

    def test_only_subject_read_addition_from_deployed_snapshot(self):
        deployed = (ROOT / 'evidence/P8/SERVICE_HISTORY_FLS_DEPLOYMENT/submitted_source'
                    / SOURCE.relative_to(ROOT))
        baseline = ET.parse(deployed).getroot()
        self.assertEqual(DASHBOARD_FIELDS | HISTORY_FIELDS,
                         {text(row, 'field') for row in baseline.findall('m:fieldPermissions', NS)})
        for row in list(self.permission.findall('m:fieldPermissions', NS)):
            if text(row, 'field') in CASE_FIELDS:
                self.permission.remove(row)

        def structure(element):
            return (element.tag, tuple(sorted(element.attrib.items())), (element.text or '').strip(),
                    tuple(structure(child) for child in element))

        self.assertEqual(structure(baseline), structure(self.permission))

    def test_no_extra_capabilities_in_metadata(self):
        allowed_tags = {'classAccesses', 'description', 'fieldPermissions', 'hasActivationRequired',
                        'label', 'objectPermissions'}
        self.assertEqual(allowed_tags, {child.tag.split('}')[-1] for child in self.permission})
        self.assertIn('not a read-only capability boundary', text(self.permission, 'description'))
        self.assertFalse(EXPECTED_OBJECTS & {'Vehicle__c', 'Vehicle_Model__c', 'Contact_Vehicle_Relationship__c',
                                           'Rooftop__c', 'Loyalty_Transaction__c'})

    def test_all_exposed_methods_are_in_review(self):
        source = (ROOT / 'force-app/main/default/classes/OwnerPortalBatchBController.cls').read_text()
        found = re.findall(r'@AuraEnabled\s+public static [\w.<>]+\s+(\w+)\s*\(', source)
        self.assertEqual(12, len(found))
        self.assertEqual(EXPECTED_METHODS, set(found))

    def test_guard_sources_match_live_readback(self):
        for name in ['OwnerPortalFoundationController', 'OwnerPortalBatchBController', 'OwnerPortalVehicleBroker']:
            local = ROOT / 'force-app/main/default/classes' / (name + '.cls')
            live = OUT / 'deployed_guard_readback/classes' / (name + '.cls')
            self.assertEqual(local.read_text().replace('\r\n', '\n').rstrip(),
                             live.read_text().replace('\r\n', '\n').rstrip(), name)

    def test_existing_deployed_package_hashes_unchanged(self):
        hashes = json.loads((ROOT / 'evidence/P8/BROKER_DEPLOYMENT/source_parity.json').read_text())['sha256']
        self.assertEqual(55, len(hashes))
        for path, digest in hashes.items():
            self.assertEqual(digest, hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), path)

    def test_assignment_plan_is_exact_and_not_executable(self):
        plan = json.loads((OUT / 'assignments.plan.json').read_text())
        self.assertEqual('PLAN_ONLY_OWNER_APPROVAL_REQUIRED', plan['status'])
        self.assertEqual('ng-demo', plan['targetOrgAlias'])
        self.assertEqual('00Daj00001Ae3iWEAR', plan['targetOrgId'])
        self.assertEqual(NAME, plan['permissionSetName'])
        self.assertIsNone(plan['permissionSetId'])
        self.assertFalse(plan['assignmentsExecuted'])
        self.assertFalse(plan['membershipChanges'])
        self.assertFalse(plan['sharingChanges'])
        self.assertFalse(plan['dataChanges'])
        self.assertEqual(2, len(plan['assignments']))
        self.assertEqual({('005aj00000guQE9AAM', '003aj00002Xl4IfAAJ'),
                          ('005aj00000guQEAAA2', '003aj00002Xl4IgAAJ')},
                         {(row['assigneeId'], row['expectedContactId']) for row in plan['assignments']})
        self.assertIn('PS_Owner_Portal_Batch_B', plan['doNotAssign'])


if __name__ == '__main__':
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(RuntimePermissionChecks)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    report = {'claim': 'CONFIRMED' if result.wasSuccessful() else 'REFUTED',
              'localTestsRun': result.testsRun, 'failures': len(result.failures), 'errors': len(result.errors),
              'metadataComponents': 1, 'apexClassGrants': 1, 'objectReadGrants': sorted(EXPECTED_OBJECTS),
              'fieldReadGrants': sorted(EXPECTED_FIELDS), 'fieldEditGrants': 0, 'nativeWriteGrants': 0,
              'guardSourcesChanged': False, 'orgWritesPerformed': 0,
              'sha256': {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
                         for path in [SOURCE, MANIFEST]},
              'skipped': ['Salesforce check-only deployment/license/dependency validation: not authorized',
                          'New permission combination actual-license System.runAs tests: not run',
                          'A/B authenticated runtime/native isolation and guarded write tests: not run',
                          'Deployment and permission assignments: not performed']}
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'local_validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if result.wasSuccessful() else 1)
