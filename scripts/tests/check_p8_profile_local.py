"""Local-only checks for the prepared P8-02 portal profile; no Salesforce calls or writes."""
import json
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROFILE = ROOT / 'force-app/main/default/profiles/NG_Owner_Portal_User.profile-meta.xml'
MANIFEST = ROOT / 'manifest/p8-02-profile-preparation.xml'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}


def main():
    assert PROFILE.exists(), PROFILE
    root = ET.parse(PROFILE).getroot()
    assert root.find('m:custom', NS).text == 'true'
    assert root.find('m:userLicense', NS).text == 'Customer Community Plus'

    objects = {}
    for node in root.findall('m:objectPermissions', NS):
        name = node.find('m:object', NS).text
        assert name not in objects, name
        objects[name] = {flag: node.find('m:' + flag, NS).text for flag in
                         ['allowRead', 'allowCreate', 'allowEdit', 'allowDelete',
                          'viewAllRecords', 'modifyAllRecords']}
    assert {'Account', 'Contact', 'Case'} <= set(objects), objects
    for name, flags in objects.items():
        assert flags['allowRead'] == ('true' if name in {'Account', 'Contact'} else 'false'), name
        for flag in ['allowCreate', 'allowEdit', 'allowDelete', 'viewAllRecords', 'modifyAllRecords']:
            assert flags[flag] == 'false', (name, flag)

    fields = {node.find('m:field', NS).text: (node.find('m:readable', NS).text, node.find('m:editable', NS).text)
              for node in root.findall('m:fieldPermissions', NS)}
    assert fields['Contact.AccountId'] == ('true', 'false')
    assert all(flags == (('true', 'false') if name == 'Contact.AccountId' else ('false', 'false'))
               for name, flags in fields.items())

    permissions = {node.find('m:name', NS).text: node.find('m:enabled', NS).text
                   for node in root.findall('m:userPermissions', NS)}
    assert {name for name, enabled in permissions.items() if enabled == 'true'} == {'EnableNotifications'}
    assert permissions['ApexRestServices'] == permissions['RunFlow'] == permissions['FieldServiceAccess'] == 'false'
    assert permissions['EmailAdministration'] == permissions['EmailTemplateManagement'] == 'false'
    assert root.findall('m:classAccesses', NS) == [], 'Apex access belongs to the permission set'
    assert root.findall('m:customPermissions', NS) == [], 'portal gate belongs to the permission set'

    manifest = ET.parse(MANIFEST).getroot()
    types = {node.find('m:name', NS).text: {m.text for m in node.findall('m:members', NS)}
             for node in manifest.findall('m:types', NS)}
    assert types == {'Profile': {'NG_Owner_Portal_User'}}, types

    output = {
        'status': 'PASS',
        'profile': 'NG_Owner_Portal_User',
        'baseLicense': 'Customer Community Plus',
        'objectPermissions': {name: flags for name, flags in objects.items()},
        'fieldPermissions': {name: {'readable': value[0], 'editable': value[1]} for name, value in fields.items()},
        'systemPermissionsGranted': 1,
        'licenseRequiredSystemPermission': 'EnableNotifications (Send Outbound Messages)',
        'apexAccessInProfile': 0,
        'customPermissionInProfile': 0,
        'caseAccess': 'EXPLICITLY DENIED',
        'deploymentManifest': 'manifest/p8-02-profile-preparation.xml',
        'correctionDeployed': False,
        'orgWritesPerformed': 0,
    }
    (ROOT / 'evidence/P8/PROFILE_PREP/LOCAL_PROFILE_CHECK.json').write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps(output, indent=2))


if __name__ == '__main__':
    main()
