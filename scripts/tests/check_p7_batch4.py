"""Offline Batch 4 scope/docs/link/source checks; no Salesforce calls or prior test rerun."""
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'force-app/main/default'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}


def main():
    package = ET.parse(ROOT / 'manifest/p7-batch4-check.xml').getroot()
    members = {node.find('m:name', NS).text: {child.text for child in node.findall('m:members', NS)}
               for node in package.findall('m:types', NS)}
    assert members == {'LightningComponentBundle': {'vehiclePhotoHeader'}, 'FlexiPage': {'NG_Vehicle_Photo_Header'}}
    bundle = SOURCE / 'lwc/vehiclePhotoHeader'
    assert {path.name for path in bundle.iterdir()} == {'vehiclePhotoHeader.js', 'vehiclePhotoHeader.html',
                                                     'vehiclePhotoHeader.css', 'vehiclePhotoHeader.js-meta.xml'}
    javascript = (bundle / 'vehiclePhotoHeader.js').read_text()
    assert "from 'lightning/uiRecordApi'" in javascript and 'optionalFields:' in javascript
    assert not any(name in javascript for name in ['@salesforce/apex/', 'innerHTML', 'updateRecord', 'createRecord', 'deleteRecord'])
    html = (bundle / 'vehiclePhotoHeader.html').read_text()
    assert 'alt={imageAlt}' in html and 'role="status"' in html and 'role="alert"' in html
    assert not any(name in html for name in ['lwc:dom', 'lightning-record-edit-form', '<iframe'])
    metadata = ET.parse(bundle / 'vehiclePhotoHeader.js-meta.xml').getroot()
    assert [node.text for node in metadata.findall('m:targets/m:target', NS)] == ['lightning__RecordPage']
    assert metadata.find('m:targetConfigs/m:targetConfig/m:objects/m:object', NS).text == 'Vehicle__c'
    page_path = SOURCE / 'flexipages/NG_Vehicle_Photo_Header.flexipage-meta.xml'
    page = ET.parse(page_path).getroot()
    assert page.find('m:sobjectType', NS).text == 'Vehicle__c'
    components = [node.text for node in page.findall('.//m:componentName', NS)]
    assert components == ['force:highlightsPanel', 'vehiclePhotoHeader', 'force:detailPanel', 'vehicleServiceHistory']
    assert page.find('m:parentFlexiPage', NS) is None
    protected = {}
    for filename in ['BATCH2_LOCAL_SCOPE_CHECK.json', 'P7_12_LOCAL_METADATA_CHECK.json']:
        snapshot = json.loads((ROOT / 'evidence/P7' / filename).read_text())
        protected.update(snapshot.get('sourceSha256', snapshot.get('sha256', {})))
    for relative, digest in protected.items():
        assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == digest, relative
    prompt = ROOT / 'force-app/main/default/genAiPromptTemplates/NG_Case_Triage.genAiPromptTemplate-meta.xml'
    prior = json.loads((ROOT / 'evidence/P7/BATCH3_LOCAL_CHECK.json').read_text())
    assert hashlib.sha256(prompt.read_bytes()).hexdigest() == prior['promptSourceSha256']
    scripts = [ROOT / 'evidence/DEMO_SCRIPTS' / (name + '.md')
               for name in ['admin', 'developer', 'analyst', 'support', 'architect']]
    for path in scripts:
        text = path.read_text()
        assert re.search(r'^## 1\. Activate persona\n', text, re.MULTILINE)
        assert not re.search(r'(^|\n)\s*(?:\./)?scripts/persona\.sh\s', text)
    documents = [ROOT / 'README.md', ROOT / 'docs/architecture/AUTOMOTIVE_CLOUD_MAPPING.md',
                 ROOT / 'evidence/DEMO_SCRIPTS/README.md', ROOT / 'docs/verification/P7_VEHICLE_PHOTO_HEADER.md',
                 ROOT / 'evidence/P7/BATCH4_EXECUTION.md', *scripts]
    links = 0
    for path in documents:
        text = path.read_text()
        for link in re.findall(r'\[[^\]]*\]\(([^)]+)\)', text):
            if link.startswith(('https://', 'http://', '#')):
                continue
            target = link.split('#')[0]
            assert (path.parent / target).exists(), (str(path.relative_to(ROOT)), link)
            links += 1
    assert 'docs/GOVERNANCE.md' in (ROOT / 'README.md').read_text()
    assert 'NOT RUN / NOT SIGNED OFF' in (ROOT / 'evidence/DEMO_SCRIPTS/README.md').read_text()
    assert 'historical' in (ROOT / 'evidence/DEMO_SCRIPTS/01_lead_to_testdrive.md').read_text().lower()
    selected = [*bundle.iterdir(), page_path, ROOT / 'manifest/p7-batch4-check.xml']
    for path in selected + documents + [Path(__file__), ROOT / 'scripts/tests/vehicle_photo_header.test.mjs']:
        assert all(line == line.rstrip() for line in path.read_text().splitlines()), path.name
    output = {'status': 'PASS', 'metadataComponents': 2, 'apexComponents': 0,
              'photoReader': 'Lightning UI API; required Name and optional photo/model fields',
              'currentPersonaScripts': 5, 'localLinksChecked': links, 'priorBatch2SourceHashesPreserved': len(protected),
              'batch3DraftPromptUnchangedAndExcluded': True, 'apexTestsRerun': 0,
              'pageAssignmentsIncluded': 0, 'actualScreenshotsAndWalkthroughs': 'NOT VERIFIED',
              'selectedSha256': {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest() for path in selected}}
    (ROOT / 'evidence/P7/BATCH4_LOCAL_CHECK.json').write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps({key: value for key, value in output.items() if key != 'selectedSha256'}, indent=2))


if __name__ == '__main__':
    main()
