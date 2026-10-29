"""Bounded Wikimedia Commons research and local stock-photo processing. No Salesforce writes."""
import argparse
import hashlib
import html
import io
import json
import re
import subprocess
import time
import urllib.parse
import zipfile
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[2]
API = 'https://commons.wikimedia.org/w/api.php'
REGISTER = ROOT / 'docs/assets/P7_VEHICLE_PHOTO_SOURCES.json'
RESOURCE = ROOT / 'force-app/main/default/staticresources/NG_VehicleImages'
CACHE = ROOT / 'evidence/P7/photo_sources'
AGENT = 'NorthgateDemoAssetPreparation/1.0 (Wikimedia Commons licensed-photo curation)'


def get(url):
    # Use the OS TLS trust store; never disable certificate verification or bypass access controls.
    for attempt in range(3):
        try:
            return subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location', '--max-time', '60',
                                   '--user-agent', AGENT, url], capture_output=True, check=True).stdout
        except subprocess.CalledProcessError as failure:
            # Retry only transient transport failures; HTTP access/rate errors are never bypassed.
            message = failure.stderr.decode(errors='replace')
            if re.search(r'\b(401|403|429)\b', message) or failure.returncode not in (28, 52, 56) or attempt == 2:
                raise RuntimeError(message) from failure
            time.sleep(2 ** (attempt + 1))


def api(**parameters):
    parameters.update(action='query', format='json', maxlag=5)
    result = json.loads(get(API + '?' + urllib.parse.urlencode(parameters)))
    if 'error' in result:
        raise RuntimeError(result['error'])
    return result.get('query', {}).get('pages', {})


def plain(value):
    return html.unescape(re.sub('<[^>]+>', '', value)).strip()


def metadata(page_id):
    page = api(pageids=str(page_id), prop='imageinfo', iiprop='url|size|extmetadata', iiurlwidth=1280)[str(page_id)]
    info = page['imageinfo'][0]
    extra = info['extmetadata']
    license_name = plain(extra.get('LicenseShortName', {}).get('value', ''))
    license_url = extra.get('LicenseUrl', {}).get('value', '')
    artist = plain(extra.get('Artist', {}).get('value', ''))
    license_location = urllib.parse.urlsplit(license_url)
    if (license_name != 'CC0' or license_location.hostname != 'creativecommons.org'
            or not license_location.path.startswith('/publicdomain/zero/1.0') or not artist):
        raise ValueError(f'Unapproved/missing rights metadata for {page_id}: {license_name}')
    return {'pageId': page_id, 'title': page['title'], 'photographer': artist,
            'source': 'Wikimedia Commons', 'sourcePage': info['descriptionurl'],
            'originalImageUrl': info['url'], 'downloadUrl': info.get('thumburl', info['url']),
            'license': license_name, 'licenseUrl': license_url,
            'description': plain(extra.get('ImageDescription', {}).get('value', '')),
            'credit': plain(extra.get('Credit', {}).get('value', '')),
            'dateTaken': plain(extra.get('DateTimeOriginal', {}).get('value', '')),
            'originalWidth': info['width'], 'originalHeight': info['height'],
            'rightsMetadata': extra, 'verifiedAtUtc': datetime.now(timezone.utc).isoformat()}


def search(query, limit):
    pages = api(generator='search', gsrsearch=query, gsrnamespace=6, gsrlimit=limit,
                prop='imageinfo', iiprop='extmetadata', iiextmetadatafilter='Artist|LicenseShortName|LicenseUrl')
    for page in sorted(pages.values(), key=lambda p: p.get('index', 0)):
        extra = page.get('imageinfo', [{}])[0].get('extmetadata', {})
        print(json.dumps({'id': page['pageid'], 'title': page['title'],
                          'license': plain(extra.get('LicenseShortName', {}).get('value', '')),
                          'photographer': plain(extra.get('Artist', {}).get('value', ''))}))


def fetch():
    selection = json.loads(REGISTER.read_text())
    CACHE.mkdir(parents=True, exist_ok=True)
    for entry in selection['photos']:
        target = CACHE / f"{entry['pageId']}.image"
        metadata_path = CACHE / f"{entry['pageId']}.json"
        if target.exists() and metadata_path.exists():
            continue
        info = metadata(entry['pageId'])
        time.sleep(3)
        data = get(info['downloadUrl'])
        with Image.open(io.BytesIO(data)) as image:
            image.verify()
        info['downloadSha256'] = hashlib.sha256(data).hexdigest()
        target.write_bytes(data)
        metadata_path.write_text(json.dumps(info, indent=2))
        print(json.dumps({'downloaded': entry['pageId'], 'file': entry['file'], 'license': info['license']}))
        time.sleep(3)


def sheet(processed=False):
    entries = json.loads(REGISTER.read_text())['photos']
    image = Image.new('RGB', (1600, ((len(entries) + 4) // 5) * 235), 'white')
    draw = ImageDraw.Draw(image)
    for i, entry in enumerate(entries):
        x, y = (i % 5) * 320, (i // 5) * 235
        path = RESOURCE / entry['file'] if processed else CACHE / f"{entry['pageId']}.image"
        if path.exists():
            source = ImageOps.exif_transpose(Image.open(path)).convert('RGB')
            thumb = ImageOps.contain(source, (310, 190))
            image.paste(thumb, (x + (310 - thumb.width) // 2, y))
        else:
            draw.text((x + 30, y + 80), 'DOWNLOAD PENDING', fill='gray')
        draw.text((x + 4, y + 192), entry['file'], fill='black')
        draw.text((x + 4, y + 208), str(entry['pageId']) + ' / ' + entry['bodyStyle'], fill='black')
    image.save(CACHE / ('processed-contact-sheet.jpg' if processed else 'contact-sheet.jpg'), quality=90)
    print('Contact sheet prepared.')


def build():
    register = json.loads(REGISTER.read_text())
    mapping = json.loads((ROOT / 'docs/assets/P7_VEHICLE_IMAGE_MAP.json').read_text())
    photos = register['photos']
    assert len(photos) == 30 and len({p['pageId'] for p in photos}) == 30
    assert {p['file'] for p in photos} == {p['file'] for p in mapping['assets']}
    review = register['visualReview']
    assert set(review['approvedPageIds']) == {p['pageId'] for p in photos}
    RESOURCE.mkdir(parents=True, exist_ok=True)
    hashes = set()
    for entry in photos:
        entry['visualReview'] = review['viewNotes'].get(entry['file'], review['defaultFinding'])
        info = json.loads((CACHE / f"{entry['pageId']}.json").read_text())
        data = (CACHE / f"{entry['pageId']}.image").read_bytes()
        assert hashlib.sha256(data).hexdigest() == info['downloadSha256']
        assert info['license'] == 'CC0'
        assert info['downloadSha256'] not in hashes
        hashes.add(info['downloadSha256'])
        source = ImageOps.exif_transpose(Image.open(io.BytesIO(data))).convert('RGB')
        resized = ImageOps.contain(source, (800, 600))
        canvas = Image.new('RGB', (800, 600), 'white')
        canvas.paste(resized, ((800 - resized.width) // 2, (600 - resized.height) // 2))
        # Preserve the entire source frame; no cropping, logo removal or background replacement.
        low, high, chosen = 60, 90, None
        for _ in range(7):
            quality = (low + high) // 2
            output = io.BytesIO()
            canvas.save(output, format='WEBP', quality=quality, method=6)
            chosen = (quality, output.getvalue())
            if len(chosen[1]) > 55 * 1024:
                high = quality - 1
            elif len(chosen[1]) < 42 * 1024:
                low = quality + 1
            else:
                break
            if low > high:
                break
        quality, optimized = chosen
        (RESOURCE / entry['file']).write_bytes(optimized)
        entry.update({k: v for k, v in info.items() if k != 'rightsMetadata'})
        entry.update(width=800, height=600, bytes=len(optimized), webpQuality=quality,
                     outputSha256=hashlib.sha256(optimized).hexdigest(),
                     processing='EXIF orientation, full-frame proportional resize, white letterbox, WebP conversion; no branding removed')
    REGISTER.write_text(json.dumps(register, indent=2) + '\n')
    notice = ('# NG_VehicleImages — illustrative stock photography\n\n'
              'Northgate names are fictional. Photographs depict real vehicles for an internal software demo, '
              'not exact inventory or an endorsement by any manufacturer or photographer. '
              'Incidental badges are retained, not deceptively removed. All selected photographs have '
              'verified CC0 1.0 source records; photographer/source credits are preserved below. '
              'CC0 copyright dedication does not grant trademark or endorsement rights.\n\n')
    for entry in photos:
        notice += f"- **{entry['file']}**: {entry['photographer']}, [original source]({entry['sourcePage']}), [CC0]({entry['licenseUrl']}). Full-frame resized/converted to WebP.\n"
    (RESOURCE / 'ATTRIBUTION.md').write_text(notice)
    (RESOURCE / 'licenses.json').write_text(json.dumps(register, indent=2) + '\n')
    package = ROOT / 'evidence/P7/NG_VehicleImages.zip'
    with zipfile.ZipFile(package, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(RESOURCE.iterdir()):
            archive.write(path, path.name)
    print(json.dumps({'photos': len(photos), 'webpBytes': sum(p['bytes'] for p in photos),
                      'zipBytes': package.stat().st_size, 'zipSha256': hashlib.sha256(package.read_bytes()).hexdigest()}, indent=2))


def inventory():
    register = json.loads(REGISTER.read_text())
    mapping = json.loads((ROOT / 'docs/assets/P7_VEHICLE_IMAGE_MAP.json').read_text())
    models = {a['file']: a['model'] for a in mapping['assets']}
    text = ('# P7-22 — thirty-photo inventory and rights register\n\n'
            'Owner-approved real automotive stock photographs replace the earlier AI-photo requirement. '
            'All thirty selected files have explicit CC0 1.0 source records on Wikimedia Commons. '
            'They illustrate fictional Northgate models, not exact inventory or endorsement. '
            'Incidental OEM badges are retained; no branding was removed.\n\n'
            'The machine-readable P7_VEHICLE_PHOTO_SOURCES.json records each original image URL, '
            'download variant, photographer, source page, exact license URL, rights-verification time, '
            'source/output hashes, approximate-year rationale, visual notes and processing. '
            'Full Commons rights metadata snapshots are in evidence/P7/photo_sources/. '
            'Copyright dedication does not assert trademark/model/property releases or endorsement.\n\n'
            '| File | Fictional model | Body style | Actual source photograph | Photographer | Rights | Bytes |\n'
            '|---|---|---|---|---|---|---:|\n')
    for entry in register['photos']:
        title = entry['title'].removeprefix('File:').replace('|', '/')
        artist = entry['photographer'].replace('|', '/')
        text += f"| `{entry['file']}` | {models[entry['file']]} | {entry['bodyStyle']} | [{title}]({entry['sourcePage']}) | {artist} | [CC0 1.0]({entry['licenseUrl']}) | {entry['bytes']} |\n"
    text += ('\nAll outputs are genuine 800×600 WebP, full-frame proportionally resized/letterboxed, '
             'without crop or logo removal. Front-quarter views are preferred; the registry explicitly '
             'identifies rear/side/elevated alternatives and approximate-year matches. '
             'No exact real manufacturer/year identity is represented as fictional Northgate inventory.\n\n'
             'Pexels license/terms and Unsplash access were reviewed. Unsplash returned 401 and was '
             'not bypassed; no Unsplash photograph is used. Pexels photographs were not selected '
             'because its current terms add systematic-copying, standalone-distribution and branded-use '
             'conditions unsuitable for this reusable asset package. No Pexels image is redistributed. '
             'Commons public API/downloads were used normally; a 429 paused collection for cooldown '
             'and slower requests, without access-control bypass.\n')
    (ROOT / 'docs/assets/P7_VEHICLE_PHOTO_INVENTORY.md').write_text(text)
    print(json.dumps({'inventoryRows': len(register['photos']), 'license': 'CC0 1.0', 'source': 'Wikimedia Commons'}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=('search', 'fetch', 'sheet', 'build', 'inventory'))
    parser.add_argument('--query')
    parser.add_argument('--limit', type=int, default=12)
    parser.add_argument('--processed', action='store_true')
    args = parser.parse_args()
    if args.command == 'search': search(args.query, args.limit)
    elif args.command == 'fetch': fetch()
    elif args.command == 'sheet': sheet(args.processed)
    elif args.command == 'build': build()
    else: inventory()
