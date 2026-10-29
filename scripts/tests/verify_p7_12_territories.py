"""Read-only P7-12 capability/settings and mapping inventory; no deployment or record mutation."""
import json
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

from audit_p7_batch2 import query, sf

ROOT = Path(__file__).resolve().parents[2]


def main():
    org = query('SELECT Id, OrganizationType, IsSandbox FROM Organization')
    assert org[0]['Id'] == '00Daj00001Ae3iWEAR'
    exposed = set(sf('sobject', 'list', '--sobject', 'all'))
    required = {'Territory2', 'Territory2Model', 'Territory2Type', 'ObjectTerritory2Association'}
    access = {}
    soql = {
        'Territory2Model': 'SELECT Id, DeveloperName, State FROM Territory2Model',
        'Territory2Type': 'SELECT Id, DeveloperName, Priority FROM Territory2Type',
        'Territory2': 'SELECT Id, DeveloperName, ParentTerritory2Id, Territory2ModelId, Territory2TypeId FROM Territory2',
        'ObjectTerritory2Association': 'SELECT COUNT(Id) total FROM ObjectTerritory2Association',
    }
    for name in sorted(required):
        access[name] = {'exposed': name in exposed, 'querySucceeded': False}
        if name in exposed:
            access[name]['records'] = query(soql[name])
            access[name]['querySucceeded'] = True
    user_links = query('SELECT COUNT(Id) total FROM UserTerritory2Association') if 'UserTerritory2Association' in exposed else None
    rooftops = query('SELECT Id, Name FROM Rooftop__c ORDER BY Name')
    account_mapping = query('SELECT Preferred_Rooftop__c, COUNT(Id) total FROM Account GROUP BY Preferred_Rooftop__c')

    # Retrieve to evidence only; never overwrite force-app or issue a deploy/configuration call.
    directory = ROOT / 'evidence/P7/P7_12_TERRITORY_SETTINGS_READBACK'
    retrieved = sf('project', 'retrieve', 'start', '--metadata', 'Settings:Territory2',
                   '--target-metadata-dir', str(directory.relative_to(ROOT)), '--unzip', '--wait', '10')
    paths = list(directory.rglob('Territory2.settings'))
    assert len(paths) == 1, 'Expected exactly one retrieved Territory2 settings file'
    settings = {child.tag.split('}')[-1]: child.text for child in ET.parse(paths[0]).getroot()}
    output = {
        'observedAtUtc': datetime.now(timezone.utc).isoformat(), 'organization': org,
        'settingsRetrieve': {'id': retrieved.get('id'), 'status': retrieved.get('status'),
                             'file': str(paths[0].relative_to(ROOT))},
        'territorySettings': settings, 'requiredObjectAccess': access,
        'userTerritoryAssociationCount': user_links, 'rooftops': rooftops,
        'accountPreferredRooftopCounts': account_mapping,
        'salesTerritoryEnabled': settings.get('enableTerritoryManagement2') == 'true',
        'allFourRequiredObjectsQueryable': all(row['querySucceeded'] for row in access.values()),
        'writesPerformed': {'metadataDeployments': 0, 'configurationChanges': 0,
                            'recordMutations': 0, 'accountAssignments': 0, 'userAssignments': 0},
        'limits': ['Authenticated administrative API context only; no operational persona/browser proof.',
                   'Settings and object access do not establish a configured/active model or P7-12 acceptance.',
                   'Account Preferred_Rooftop grouping is a mapping candidate, not approved territory assignments.',
                   'Batch 2 passing tests are reused, not rerun.'],
    }
    (ROOT / 'evidence/P7/P7_12_TERRITORY_REVERIFICATION.json').write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps(output, indent=2))


if __name__ == '__main__':
    main()
