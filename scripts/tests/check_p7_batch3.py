"""Local Batch 3 metadata/docs and preservation check; no Salesforce calls or Apex execution."""
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}


def main():
    package = ET.parse(ROOT / 'manifest/p7-batch3-check.xml').getroot()
    types = package.findall('m:types', NS)
    assert len(types) == 1 and types[0].find('m:name', NS).text == 'GenAiPromptTemplate'
    assert [node.text for node in types[0].findall('m:members', NS)] == ['NG_Case_Triage']
    path = ROOT / 'force-app/main/default/genAiPromptTemplates/NG_Case_Triage.genAiPromptTemplate-meta.xml'
    prompt = ET.parse(path).getroot()
    assert prompt.find('m:activeVersionIdentifier', NS) is None
    versions = prompt.findall('m:templateVersions', NS)
    assert len(versions) == 1 and versions[0].find('m:status', NS).text == 'Draft'
    content = versions[0].find('m:content', NS).text
    assert set(re.findall(r'\{!([^}]+)\}', content)) == {
        '$Input:caseRecord.Subject', '$Input:caseRecord.Status', '$Input:caseRecord.Priority'}
    assert versions[0].find('m:inputs/m:definition', NS).text == 'SOBJECT://Case'
    hashes = {}
    for name in ['BATCH2_LOCAL_SCOPE_CHECK.json', 'P7_12_LOCAL_METADATA_CHECK.json']:
        snapshot = json.loads((ROOT / 'evidence/P7' / name).read_text())
        hashes.update(snapshot.get('sourceSha256', snapshot.get('sha256', {})))
    for relative, digest in hashes.items():
        assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == digest, relative
    notes = ['SIMULATION_CPQ.md', 'SIMULATION_LOYALTY.md', 'SIMULATION_NURTURE.md',
             'SIMULATION_FIELD_SERVICE.md', 'SIMULATION_INTEGRATION.md']
    master = (ROOT / 'DEMO_ORG_MASTER_PLAN.md').read_text()
    for name in notes:
        assert (ROOT / 'docs/architecture' / name).is_file() and name in master
    assert (ROOT / 'docs/architecture/ORG_STRATEGY.md').is_file()
    for relative in ['scripts/test.sh', 'scripts/tests/p7_regression.py', 'scripts/tests/p7_regression_test.py',
                     'docs/planning/P7_BATCH3_CAPABILITY_GATES.md', 'docs/verification/P7_REGRESSION_GATE.md']:
        assert (ROOT / relative).is_file()
    output = {'status': 'PASS', 'batch3MetadataComponents': 1, 'promptStatus': 'Draft',
              'activePromptVersions': 0, 'caseInputFields': ['Subject', 'Status', 'Priority'],
              'seamNotesIndexed': 5, 'preservedBatch2SourceHashes': len(hashes), 'apexTestsRerun': 0,
              'promptSourceSha256': hashlib.sha256(path.read_bytes()).hexdigest(),
              'nativeAgentIngestionPortalAcceptance': 'NOT PASSED: capability/authorization gates documented'}
    (ROOT / 'evidence/P7/BATCH3_LOCAL_CHECK.json').write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps(output, indent=2))


if __name__ == '__main__':
    main()
