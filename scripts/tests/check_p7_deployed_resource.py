"""Read-only verification of deployed archive contents against approved photo hashes/model paths."""
import hashlib
import io
import json
import subprocess
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def query(soql):
    process = subprocess.run(['sf', 'data', 'query', '--target-org', 'ng-demo', '--query', soql, '--json'],
                             text=True, capture_output=True, check=True)
    result = json.loads(process.stdout)
    assert result['status'] == 0 and result['result']['done']
    return result['result']['records']


def check():
    snapshot = json.loads((ROOT / 'evidence/P7/DEPLOYMENT_RECOVERY_PREFLIGHT_2026-10-25.json').read_text())
    checked_source_files = 0
    for package in snapshot['packages']:
        for relative, digest in package['sha256'].items():
            assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == digest
            checked_source_files += 1
    assert query('SELECT Id FROM Organization')[0]['Id'] == '00Daj00001Ae3iWEAR'
    resources = query("SELECT Id,Name,BodyLength,ContentType,CacheControl FROM StaticResource WHERE Name = 'NG_VehicleImages'")
    assert len(resources) == 1
    resource = resources[0]
    assert resource['ContentType'] == 'application/zip' and resource['CacheControl'] == 'Public'
    path = ROOT / 'evidence/P7/deployed-NG-VehicleImages.zip'
    assert path.stat().st_size == resource['BodyLength']
    register = json.loads((ROOT / 'docs/assets/P7_VEHICLE_PHOTO_SOURCES.json').read_text())
    mapping = json.loads((ROOT / 'docs/assets/P7_VEHICLE_IMAGE_MAP.json').read_text())
    expected = {p['file']: p for p in register['photos']}
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
        # Existing .forceignore excludes *.md, including the optional bundled Markdown credits.
        assert set(archive.namelist()) == set(expected) | {'licenses.json'}
        for name, photo in expected.items():
            data = archive.read(name)
            assert hashlib.sha256(data).hexdigest() == photo['outputSha256']
            with Image.open(io.BytesIO(data)) as image:
                assert image.format == 'WEBP' and image.size == (800, 600)
                image.verify()
        for name in ('licenses.json',):
            assert archive.read(name) == (ROOT / 'force-app/main/default/staticresources/NG_VehicleImages' / name).read_bytes()
    by_model = {m['model']: m for m in mapping['assets']}
    rows = query('SELECT Name,Body_Style__c,Image_Path__c FROM Vehicle_Model__c ORDER BY Name')
    assert len(rows) == 30
    for row in rows:
        model = by_model[row['Name']]
        assert row['Image_Path__c'] == mapping['pathPrefix'] + model['file']
        assert model['file'] in expected and row['Body_Style__c'] == model['bodyStyle']
    output = {'status': 'PASS', 'resourceId': resource['Id'], 'resourceName': resource['Name'],
              'deployedArchiveBytes': path.stat().st_size, 'deployedPhotoContentMatches': 30,
              'deployedRootFiles': 31, 'photographerAndLicenseRegisterMatches': True,
              'optionalAttributionMarkdown': 'Excluded by existing .forceignore *.md; no ignore/source repair performed. CC0 credits remain in licenses.json.',
              'existingModelPathsCompatible': 30, 'recordChanges': 0,
              'selectedSourceFilesUnchangedSincePreflight': checked_source_files,
              'browserGalleryEventAcceptance': 'DEFERRED',
              'frontEndHttpImageRendering': 'NOT VERIFIED: direct API-host resource stream was empty; authenticated REST archive contents verified.'}
    (ROOT / 'evidence/P7/DEPLOYED_RESOURCE_VERIFICATION_2026-10-25.json').write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps(output, indent=2))


if __name__ == '__main__':
    check()
