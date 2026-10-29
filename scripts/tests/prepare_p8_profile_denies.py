"""Generate a local explicit-deny profile from captured live grants/describes. No org calls."""
import json
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'evidence/P8/BLOCKER_REMEDIATION'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}


def main():
    objects = json.loads((EVIDENCE / 'profile_objects.json').read_text())['result']['records']
    fields = json.loads((EVIDENCE / 'profile_fields.json').read_text())['result']['records']
    retrieved = ET.parse(EVIDENCE / 'retrieved/profiles/NG_Owner_Portal_User.profile-meta.xml').getroot()
    # These two backend names are valid explicit profile metadata even though retrieval omits
    # their enabled defaults: one-component probe 0Afaj00000pIZtCCAW accepted both false entries.
    permissions = sorted({n.find('m:name', NS).text for n in retrieved.findall('m:userPermissions', NS)} |
                         {'EmailAdministration', 'EmailTemplateManagement'})
    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<Profile xmlns="http://soap.sforce.com/2006/04/metadata">',
             '    <custom>true</custom>',
             '    <description>Local explicit-deny correction; not deployed. Plus login, own Account/Contact Read, and license-required Send Outbound Messages only. Portal feature grants require separate reviewed permission sets. No base-profile Case or Apex grants.</description>']
    denied_fields = []
    skipped_fields = []
    names = {r['Field'] for r in fields} | {'Contact.AccountId'}
    for name in sorted(names):
        if '.' not in name:
            skipped_fields.append({'field': name, 'reason': 'No object-qualified API name returned by FieldPermissions'})
            continue
        obj, field = name.split('.', 1)
        path = EVIDENCE / (obj + '_describe.json')
        if not path.exists():
            skipped_fields.append({'field': name, 'reason': 'No successful describe'})
            continue
        definition = next((f for f in json.loads(path.read_text())['result']['fields'] if f['name'] == field), None)
        if not definition or not definition.get('permissionable'):
            skipped_fields.append({'field': name, 'reason': 'Not a permissionable field in captured describe'})
            continue
        readable = 'true' if name == 'Contact.AccountId' else 'false'
        lines.extend(['    <fieldPermissions>', '        <editable>false</editable>',
                      '        <field>' + name + '</field>', '        <readable>' + readable + '</readable>',
                      '    </fieldPermissions>'])
        if readable == 'false':
            denied_fields.append(name)
    for name in sorted({r['SobjectType'] for r in objects} | {'Account', 'Contact'}):
        read = 'true' if name in {'Account', 'Contact'} else 'false'
        lines.extend(['    <objectPermissions>', '        <allowCreate>false</allowCreate>',
                      '        <allowDelete>false</allowDelete>', '        <allowEdit>false</allowEdit>',
                      '        <allowRead>' + read + '</allowRead>', '        <modifyAllRecords>false</modifyAllRecords>',
                      '        <object>' + name + '</object>', '        <viewAllRecords>false</viewAllRecords>',
                      '    </objectPermissions>'])
    lines.append('    <userLicense>Customer Community Plus</userLicense>')
    for name in permissions:
        # Salesforce rejected disabling EnableNotifications (label: Send Outbound Messages)
        # as mandatory for this license, validation 0Afaj00000pJD93CAG.
        enabled = 'true' if name == 'EnableNotifications' else 'false'
        lines.extend(['    <userPermissions>', '        <enabled>' + enabled + '</enabled>', '        <name>' + name + '</name>', '    </userPermissions>'])
    lines.append('</Profile>')
    (ROOT / 'force-app/main/default/profiles/NG_Owner_Portal_User.profile-meta.xml').write_text('\n'.join(lines) + '\n')
    plan = {'explicitlyDeniedObjects': sorted(r['SobjectType'] for r in objects if r['SobjectType'] not in {'Account', 'Contact'}),
            'explicitlyDeniedFields': denied_fields, 'skippedFields': skipped_fields,
            'explicitlyDeniedSystemPermissions': [p for p in permissions if p != 'EnableNotifications'],
            'licenseRequiredSystemPermissions': ['EnableNotifications'], 'retainedRead': ['Account', 'Contact', 'Contact.AccountId'],
            'deployed': False}
    (EVIDENCE / 'profile_deny_plan.json').write_text(json.dumps(plan, indent=2) + '\n')
    print(json.dumps({'deniedObjects': len(plan['explicitlyDeniedObjects']), 'deniedFields': len(denied_fields),
                      'deniedSystemPermissions': len(plan['explicitlyDeniedSystemPermissions']),
                      'licenseRequiredSystemPermissions': plan['licenseRequiredSystemPermissions'],
                      'skippedFields': len(skipped_fields), 'deployed': False}, indent=2))


if __name__ == '__main__':
    main()
