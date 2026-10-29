"""Offline exact-scope/access checks for P7-12; never calls Salesforce or runs Apex tests."""
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

from check_p7_batch2 import CLASSES, REMOVED, TRIGGERS

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'force-app/main/default'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
MODEL = 'NG_Rooftops'
TERRITORIES = {'Downtown', 'North', 'Airport', 'Service_Centre'}


def members(path):
    return {node.find('m:name', NS).text: {m.text for m in node.findall('m:members', NS)}
            for node in ET.parse(path).getroot().findall('m:types', NS)}


def main():
    expected = {'Territory2Type': {'NG_Rooftop'}, 'Territory2Model': {MODEL},
                'Territory2': {MODEL + '.' + name for name in TERRITORIES}}
    assert members(ROOT / 'manifest/p7-12-territories.xml') == expected
    folder = SOURCE / 'territory2Models' / MODEL
    model = folder / (MODEL + '.territory2Model-meta.xml')
    territory_type = SOURCE / 'territory2Types/NG_Rooftop.territory2Type-meta.xml'
    paths = [model, territory_type] + sorted((folder / 'territories').glob('*.territory2-meta.xml'))
    assert len(paths) == 6
    assert set(folder.rglob('*.*')) == set(paths) - {territory_type}, 'No rules, memberships or extra model files'
    assert ET.parse(model).getroot().find('m:name', NS).text == 'Northgate Motors'
    assert ET.parse(model).getroot().find('m:state', NS) is None, 'Activation state is not model metadata'
    assert ET.parse(territory_type).getroot().find('m:priority', NS).text == '1'
    inspection = json.loads((ROOT / 'evidence/P7/P7_12_DESIGN_INSPECTION.json').read_text())
    supported = {field['name']: {v['value'] for v in field['picklistValues'] if v['active']}
                 for field in inspection['nativeDescribe']['Territory2']['fields']}
    assert {path.name.removesuffix('.territory2-meta.xml') for path in paths[2:]} == TERRITORIES
    settings = {'accountAccessLevel': 'Read', 'contactAccessLevel': 'None',
                'opportunityAccessLevel': 'None', 'caseAccessLevel': 'None'}
    for path in paths[2:]:
        tree = ET.parse(path).getroot()
        assert tree.find('m:parentTerritory', NS) is None, 'All four territories must be siblings'
        assert tree.find('m:territory2Type', NS).text == 'NG_Rooftop'
        assert tree.find('m:ruleAssociations', NS) is None
        for name, value in settings.items():
            assert tree.find('m:' + name, NS).text == value
            assert value in supported[name[0].upper() + name[1:]], name
    original = json.loads((ROOT / 'evidence/P7/BATCH2_LOCAL_SCOPE_CHECK.json').read_text())
    for relative, digest in original['sourceSha256'].items():
        assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == digest, relative
    assert members(ROOT / 'manifest/p7-batch2-check.xml') == {'ApexClass': CLASSES, 'ApexTrigger': TRIGGERS}
    assert members(ROOT / 'manifest/p7-batch2-destructive.xml') == {'ApexTrigger': REMOVED}
    converted = ROOT / 'evidence/P7/P7_12_METADATA_CONVERSION'
    assert members(converted / 'package.xml') == expected
    expected_converted = {'package.xml'} | {
        str(path.relative_to(SOURCE)).removesuffix('-meta.xml') for path in paths}
    assert {str(path.relative_to(converted)) for path in converted.rglob('*') if path.is_file()} == expected_converted
    for path in paths:
        target = converted / str(path.relative_to(SOURCE)).removesuffix('-meta.xml')
        assert ET.tostring(ET.parse(target).getroot()) == ET.tostring(ET.parse(path).getroot())
    for path in paths + [ROOT / 'manifest/p7-12-territories.xml', Path(__file__),
                         ROOT / 'scripts/tests/inspect_p7_12_design.py',
                         ROOT / 'docs/planning/P7_12_TERRITORY_DESIGN.md']:
        assert all(line == line.rstrip() for line in path.read_text().splitlines()), path.name
    output = {'status': 'PASS', 'localComponents': 6, 'model': MODEL, 'sharedType': 'NG_Rooftop',
              'siblingTerritories': sorted(TERRITORIES), 'explicitAccess': settings,
              'assignmentRules': 0, 'userMemberships': 0, 'settingsComponents': 0,
              'unchangedBatch2SourceFiles': len(original['sourceSha256']),
              'convertedComponentsChecked': 6,
              'serverValidation': 'NOT RUN: local-only preparation; default/override behavior requires scoped check-only approval',
              'apexTestsRerun': 0, 'sha256': {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}}
    (ROOT / 'evidence/P7/P7_12_LOCAL_METADATA_CHECK.json').write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps({key: value for key, value in output.items() if key != 'sha256'}, indent=2))


if __name__ == '__main__':
    main()
