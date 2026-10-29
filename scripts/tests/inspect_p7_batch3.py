"""Feature-specific Batch 3 capability inventory; read-only ng-demo access, no inference of activation."""
import json
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

from audit_p7_batch2 import query, sf

ROOT = Path(__file__).resolve().parents[2]


def main():
    org = query('SELECT Id, OrganizationType FROM Organization')
    assert org[0]['Id'] == '00Daj00001Ae3iWEAR'
    objects = set(sf('sobject', 'list', '--sobject', 'all'))
    metadata = sf('org', 'list', 'metadata-types')
    types = {row['xmlName'] for row in metadata['metadataObjects']}
    names = {}
    for kind in ['Bot', 'GenAiPlannerBundle', 'GenAiPromptTemplate', 'Network', 'CustomSite']:
        if kind in types:
            rows = sf('org', 'list', 'metadata', '--metadata-type', kind)
            names[kind] = sorted(row['fullName'] for row in rows)
        else:
            names[kind] = None
    settings = sf('org', 'list', 'metadata', '--metadata-type', 'Settings')
    setting_names = sorted(row['fullName'] for row in settings)
    selected_settings = ['Communities', 'EinsteinGpt', 'EinsteinCopilot', 'CustomerDataPlatform', 'Bot', 'AgentPlatform']
    selected_settings = [name for name in selected_settings if name in setting_names]
    directory = ROOT / 'evidence/P7/BATCH3_SETTINGS_READBACK'
    retrieved = sf('project', 'retrieve', 'start', '--metadata',
                   *['Settings:' + name for name in selected_settings],
                   '--target-metadata-dir', str(directory.relative_to(ROOT)), '--unzip', '--wait', '10')
    flags = {}
    for path in directory.rglob('*.settings'):
        flags[path.stem] = {child.tag.split('}')[-1]: child.text for child in ET.parse(path).getroot()
                            if child.text in ['true', 'false']}
    counts = {}
    for name in ['Network', 'Site', 'DataSpace', 'DataStream', 'Bot']:
        if name in objects:
            described = sf('sobject', 'describe', '--sobject', name)
            counts[name] = {'queryable': described['queryable']}
            if described['queryable']:
                counts[name]['count'] = query('SELECT COUNT(Id) total FROM ' + name)
    licenses = query("SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense WHERE Name IN "
                     "('Salesforce','External Identity','Customer Community','Customer Community Plus','Partner Community')")
    articles = query('SELECT PublishStatus, COUNT(Id) total FROM Knowledge__kav GROUP BY PublishStatus') if 'Knowledge__kav' in objects else None
    output = {'observedAtUtc': datetime.now(timezone.utc).isoformat(), 'organization': org,
              'exposedCapabilityObjects': sorted(name for name in objects if name.startswith(
                  ('Bot', 'GenAi', 'AiAgent', 'DataSpace', 'DataStream', 'Network', 'Site'))),
              'nativeMetadataNames': names, 'availableSettingsNames': setting_names,
              'supportedAgentMetadataTypes': sorted(name for name in types if any(word in name for word in ['Bot', 'GenAi', 'AiAgent'])),
              'settingsRetrieve': {'id': retrieved.get('id'), 'status': retrieved.get('status')},
              'settingsBooleanReadback': flags,
              'nativeObjectCounts': counts, 'licenses': licenses, 'knowledgeByPublishStatus': articles,
              'writesPerformed': 0, 'promptsExecuted': 0, 'ingestionsStarted': 0,
              'limits': ['Metadata/object exposure is not activation, quota/credit or runtime availability proof.',
                         'License counts do not establish external object CRUD/FLS or relationship sharing.',
                         'No permission assignment, publication, external data export, site or model activation.']}
    (ROOT / 'evidence/P7/BATCH3_CAPABILITY_INSPECTION.json').write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps(output, indent=2))


if __name__ == '__main__':
    main()
