"""Local exact-scope and architecture checks; does not claim Apex execution."""
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'force-app/main/default'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
CLASSES = {'LeadTriggerHandler', 'VehicleTriggerHandler', 'TestDriveTriggerHandler',
           'LeadRoutingHandler', 'InventoryReconciliationJob', 'P7TriggerArchitectureTest',
           'InventoryReconciliationJobTest'}
TRIGGERS = {'LeadRoutingTrigger', 'VehicleTrigger', 'TestDriveTrigger'}
REMOVED = {'LeadBeforeConvertGuard', 'LeadAfterConvertSeedBlock',
           'VehicleCounterTrigger', 'TestDriveFollowupTrigger'}


def members(path):
    root = ET.parse(path).getroot()
    return {item.find('m:name', NS).text: {m.text for m in item.findall('m:members', NS)}
            for item in root.findall('m:types', NS)}


def main():
    assert members(ROOT / 'manifest/p7-batch2-check.xml') == {'ApexClass': CLASSES, 'ApexTrigger': TRIGGERS}
    assert members(ROOT / 'manifest/p7-batch2-destructive.xml') == {'ApexTrigger': REMOVED}
    inventory = {}
    for path in (SOURCE / 'triggers').glob('*.trigger'):
        match = re.search(r'trigger\s+(\w+)\s+on\s+(\w+)\s*\(', path.read_text())
        assert match, path.name
        inventory.setdefault(match[2], []).append(match[1])
    for obj, trigger in [('Lead', 'LeadRoutingTrigger'), ('Vehicle__c', 'VehicleTrigger'),
                         ('Test_Drive__c', 'TestDriveTrigger')]:
        assert inventory[obj] == [trigger], inventory[obj]
    for name in REMOVED:
        assert not (SOURCE / 'triggers' / (name + '.trigger')).exists()
        assert not (SOURCE / 'triggers' / (name + '.trigger-meta.xml')).exists()
    hashes = {}
    for folder, names, suffix in [('classes', CLASSES, '.cls'), ('triggers', TRIGGERS, '.trigger')]:
        for name in sorted(names):
            path = SOURCE / folder / (name + suffix)
            metadata = Path(str(path) + '-meta.xml')
            ET.parse(metadata)
            for selected in [path, metadata]:
                hashes[str(selected.relative_to(ROOT))] = hashlib.sha256(selected.read_bytes()).hexdigest()
            if not name.endswith('Test'):
                assert not re.search(r'System\.(enqueueJob|schedule)\s*\(', path.read_text()), name
    field = ET.parse(SOURCE / 'objects/Vehicle__c/fields/Inventory_Age_Days__c.field-meta.xml').getroot()
    assert field.find('m:formula', NS).text == 'TODAY() - Acquisition_Date__c'
    audit = json.loads((ROOT / 'evidence/P7/BATCH2_PERMISSION_TERRITORY_AUDIT.json').read_text())
    assert audit['organization'][0]['Id'] == '00Daj00001Ae3iWEAR'
    for relative in ['README.md', 'DEMO_ORG_BACKLOG.md']:
        assert 'docs/GOVERNANCE.md' in (ROOT / relative).read_text()
    local_files = list(hashes) + [
        'README.md', 'docs/GOVERNANCE.md', 'docs/TECH_DEBT.md',
        'docs/security/P7_PERMISSION_AUDIT.md', 'docs/planning/P7_BATCH2_IMPLEMENTATION_PLAN.md',
        'manifest/p7-batch2-check.xml', 'manifest/p7-batch2-destructive.xml',
        'scripts/tests/audit_p7_batch2.py', 'scripts/tests/check_p7_batch2.py',
        'scripts/tests/validate_p7_batch2.py', 'scripts/tests/report_p7_batch2.py',
        'evidence/P7/BATCH2_EXECUTION.md', 'evidence/P7/BATCH2_TERRITORY_CAPABILITY.md',
    ]
    for relative in local_files:
        for number, line in enumerate((ROOT / relative).read_text().splitlines(), 1):
            assert line == line.rstrip(), (relative, number, 'Trailing whitespace')
    output = {'status': 'PASS', 'replacementComponents': 10, 'removedTriggers': sorted(REMOVED),
              'singleEntryTriggers': {obj: inventory[obj] for obj in ['Lead', 'Vehicle__c', 'Test_Drive__c']},
              'inventoryAge': 'Existing native formula; no field write', 'automaticMaintenanceEnqueue': False,
              'sourceFileCount': len(hashes), 'sourceSha256': hashes,
              'governanceReferences': ['README.md', 'DEMO_ORG_BACKLOG.md'],
              'localWhitespaceFilesChecked': len(local_files),
              'territoryDisposition': audit['territoryCapability']['disposition'],
              'apexExecution': 'Not established by this local structural check'}
    (ROOT / 'evidence/P7/BATCH2_LOCAL_SCOPE_CHECK.json').write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps({key: value for key, value in output.items() if key != 'sourceSha256'}, indent=2))


if __name__ == '__main__':
    main()
