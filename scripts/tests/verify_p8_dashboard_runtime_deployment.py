"""Compare saved scoped release/security evidence. No Salesforce calls or corrective writes."""
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'evidence/P8/DASHBOARD_RUNTIME_DEPLOYMENT'
PID = '0PSaj00000hHfZ7GAK'
NAME = 'PS_Owner_Portal_Dashboard_Runtime'
USERS = {'A': '005aj00000guQE9AAM', 'B': '005aj00000guQEAAA2'}
OWN_RECORDS = {'A': {'003aj00002Xl4IfAAJ', '001aj000049ZoXNAA0'},
               'B': {'003aj00002Xl4IgAAJ', '001aj000049ZoXOAA0'}}


def clean(value):
    if isinstance(value, dict):
        return {key: clean(item) for key, item in value.items() if key != 'attributes'}
    if isinstance(value, list):
        return [clean(item) for item in value]
    return value


def result(name):
    return clean(json.loads((OUT / 'operations' / (name + '.json')).read_text())['result'])


def rows(name):
    return result(name)['records']


checks = {}
validation, deployment = result('salesforce_validation'), result('deployment')
checks['salesforce_validation_exact_one_component_and_22_tests'] = (
    validation['id'] == '0Afaj00000pTPCACA4' and validation['status'] == 'Succeeded'
    and validation['checkOnly'] and validation['numberComponentsTotal'] == 1
    and validation['numberComponentErrors'] == 0 and validation['numberTestsCompleted'] == 22
    and validation['numberTestErrors'] == 0)
components = {(row['componentType'], row['fullName']) for row in deployment['details']['componentSuccesses']
              if row.get('componentType')}
checks['deployment_exact_approved_permission_set_only'] = (
    deployment['id'] == '0Afaj00000pT3OYCA0' and deployment['status'] == 'Succeeded'
    and not deployment['checkOnly'] and deployment['numberComponentsDeployed'] == 1
    and deployment['numberComponentErrors'] == 0 and components == {('PermissionSet', NAME)})

old, current = rows('assignments_before'), rows('assignments_after')
added = [row for row in current if row not in old]
checks['exact_two_assignments_only'] = all(row in current for row in old) and len(added) == 2 and {
    (row['Id'], row['AssigneeId'], row['PermissionSetId'], row['PermissionSetGroupId']) for row in added} == {
        ('0Paaj000018ByQMCA0', USERS['A'], PID, None), ('0Paaj000018ByQNCA0', USERS['B'], PID, None)}
checks['customer_assignments_only_approved_sets'] = all(
    row['PermissionSetId'] in {'0PSaj00000h8ikhGAA', '0PSaj00000h8ikiGAA', PID}
    for row in current if row['AssigneeId'] in USERS.values())
for name in ['users', 'membership_criteria', 'members', 'network', 'ledger', 'scheduler']:
    checks[name + '_unchanged'] = rows(name + '_before') == rows(name + '_after')
checks['both_retain_site_membership'] = set(USERS.values()) <= {row['MemberId'] for row in rows('members_after')}

read_objects = {'Case', 'Service_Visit__c', 'Loyalty_Member__c'}
for label, uid in USERS.items():
    for obj in ['Case', 'Service_Visit__c', 'Loyalty_Member__c', 'Vehicle__c', 'Vehicle_Model__c',
                'Contact_Vehicle_Relationship__c']:
        name = 'A_effective_case_access' if label == 'A' and obj == 'Case' else label + '_effective_' + obj
        access = rows(name)
        checks[label + '/effective_object/' + obj] = len(access) == 1 and access[0]['UserId'] == uid and (
            access[0]['IsReadable'] == (obj in read_objects) and not access[0]['IsCreatable']
            and not access[0]['IsEditable'] and not access[0]['IsUpdatable'] and not access[0]['IsDeletable'])
    access = rows(label + '_record_isolation')
    checks[label + '/native_record_sample_isolation'] = len(access) == 15 and all(
        row['HasReadAccess'] == (row['RecordId'] in OWN_RECORDS[label]) and not row['HasEditAccess']
        and not row['HasDeleteAccess'] and not row['HasAllAccess'] for row in access)
    checks[label + '/facade_apex_access'] = any(row['AssigneeId'] == uid and row['PermissionSetId'] == PID for row in current) and any(
        row['ParentId'] == PID and row['SetupEntityType'] == 'ApexClass'
        and row['SetupEntityId'] == '01paj00000c9U5pAAE' for row in rows('current_apex_access'))

checks['no_view_all_modify_all_record_grants'] = all(
    not row['PermissionsViewAllRecords'] and not row['PermissionsModifyAllRecords']
    for row in rows('current_effective_object_grants'))
checks['no_broad_system_grants'] = all(
    not value for row in rows('current_system_flags') for key, value in row.items() if key.startswith('Permissions'))
fields = rows('runtime_field_permissions')
expected_fields = {'Case.ContactId', 'Service_Visit__c.Status__c', 'Service_Visit__c.Service_Type__c',
                   'Loyalty_Member__c.Points_Balance__c', 'Loyalty_Member__c.Status__c', 'Loyalty_Member__c.Tier__c'}
checks['deployed_fls_definition_exact_six_read_only'] = len(fields) == 6 and {row['Field'] for row in fields} == expected_fields and all(
    row['PermissionsRead'] and not row['PermissionsEdit'] for row in fields)
checks['vehicle_shares_still_empty'] = rows('vehicle_shares') == []
checks['ledger_shares_internal_owner_only'] = len(rows('ledger_shares')) == 4 and all(
    row['RowCause'] == 'Owner' and row['UserOrGroupId'] == '005aj00000feqbNAAQ' for row in rows('ledger_shares'))

now = datetime.now(timezone.utc)


def current_verified(row):
    return (row['Status__c'] == 'Verified' and row['Verified_By__c'] is not None
            and row['Verified_At__c'] is not None and datetime.fromisoformat(row['Verified_At__c']) <= now
            and row['Evidence_Type__c'] == 'Approved_Synthetic_Fixture' and bool(row['Evidence_Reference__c'])
            and datetime.fromisoformat(row['Effective_From__c']) <= now
            and (row['Effective_To__c'] is None or now < datetime.fromisoformat(row['Effective_To__c']))
            and (row['Revoked_At__c'] is None or now < datetime.fromisoformat(row['Revoked_At__c'])))


ledger = rows('ledger_after')
for label, contact, vehicle in [('A', '003aj00002Xl4IfAAJ', 'a0Daj00001D2FPaEAN'),
                                ('B', '003aj00002Xl4IgAAJ', 'a0Daj00001D2FPbEAN')]:
    own = [row for row in ledger if row['Vehicle__c'] == vehicle and row['Relationship_Type__c'] == 'Ownership']
    consent = [row for row in ledger if row['Vehicle__c'] == vehicle and row['Relationship_Type__c'] == 'Service_Authorization']
    checks[label + '/ledger_snapshot_current_exclusive_ownership_and_separate_consent'] = len(own) == len(consent) == 1 and all(
        row['Contact__c'] == contact and current_verified(row) for row in own + consent)

hashes = json.loads((OUT / 'submitted_hashes.json').read_text())
checks['reviewed_source_and_manifest_unchanged'] = all(
    hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest for name, digest in hashes.items())
previous = json.loads((ROOT / 'evidence/P8/BROKER_DEPLOYMENT/source_parity.json').read_text())['sha256']
checks['existing_55_development_hashes_unchanged'] = all(
    hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest for name, digest in previous.items())
field_api = json.loads((OUT / 'field_api_errors.json').read_text())
report = {'deploymentStatus': 'Succeeded', 'securityValidationStatus': 'PARTIAL',
          'observedAtUtc': now.isoformat(),
          'checks': {key: 'CONFIRMED' if value else 'REFUTED' for key, value in checks.items()},
          'validationId': validation['id'], 'deploymentId': deployment['id'], 'permissionSetId': PID,
          'assignmentsAdded': added, 'targetedApexTestsPassed': 22, 'localTestsPassed': 10,
          'effectiveFieldApiStatus': field_api['status'],
          'limitations': ['UserFieldAccess raised UNKNOWN_EXCEPTION; stopped, no retries; effective-field API proof incomplete',
                          'Six deployed FieldPermissions are confirmed exactly; this is not substituted for authenticated USER_MODE execution',
                          'No A/B authenticated browser/runtime success claimed: no connected browser extension',
                          'Existing targeted Apex tests use historical fixture permission sets, not this new minimal combination',
                          'Record access checked for 15 actual records per user including 3 unrelated samples, not exhaustive all-record coverage',
                          'Ledger predicates checked against current snapshot; live Network-context broker invocation by A/B remains untested'],
          'browserUat': 'READY_TO_BEGIN_OWNER_TESTING_NOT_PASSED', 'phase8Complete': False,
          'explicitShareWrites': 0, 'persistentBusinessFixtureWrites': 0, 'additionalDeployments': 0, 'gitOperations': 0}
(OUT / 'verification.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
assert all(checks.values()), 'Stop: a completed security/preservation check was REFUTED'
