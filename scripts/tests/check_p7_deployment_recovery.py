"""Verify exact authorized component sets/current source before standard deployment; no org writes."""
import hashlib
import json
import subprocess
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'force-app/main/default'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}


def report(job):
    command = subprocess.run(['sf', 'project', 'deploy', 'report', '--target-org', 'ng-demo', '--job-id', job, '--json'],
                             text=True, capture_output=True, check=True)
    response = json.loads(command.stdout)
    assert response['status'] == 0
    result = response['result']
    assert result['success'] and result['checkOnly'] and result['status'] == 'Succeeded'
    return result


def members(path):
    root = ET.parse(ROOT / path).getroot()
    return {(t.findtext('m:name', namespaces=NS), m.text)
            for t in root.findall('m:types', NS) for m in t.findall('m:members', NS)}


def check():
    snapshots = []
    for manifest, job, count in [('manifest/p7-22-images-check.xml', '0Afaj00000p4yTFCAY', 1),
                                  ('manifest/p7-batch1-check.xml', '0Afaj00000p2bfeCAA', 21)]:
        result = report(job)
        expected = {(c['componentType'], c['fullName']) for c in result['details']['componentSuccesses'] if c.get('componentType')}
        assert len(expected) == count and members(manifest) == expected
        hashes = {}
        source_files = set()
        for kind, name in expected:
            if kind in ('ApexClass', 'ApexTrigger'):
                folder, suffix = ('classes', '.cls') if kind == 'ApexClass' else ('triggers', '.trigger')
                source_files.update([SOURCE / folder / (name + suffix), SOURCE / folder / (name + suffix + '-meta.xml')])
            elif kind == 'CustomField':
                obj, field = name.split('.')
                source_files.add(SOURCE / 'objects' / obj / 'fields' / (field + '.field-meta.xml'))
            elif kind == 'CustomObject':
                obj_files = set((SOURCE / 'objects' / name).rglob('*'))
                allowed = {SOURCE / 'objects' / name / (name + '.object-meta.xml')} | {
                    SOURCE / 'objects' / name / 'fields' / (field.split('.')[1] + '.field-meta.xml')
                    for t, field in expected if t == 'CustomField' and field.startswith(name + '.')}
                assert {p for p in obj_files if p.is_file()} == allowed
                source_files.add(SOURCE / 'objects' / name / (name + '.object-meta.xml'))
            elif kind == 'LightningComponentBundle':
                allowed = {'inventoryGallery': {'inventoryGallery.js', 'inventoryGallery.html', 'inventoryGallery.css', 'inventoryGallery.js-meta.xml'},
                           'opportunityCalculator': {'opportunityCalculator.js', 'opportunityCalculator.html', 'opportunityCalculator.js-meta.xml'}}[name]
                files = {p for p in (SOURCE / 'lwc' / name).rglob('*') if p.is_file()}
                assert {p.name for p in files} == allowed
                source_files.update(files)
            elif kind == 'StaticResource':
                source_files.add(SOURCE / 'staticresources' / (name + '.resource-meta.xml'))
                directory = SOURCE / 'staticresources' / name
                files = {p for p in directory.rglob('*') if p.is_file()}
                mapping = json.loads((ROOT / 'docs/assets/P7_VEHICLE_IMAGE_MAP.json').read_text())
                assert {str(p.relative_to(directory)) for p in files} == {a['file'] for a in mapping['assets']} | {'ATTRIBUTION.md', 'licenses.json'}
                source_files.update(files)
            else:
                folder, suffix = {'PermissionSet': ('permissionsets', '.permissionset-meta.xml'),
                                  'CustomPermission': ('customPermissions', '.customPermission-meta.xml'),
                                  'CustomTab': ('tabs', '.tab-meta.xml')}[kind]
                source_files.add(SOURCE / folder / (name + suffix))
        for path in sorted(source_files):
            assert path.is_file()
            hashes[str(path.relative_to(ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
        if count == 21:
            boundary = datetime.fromisoformat(result['completedDate'].replace('Z', '+00:00')).timestamp()
            changed = [str(p.relative_to(ROOT)) for p in source_files if p.stat().st_mtime > boundary]
            assert not changed, 'Selected application source newer than validated boundary: ' + ', '.join(changed)
        else:
            archive = ROOT / 'evidence/P7/NG_VehicleImages.zip'
            assert hashlib.sha256(archive.read_bytes()).hexdigest() == '67f1710386db658283f2d0649110128407c39bef9e28573ceccff805c0dffd7d'
        snapshots.append({'manifest': manifest, 'storedValidation': job, 'componentCount': count,
                          'sourceFileCount': len(source_files), 'sha256': hashes})
    evidence = {'checkedAtUtc': datetime.now(timezone.utc).isoformat(), 'status': 'PASS',
                'scopeMatchesStoredValidations': True, 'unexpectedSelectedSourceChanges': [],
                'applicationZipByteParity': 'Stored Salesforce ZIP unavailable; scope, file layout and pre-validation modification times checked, not sealed byte parity.',
                'packages': snapshots}
    (ROOT / 'evidence/P7/DEPLOYMENT_RECOVERY_PREFLIGHT_2026-10-25.json').write_text(json.dumps(evidence, indent=2) + '\n')
    print(json.dumps({'status': 'PASS', 'componentCounts': [1, 21], 'sourceFileCounts': [s['sourceFileCount'] for s in snapshots],
                      'scopeMatchesStoredValidations': True, 'unexpectedSelectedSourceChanges': [],
                      'assetArchiveMatchesRecordedHash': True}, indent=2))


if __name__ == '__main__':
    check()
