"""Local complete-resource checks. Optional live path comparison is read-only, never a deploy."""
import argparse
import hashlib
import json
import statistics
import subprocess
import urllib.parse
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'force-app/main/default/staticresources/NG_VehicleImages'


def query(soql):
    process = subprocess.run(['sf', 'data', 'query', '--target-org', 'ng-demo', '--query', soql, '--json'],
                             capture_output=True, text=True, check=True)
    response = json.loads(process.stdout)
    assert response['status'] == 0 and response['result']['done']
    return response['result']['records']


def check(live=False):
    mapping = json.loads((ROOT / 'docs/assets/P7_VEHICLE_IMAGE_MAP.json').read_text())
    register = json.loads((ROOT / 'docs/assets/P7_VEHICLE_PHOTO_SOURCES.json').read_text())
    photos = register['photos']
    expected = {a['file']: a for a in mapping['assets']}
    assert len(photos) == 30 and len(expected) == 30
    assert len({p['pageId'] for p in photos}) == 30
    assert len({p['downloadSha256'] for p in photos}) == 30
    assert len({p['outputSha256'] for p in photos}) == 30
    assert {p['file'] for p in photos} == set(expected)
    assert {p.name for p in SOURCE.glob('*.webp')} == set(expected)
    sizes = []
    for entry in photos:
        assert entry['bodyStyle'] == expected[entry['file']]['bodyStyle']
        assert entry.get('visualReview') and entry['license'] == 'CC0' and entry['photographer']
        assert urllib.parse.urlsplit(entry['licenseUrl']).hostname == 'creativecommons.org'
        assert '/publicdomain/zero/1.0' in entry['licenseUrl']
        assert urllib.parse.urlsplit(entry['sourcePage']).hostname == 'commons.wikimedia.org'
        assert entry['originalImageUrl'].startswith('https://upload.wikimedia.org/')
        data = (SOURCE / entry['file']).read_bytes()
        assert data[:4] == b'RIFF' and data[8:12] == b'WEBP'
        assert hashlib.sha256(data).hexdigest() == entry['outputSha256']
        assert len(data) == entry['bytes'] and 5000 <= len(data) <= 120 * 1024
        with Image.open(SOURCE / entry['file']) as image:
            assert image.format == 'WEBP' and image.size == (800, 600) and image.n_frames == 1
            image.verify()
        sizes.append(len(data))
    package = ROOT / 'evidence/P7/NG_VehicleImages.zip'
    with zipfile.ZipFile(package) as archive:
        assert archive.testzip() is None
        assert set(archive.namelist()) == set(expected) | {'ATTRIBUTION.md', 'licenses.json'}
        assert all('/' not in name and '..' not in name for name in archive.namelist())
        assert sum(i.file_size for i in archive.infolist()) < 5 * 1024 * 1024
        for name in archive.namelist():
            assert archive.read(name) == (SOURCE / name).read_bytes()
    assert package.stat().st_size < 5 * 1024 * 1024
    if live:
        assert query('SELECT Id FROM Organization')[0]['Id'] == '00Daj00001Ae3iWEAR'
        rows = query('SELECT Name,Body_Style__c,Image_Path__c FROM Vehicle_Model__c ORDER BY Name')
        assert len(rows) == 30
        by_model = {a['model']: a for a in mapping['assets']}
        for row in rows:
            asset = by_model[row['Name']]
            assert row['Image_Path__c'] == mapping['pathPrefix'] + asset['file']
            assert row['Body_Style__c'] == asset['bodyStyle']
    print(json.dumps({'status': 'PASS', 'photos': 30, 'distinctPhotographs': 30, 'cc0Verified': 30,
                      'dimensions': '800x600', 'webpEncoding': 'RIFF/WEBP + Pillow verified',
                      'minBytes': min(sizes), 'medianBytes': statistics.median(sizes), 'maxBytes': max(sizes),
                      'totalImageBytes': sum(sizes), 'zipBytes': package.stat().st_size,
                      'zipSha256': hashlib.sha256(package.read_bytes()).hexdigest(),
                      'rootFilenamesAndZipIntegrity': True, 'livePathCompatibility': live,
                      'salesforceRecordChanges': 0}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--live', action='store_true')
    check(parser.parse_args().live)
