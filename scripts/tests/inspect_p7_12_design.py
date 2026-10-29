"""Read-only native territory schema, role and responsibility evidence; excludes personal names."""
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from audit_p7_batch2 import query, sf

ROOT = Path(__file__).resolve().parents[2]


def main():
    org = query('SELECT Id FROM Organization')
    assert org[0]['Id'] == '00Daj00001Ae3iWEAR'
    users = query('SELECT Id, IsActive, UserType, ProfileId, Profile.Name, Profile.UserLicense.Name, '
                  'UserRoleId, UserRole.DeveloperName FROM User WHERE IsActive = true')
    roles = query('SELECT Id, DeveloperName, ParentRoleId FROM UserRole')
    staff = query('SELECT Id, Rooftop__c, Role__c, User__c, Is_Persona_Login__c, Is_Active__c FROM Staff__c')
    rooftops = query('SELECT Id, Name, General_Manager__c FROM Rooftop__c ORDER BY Name')
    assignments = query('SELECT AssigneeId, PermissionSetId, PermissionSet.Name, PermissionSetGroupId, '
                        'PermissionSetGroup.DeveloperName FROM PermissionSetAssignment')
    descriptions = {}
    selected_fields = {'AccountAccessLevel', 'ContactAccessLevel', 'OpportunityAccessLevel',
                       'CaseAccessLevel', 'AssociationCause', 'ObjectId', 'Territory2Id',
                       'UserId', 'RoleInTerritory2', 'Preferred_Rooftop__c', 'State'}
    for name in ['Territory2', 'Territory2Model', 'ObjectTerritory2Association', 'UserTerritory2Association', 'Account']:
        described = sf('sobject', 'describe', '--sobject', name)
        descriptions[name] = {key: described.get(key) for key in ['name', 'createable', 'updateable', 'deletable', 'queryable']}
        descriptions[name]['fields'] = [
            {key: field.get(key) for key in ['name', 'type', 'createable', 'updateable', 'nillable', 'referenceTo', 'picklistValues']}
            for field in described['fields'] if field['name'] in selected_fields]
    sharing = sf('data', 'query', '--use-tooling-api', '--query',
                 "SELECT QualifiedApiName, InternalSharingModel, ExternalSharingModel FROM EntityDefinition "
                 "WHERE QualifiedApiName IN ('Account','Contact','Opportunity','Case')")
    assert sharing['done']
    sources = {}
    url = 'https://raw.githubusercontent.com/jsforce/jsforce/main/src/api/metadata/schema.ts'
    schema = subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location', '--max-time', '60', url],
                            text=True, capture_output=True, check=True).stdout
    definitions = {}
    for name in ['Territory2', 'Territory2Model', 'Territory2Type', 'Territory2Rule', 'Territory2Settings',
                 'Territory2AccountAccessLevel', 'Territory2ContactAccessLevel', 'Territory2OpportunityAccessLevel',
                 'Territory2CaseAccessLevel']:
        match = re.search(r'^  ' + name + r': \{.*?^  \},', schema, re.MULTILINE | re.DOTALL)
        if match:
            definitions[name] = match.group(0)
    sources['jsforceWsdlSchema'] = {'url': url, 'sha256': hashlib.sha256(schema.encode()).hexdigest(),
                                   'definitions': definitions, 'authority': 'WSDL-derived client schema; not live deployment acceptance'}
    registry_url = 'https://raw.githubusercontent.com/forcedotcom/source-deploy-retrieve/main/src/registry/metadataRegistry.json'
    registry_bytes = subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location', '--max-time', '60', registry_url],
                                    capture_output=True, check=True).stdout
    registry = json.loads(registry_bytes)
    sources['salesforceSourceRegistry'] = {'url': registry_url, 'sha256': hashlib.sha256(registry_bytes).hexdigest(),
        'types': {key: registry['types'][key] for key in ['territory2', 'territory2model', 'territory2type', 'territory2rule']}}
    output = {'observedAtUtc': datetime.now(timezone.utc).isoformat(), 'organization': org,
              'activeUsers': users, 'roles': roles, 'staffResponsibilities': staff, 'rooftops': rooftops,
              'permissionAssignments': assignments, 'nativeDescribe': descriptions,
              'liveSharingModels': sharing['records'], 'metadataReferences': sources,
              'mutationsPerformed': 0,
              'limits': ['No personal display names, usernames or email addresses collected.',
                         'Read/describe capability is not an executed assignment or actual-persona access check.',
                         'No native lookup assignment-rule eligibility is inferred from SOQL filterability.']}
    (ROOT / 'evidence/P7/P7_12_DESIGN_INSPECTION.json').write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps({key: value for key, value in output.items() if key != 'permissionAssignments'}, indent=2))


if __name__ == '__main__':
    main()
