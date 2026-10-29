"""Read-only package/image-contract checks; missing photographs remain an explicit blocker."""
import itertools
import json
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'force-app/main/default'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
manifest = ET.parse(ROOT / 'manifest/p7-batch1-check.xml').getroot()
types = {t.findtext('m:name', namespaces=NS): [m.text for m in t.findall('m:members', NS)]
         for t in manifest.findall('m:types', NS)}
assert sum(map(len, types.values())) == 21
assert not {'Flow', 'Settings', 'Profile', 'NamedCredential', 'ExternalCredential', 'StaticResource'}.intersection(types)
assert types['ApexTrigger'] == ['VehicleCounterTrigger']
assert set(types['ApexClass']) == {'InventoryGalleryController', 'OpportunityCalculatorController', 'VinDecoderService',
    'VehicleReservationEventPublisher', 'VehicleCounters', 'P7Batch1TestData', 'InventoryGalleryControllerTest',
    'OpportunityCalculatorControllerTest', 'VinDecoderServiceTest', 'VehicleReservationEventPublisherTest'}
event = ET.parse(SOURCE / 'objects/Vehicle_Reserved__e/Vehicle_Reserved__e.object-meta.xml').getroot()
assert event.findtext('m:publishBehavior', namespaces=NS) == 'PublishAfterCommit'
assert set(types['CustomField']) == {'Vehicle_Reserved__e.Vehicle_Id__c', 'Vehicle_Reserved__e.Reserved_At__c'}
permissions = ET.parse(SOURCE / 'permissionsets/PS_Inventory_Gallery.permissionset-meta.xml').getroot()
for permission in permissions.findall('m:objectPermissions', NS):
    assert permission.findtext('m:allowEdit', namespaces=NS) == 'false'
    if permission.findtext('m:object', namespaces=NS) != 'Vehicle_Reserved__e':
        assert permission.findtext('m:allowCreate', namespaces=NS) == 'false'
assert 'Invoice_Cost__c' not in ET.tostring(permissions, encoding='unicode')
mapping = json.loads((ROOT / 'docs/assets/P7_VEHICLE_IMAGE_MAP.json').read_text())
expected = {f'{make}_{trim}.webp' for make, trim in itertools.product(
    ['aurelia', 'cascadia', 'halcyon', 'kestrel', 'meridian', 'vantage'], ['ex', 'limited', 'lx', 'premium', 'sport'])}
assert len(mapping['assets']) == 30 and {a['file'] for a in mapping['assets']} == expected
assert mapping['recordChanges'] is False and mapping['pathPrefix'] == '/resource/NG_VehicleImages/'
available = sum((SOURCE / 'staticresources/NG_VehicleImages' / name).is_file() for name in expected)
print(json.dumps({'status': 'PASS', 'scope': 'package and path contract only', 'metadataMembers': 21,
                  'expectedPhotoFiles': 30, 'availablePhotoFiles': available,
                  'photoAcceptance': 'BLOCKED' if available != 30 else 'REQUIRES_ASSET_AND_VISUAL_VALIDATION',
                  'eventPublishBehavior': 'PublishAfterCommit', 'credentialMetadata': 0,
                  'vehicleEditGranted': False}, indent=2))
