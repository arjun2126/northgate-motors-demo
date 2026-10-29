"""Read-only ng-demo permission inventory and native territory capability report."""
import json
import subprocess
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def sf(*args):
    process = subprocess.run(['sf', *args, '--target-org', 'ng-demo', '--json'],
                             text=True, capture_output=True)
    if process.returncode:
        raise RuntimeError(process.stdout or process.stderr)
    payload = json.loads(process.stdout)
    assert payload['status'] == 0, payload
    return payload['result']


def query(soql):
    result = sf('data', 'query', '--query', soql)
    assert result['done'], 'Incomplete query; do not label partial evidence complete'
    return [{key: value for key, value in row.items() if key != 'attributes'}
            for row in result['records']]


def main():
    org = query('SELECT Id, OrganizationType, IsSandbox FROM Organization')
    assert org[0]['Id'] == '00Daj00001Ae3iWEAR'
    permissions = query("SELECT Id, Name FROM PermissionSet WHERE IsOwnedByProfile = false ORDER BY Name")
    assignments = query('SELECT PermissionSetId, PermissionSetGroupId, AssigneeId, Assignee.IsActive, '
                        'Assignee.Profile.Name, Assignee.UserRole.DeveloperName FROM PermissionSetAssignment')
    groups = query('SELECT Id, DeveloperName, Status FROM PermissionSetGroup')
    components = query('SELECT PermissionSetGroupId, PermissionSetId FROM PermissionSetGroupComponent')
    objects = set(sf('sobject', 'list', '--sobject', 'all'))
    required = {'Territory2', 'Territory2Model', 'Territory2Type', 'ObjectTerritory2Association'}
    available = sorted(required & objects)
    territory = {'requiredObjects': sorted(required), 'exposedObjects': available,
                 'missingObjects': sorted(required - objects), 'configurationChanges': 0,
                 'accountAssignments': 0, 'renderedTreeAcceptance': 'NOT VERIFIED'}
    if required <= objects:
        territory['models'] = query('SELECT Id, DeveloperName, State FROM Territory2Model')
        territory['types'] = query('SELECT Id, DeveloperName, Priority FROM Territory2Type')
        territory['territories'] = query('SELECT Id, DeveloperName, Territory2ModelId FROM Territory2')
        territory['disposition'] = 'Native objects exposed; activation/sharing/Account assignment require separate approval.'
    else:
        territory['disposition'] = 'BLOCKED: required native territory objects are not exposed; owner capability disposition required.'
    counts = Counter(row['PermissionSetId'] for row in assignments)
    grouped = {row['PermissionSetId'] for row in components}
    candidates = [{'name': row['Name'], 'directOrGeneratedAssignments': counts[row['Id']],
                   'includedInPermissionSetGroup': row['Id'] in grouped}
                  for row in permissions if row['Name'].startswith('PS_') and not counts[row['Id']]]
    output = {'organization': org, 'permissionSets': permissions, 'assignments': assignments,
              'permissionSetGroups': groups, 'groupComponents': components,
              'unassignedProjectSetCandidates': candidates,
              'limits': ['Assignment snapshot is not permission usage telemetry.',
                         'Group members may be used through a group without direct assignments.',
                         'No permission is proven unused; no grants or revocations performed.',
                         'Administrative CLI report only; operational-reader/native report UI not verified.'],
              'territoryCapability': territory}
    path = ROOT / 'evidence/P7/BATCH2_PERMISSION_TERRITORY_AUDIT.json'
    path.write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps({'organization': org, 'permissionSetCount': len(permissions),
                      'assignmentCount': len(assignments), 'groupCount': len(groups),
                      'unassignedProjectSetCandidates': candidates,
                      'territoryCapability': territory}, indent=2))


if __name__ == '__main__':
    main()
