"""Owner-authorized Batch 2 deployment only; stop on failure, then verify live metadata read-only."""
import hashlib
import json
import subprocess
from pathlib import Path

from audit_p7_batch2 import query, sf
from check_p7_batch2 import CLASSES, REMOVED, TRIGGERS, members

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'evidence/P7'


def save(name, value):
    (EVIDENCE / name).write_text(json.dumps(value, indent=2) + '\n')


def tooling(soql):
    result = sf('data', 'query', '--use-tooling-api', '--query', soql)
    assert result['done']
    return result['records']


def deploy(name, args, expected, deleted):
    command = ['sf', 'project', 'deploy', 'start', '--target-org', 'ng-demo', *args,
               '--test-level', 'NoTestRun', '--wait', '10', '--json']
    process = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    raw = json.loads(process.stdout.replace(str(ROOT) + '/', '').replace(str(ROOT), '.'))
    raw.get('result', {}).pop('createdByName', None)
    save(name + '.json', raw)
    save(name + '_COMMAND.json', command)
    result = raw.get('result', {})
    print(json.dumps({key: result.get(key) for key in ['id', 'status', 'checkOnly', 'numberComponentsDeployed',
          'numberComponentsTotal', 'numberComponentErrors', 'numberTestsCompleted', 'numberTestsTotal']}, indent=2), flush=True)
    if process.returncode or result.get('status') != 'Succeeded':
        raise RuntimeError(json.dumps(raw))
    assert result['checkOnly'] is False and result['rollbackOnError'] is True
    rows = [row for row in result['details']['componentSuccesses'] if row['componentType']]
    assert {(row['componentType'], row['fullName']) for row in rows} == expected
    assert {row['fullName'] for row in rows if row.get('deleted')} == deleted
    return result['id']


def main():
    assert query('SELECT Id, OrganizationType FROM Organization')[0] == {
        'Id': '00Daj00001Ae3iWEAR', 'OrganizationType': 'Developer Edition'}
    assert members(ROOT / 'manifest/p7-batch2-check.xml') == {'ApexClass': CLASSES, 'ApexTrigger': TRIGGERS}
    assert members(ROOT / 'manifest/p7-batch2-destructive.xml') == {'ApexTrigger': REMOVED}
    validation = json.loads((EVIDENCE / 'BATCH2_CHECK_ONLY.json').read_text())['result']
    assert validation['id'] == '0Afaj00000p7GCLCA2' and validation['status'] == 'Succeeded'
    assert validation['numberTestsCompleted'] == 235 and validation['numberTestErrors'] == 0
    expected_app = {('ApexClass', name) for name in CLASSES} | {('ApexTrigger', name) for name in TRIGGERS | REMOVED}
    assert {(r['componentType'], r['fullName']) for r in validation['details']['componentSuccesses'] if r['componentType']} == expected_app
    prior_command = json.loads((EVIDENCE / 'BATCH2_CHECK_ONLY_COMMAND.json').read_text())
    assert prior_command[prior_command.index('--pre-destructive-changes') + 1] == 'manifest/p7-batch2-destructive.xml'
    snapshots = ['BATCH2_LOCAL_SCOPE_CHECK.json', 'P7_12_LOCAL_METADATA_CHECK.json']
    hashes = {}
    for filename in snapshots:
        snapshot = json.loads((EVIDENCE / filename).read_text())
        hashes.update(snapshot.get('sourceSha256', snapshot.get('sha256', {})))
    for relative, digest in hashes.items():
        assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == digest, relative
    territory_validation = json.loads((EVIDENCE / 'P7_12_SCOPED_VALIDATION.json').read_text())['result']
    expected_territory = {(row['componentType'], row['fullName']) for row in territory_validation['details']['componentSuccesses']}
    assert territory_validation['id'] == '0Afaj00000p7zkYCAQ' and territory_validation['status'] == 'Succeeded'
    assert members(ROOT / 'manifest/p7-12-territories.xml') == {
        'Territory2Type': {'NG_Rooftop'}, 'Territory2Model': {'NG_Rooftops'},
        'Territory2': {'NG_Rooftops.' + name for name in ['Airport', 'Downtown', 'North', 'Service_Centre']}}
    assert not query("SELECT Id FROM Territory2Model WHERE DeveloperName = 'NG_Rooftops'")
    assert not query("SELECT Id FROM Territory2Type WHERE DeveloperName = 'NG_Rooftop'")
    before_triggers = tooling('SELECT Name, TableEnumOrId, Status, Body FROM ApexTrigger')
    original_other = {row['Name']: hashlib.sha256(row['Body'].encode()).hexdigest()
                      for row in before_triggers if row['Name'] not in TRIGGERS | REMOVED}
    baseline = {'sourceFilesVerified': len(hashes), 'atomicFormat': 'destructiveChangesPre.xml via --pre-destructive-changes',
                'priorCombinedValidation': validation['id'], 'combinedComponentChanges': len(expected_app),
                'unrelatedTriggerHashes': original_other}
    save('BATCH2_DEPLOYMENT_PREFLIGHT.json', baseline)
    print(json.dumps(baseline, indent=2), flush=True)
    app_id = deploy('BATCH2_APPLICATION_DEPLOYMENT', [
        '--manifest', 'manifest/p7-batch2-check.xml', '--pre-destructive-changes', 'manifest/p7-batch2-destructive.xml'],
        expected_app, REMOVED)
    after_triggers = tooling('SELECT Name, TableEnumOrId, Status, Body FROM ApexTrigger')
    assert not ({row['Name'] for row in after_triggers} & REMOVED)
    assert {row['Name'] for row in after_triggers if row['TableEnumOrId'] in ['Lead', 'Vehicle__c', 'Test_Drive__c']} == TRIGGERS
    assert {row['Name']: hashlib.sha256(row['Body'].encode()).hexdigest()
            for row in after_triggers if row['Name'] not in TRIGGERS} == original_other
    for row in after_triggers:
        if row['Name'] in TRIGGERS:
            assert row['Status'] == 'Active'
            assert row['Body'].strip() == (ROOT / 'force-app/main/default/triggers' / (row['Name'] + '.trigger')).read_text().strip()
    names = ','.join("'" + name + "'" for name in sorted(CLASSES))
    live_classes = tooling('SELECT Name, Body FROM ApexClass WHERE Name IN (' + names + ')')
    assert {row['Name'] for row in live_classes} == CLASSES
    for row in live_classes:
        assert row['Body'].strip() == (ROOT / 'force-app/main/default/classes' / (row['Name'] + '.cls')).read_text().strip()
    save('BATCH2_APPLICATION_READBACK.json', {'status': 'PASS', 'deploymentId': app_id,
        'activeEntryTriggers': sorted(TRIGGERS), 'obsoleteTriggersAbsent': sorted(REMOVED),
        'classBodiesMatchSource': len(live_classes), 'unrelatedTriggersUnchanged': len(original_other)})
    territory_id = deploy('BATCH2_TERRITORY_DEPLOYMENT', ['--manifest', 'manifest/p7-12-territories.xml'], expected_territory, set())
    models = query("SELECT Id, DeveloperName, State FROM Territory2Model WHERE DeveloperName = 'NG_Rooftops'")
    types = query("SELECT Id, DeveloperName, Priority FROM Territory2Type WHERE DeveloperName = 'NG_Rooftop'")
    territories = query("SELECT Id, DeveloperName, ParentTerritory2Id, Territory2Type.DeveloperName, AccountAccessLevel, "
                        "ContactAccessLevel, OpportunityAccessLevel, CaseAccessLevel FROM Territory2 "
                        "WHERE Territory2Model.DeveloperName = 'NG_Rooftops'")
    object_links = query("SELECT COUNT(Id) total FROM ObjectTerritory2Association WHERE Territory2.Territory2Model.DeveloperName = 'NG_Rooftops'")
    user_links = query("SELECT COUNT(Id) total FROM UserTerritory2Association WHERE Territory2.Territory2Model.DeveloperName = 'NG_Rooftops'")
    readback = {'deploymentId': territory_id, 'models': models, 'types': types, 'territories': territories,
                'objectAssociations': object_links, 'userMemberships': user_links}
    save('BATCH2_TERRITORY_READBACK.json', readback)
    assert len(models) == len(types) == 1 and models[0]['State'] == 'Planning' and types[0]['Priority'] == 1
    assert {row['DeveloperName'] for row in territories} == {'Airport', 'Downtown', 'North', 'Service_Centre'}
    for row in territories:
        assert row['ParentTerritory2Id'] is None and row['Territory2Type']['DeveloperName'] == 'NG_Rooftop'
        assert [row[key] for key in ['AccountAccessLevel', 'ContactAccessLevel', 'OpportunityAccessLevel', 'CaseAccessLevel']] == ['Read', 'None', 'None', 'None']
    assert object_links == user_links == [{'total': 0}]
    for relative, digest in hashes.items():
        assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == digest
    print(json.dumps({'status': 'PASS', 'applicationDeployment': app_id, 'territoryDeployment': territory_id,
                      'modelState': models[0]['State'], 'territories': len(territories),
                      'accessValuesPersisted': ['Read', 'None', 'None', 'None'],
                      'accountAssociations': 0, 'userMemberships': 0, 'newTestsRun': 0,
                      'selectedSourceFilesUnchanged': len(hashes)}, indent=2))


if __name__ == '__main__':
    main()
