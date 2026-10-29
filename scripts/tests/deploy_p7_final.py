"""Owner-authorized exact Batch 3/4 deployment; scoped read-only before/after verification."""
import hashlib
import json
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

from audit_p7_batch2 import query, sf
from check_p7_batch2 import members

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'evidence/P7'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
BUSINESS_OBJECTS = [
    'Account', 'Contact', 'Lead', 'Opportunity', 'Quote', 'QuoteLineItem', 'Product2', 'PricebookEntry',
    'Vehicle__c', 'Vehicle_Model__c', 'Rooftop__c', 'Staff__c', 'Trade_In__c', 'Financing__c',
    'Delivery__c', 'Test_Drive__c', 'Case', 'Service_Visit__c', 'Campaign', 'CampaignMember',
    'Loyalty_Member__c', 'Loyalty_Transaction__c', 'Consent__c', 'Task', 'Event', 'Data_Load_Batch__c', 'Knowledge__kav'
]


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def clean(value):
    if isinstance(value, dict):
        return {key: clean(item) for key, item in value.items()
                if key not in {'createdByName', 'lastModifiedByName', 'accessToken', 'refreshToken', 'username', 'deployUrl', 'attributes', 'stack'}}
    if isinstance(value, list):
        return [clean(item) for item in value]
    return value.replace(str(ROOT) + '/', '').replace(str(ROOT), '.') if isinstance(value, str) else value


def save(name, value):
    (EVIDENCE / name).write_text(json.dumps(clean(value), indent=2) + '\n')


def normalized(node):
    return {'tag': node.tag.split('}')[-1], 'text': (node.text or '').strip(),
            'attributes': dict(node.attrib), 'children': [normalized(child) for child in node]}


def baseline(label):
    directory = EVIDENCE / ('FINAL_' + label + '_METADATA')
    settings = ['Communities', 'EinsteinGpt', 'EinsteinCopilot', 'CustomerDataPlatform', 'Bot', 'AgentPlatform']
    result = sf('project', 'retrieve', 'start', '--metadata', 'CustomObject:Vehicle__c', 'CustomApplication:*',
                *['Settings:' + name for name in settings], '--target-metadata-dir',
                str(directory.relative_to(ROOT)), '--unzip', '--wait', '10')
    apps, object_overrides, setting_hashes = {}, [], {}
    for path in directory.rglob('*.app'):
        root = ET.parse(path).getroot()
        overrides = [normalized(child) for child in root if child.tag.split('}')[-1] in ['actionOverrides', 'profileActionOverrides']]
        # Include every app override; recordType/profile/form-factor assignment is held here.
        apps[path.stem] = overrides
    objects = list(directory.rglob('Vehicle__c.object'))
    assert len(objects) == 1
    for child in ET.parse(objects[0]).getroot():
        if child.tag.split('}')[-1] == 'actionOverrides':
            object_overrides.append(normalized(child))
    for path in directory.rglob('*.settings'):
        setting_hashes[path.stem] = digest(normalized(ET.parse(path).getroot()))
    assert set(setting_hashes) == set(settings) and apps
    assignments = {'vehicleObject': object_overrides, 'allApplicationOverrides': apps}
    save('FINAL_' + label + '_PAGE_ASSIGNMENTS.json', assignments)
    security = {
        'permissionAssignments': query('SELECT Id, AssigneeId, PermissionSetId, PermissionSetGroupId FROM PermissionSetAssignment ORDER BY Id'),
        'groupMembers': query('SELECT Id, PermissionSetGroupId, PermissionSetId FROM PermissionSetGroupComponent ORDER BY Id'),
        'objectPermissions': query('SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM ObjectPermissions ORDER BY Id'),
        'fieldPermissions': query('SELECT Id, ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions ORDER BY Id'),
        'userRoleProfileState': query('SELECT Id, IsActive, ProfileId, UserRoleId FROM User ORDER BY Id'),
    }
    security_hashes = {key: {'rows': len(rows), 'sha256': digest(clean(rows))} for key, rows in security.items()}
    stamps = {}
    for obj in BUSINESS_OBJECTS:
        rows = query('SELECT Id, LastModifiedDate FROM ' + obj + ' ORDER BY Id')
        stamps[obj] = {'rows': len(rows), 'idModificationSha256': digest(clean(rows))}
    triggers = sf('data', 'query', '--use-tooling-api', '--query', 'SELECT Name, Body, Status FROM ApexTrigger ORDER BY Name')
    assert triggers['done']
    trigger_hashes = {row['Name']: {'status': row['Status'], 'sha256': hashlib.sha256(row['Body'].encode()).hexdigest()}
                      for row in triggers['records']}
    output = {'retrieveId': result.get('id'), 'applicationDefinitionsRead': len(apps),
              'vehicleAndApplicationAssignmentSha256': digest(assignments), 'settingsSha256': setting_hashes,
              'securityFingerprints': security_hashes, 'businessRecordFingerprints': stamps,
              'triggerFingerprints': trigger_hashes,
              'limits': 'Business fingerprint covers IDs/LastModifiedDate of visible non-deleted rows, not a full field/history or background-event audit.'}
    save('FINAL_' + label + '_BASELINE.json', output)
    print(json.dumps({'baseline': label, 'retrieveId': result.get('id'), 'applicationsRead': len(apps),
                      'businessObjectsFingerprinted': len(stamps)}, indent=2), flush=True)
    return output


def deployment(label, validation_id, manifest, expected):
    quick = ['sf', 'project', 'deploy', 'quick', '--target-org', 'ng-demo', '--job-id', validation_id, '--wait', '10', '--json']
    process = subprocess.run(quick, cwd=ROOT, text=True, capture_output=True)
    raw = json.loads(process.stdout)
    save(label + '_QUICK_ATTEMPT.json', raw)
    if process.returncode:
        if raw.get('name') != 'CannotQuickDeployError':
            raise RuntimeError(json.dumps(clean(raw)))
        command = ['sf', 'project', 'deploy', 'start', '--target-org', 'ng-demo', '--manifest', manifest,
                   '--test-level', 'NoTestRun', '--wait', '10', '--json']
        process = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
        raw = json.loads(process.stdout)
        method = 'standard scoped fallback after explicit Quick Deploy unavailability'
    else:
        command = quick
        method = 'Quick Deploy'
    save(label + '_DEPLOYMENT.json', raw)
    save(label + '_COMMAND.json', command)
    result = raw.get('result', {})
    print(json.dumps({'scope': label, 'method': method, **{key: result.get(key) for key in
        ['id', 'status', 'checkOnly', 'numberComponentsDeployed', 'numberComponentsTotal', 'numberComponentErrors',
         'numberTestsCompleted', 'numberTestsTotal']}}, indent=2), flush=True)
    if process.returncode or result.get('status') != 'Succeeded':
        raise RuntimeError(json.dumps(clean(raw)))
    assert result['checkOnly'] is False
    rows = [row for row in result['details']['componentSuccesses'] if row['componentType']]
    assert {(row['componentType'], row['fullName']) for row in rows} == expected
    assert not any(row.get('deleted') for row in rows)
    return result['id']


def main():
    org = query('SELECT Id, OrganizationType FROM Organization')
    assert org == [{'Id': '00Daj00001Ae3iWEAR', 'OrganizationType': 'Developer Edition'}]
    expected3 = {'GenAiPromptTemplate': {'NG_Case_Triage'}}
    expected4 = {'LightningComponentBundle': {'vehiclePhotoHeader'}, 'FlexiPage': {'NG_Vehicle_Photo_Header'}}
    assert members(ROOT / 'manifest/p7-batch3-check.xml') == expected3
    assert members(ROOT / 'manifest/p7-batch4-check.xml') == expected4
    for name, expected_id in [('BATCH3_CHECK_ONLY.json', '0Afaj00000p8MduCAE'), ('BATCH4_CHECK_ONLY.json', '0Afaj00000pBPvPCAW')]:
        validated = json.loads((EVIDENCE / name).read_text())['result']
        assert validated['id'] == expected_id and validated['status'] == 'Succeeded' and validated['checkOnly']
    prompt_path = ROOT / 'force-app/main/default/genAiPromptTemplates/NG_Case_Triage.genAiPromptTemplate-meta.xml'
    prompt_hash = json.loads((EVIDENCE / 'BATCH3_LOCAL_CHECK.json').read_text())['promptSourceSha256']
    assert hashlib.sha256(prompt_path.read_bytes()).hexdigest() == prompt_hash
    hashes = json.loads((EVIDENCE / 'BATCH4_LOCAL_CHECK.json').read_text())['selectedSha256']
    for relative, value in hashes.items():
        assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == value, relative
    before = baseline('BEFORE')
    first = deployment('BATCH3_FINAL', '0Afaj00000p8MduCAE', 'manifest/p7-batch3-check.xml', {('GenAiPromptTemplate', 'NG_Case_Triage')})
    second = deployment('BATCH4_FINAL', '0Afaj00000pBPvPCAW', 'manifest/p7-batch4-check.xml',
                        {('LightningComponentBundle', 'vehiclePhotoHeader'), ('FlexiPage', 'NG_Vehicle_Photo_Header')})
    directory = EVIDENCE / 'FINAL_DEPLOYED_DEFINITIONS'
    readback = sf('project', 'retrieve', 'start', '--metadata', 'GenAiPromptTemplate:NG_Case_Triage',
                  'LightningComponentBundle:vehiclePhotoHeader', 'FlexiPage:NG_Vehicle_Photo_Header',
                  '--target-metadata-dir', str(directory.relative_to(ROOT)), '--unzip', '--wait', '10')
    prompts = list(directory.rglob('NG_Case_Triage.genAiPromptTemplate'))
    assert len(prompts) == 1
    prompt = ET.parse(prompts[0]).getroot()
    active = prompt.find('m:activeVersionIdentifier', NS)
    versions = prompt.findall('m:templateVersions', NS)
    inactive = active is None or not (active.text or '').strip()
    assert inactive and versions and all(node.find('m:status', NS).text == 'Draft' for node in versions)
    assert len(list(directory.rglob('NG_Vehicle_Photo_Header.flexipage'))) == 1
    assert len(list(directory.rglob('vehiclePhotoHeader.js'))) == 1
    after = baseline('AFTER')
    keys = ['vehicleAndApplicationAssignmentSha256', 'settingsSha256', 'securityFingerprints',
            'businessRecordFingerprints', 'triggerFingerprints']
    comparisons = {key: before[key] == after[key] for key in keys}
    territory = query("SELECT DeveloperName, State FROM Territory2Model WHERE DeveloperName = 'NG_Rooftops'")
    assert territory == [{'DeveloperName': 'NG_Rooftops', 'State': 'Planning'}]
    assert query("SELECT COUNT(Id) total FROM ObjectTerritory2Association WHERE Territory2.Territory2Model.DeveloperName = 'NG_Rooftops'") == [{'total': 0}]
    assert query("SELECT COUNT(Id) total FROM UserTerritory2Association WHERE Territory2.Territory2Model.DeveloperName = 'NG_Rooftops'") == [{'total': 0}]
    output = {'status': 'PASS' if all(comparisons.values()) else 'VERIFICATION DIFFERENCE',
              'organization': org, 'batch3Deployment': first, 'batch4Deployment': second,
              'readbackRetrieveId': readback.get('id'), 'promptInactive': inactive,
              'promptVersionStatuses': [node.find('m:status', NS).text for node in versions],
              'headerAndPageExist': True, 'unchangedComparisons': comparisons,
              'territoryModelState': 'Planning', 'accountAssociations': 0, 'userMemberships': 0,
              'newTestsRun': 0, 'phase8Implemented': False, 'pageActivatedOrAssigned': False}
    save('P7_FINAL_DEPLOYMENT_VERIFICATION.json', output)
    print(json.dumps(output, indent=2), flush=True)
    assert all(comparisons.values()), 'Read-only before/after comparison differs; investigate with owner, do not repair.'
    assert hashlib.sha256(prompt_path.read_bytes()).hexdigest() == prompt_hash
    for relative, value in hashes.items():
        assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == value


if __name__ == '__main__':
    main()
