"""Read-only ng-demo snapshot for the explicitly approved five-component deployment."""
import concurrent.futures
import json
import subprocess
import sys
from pathlib import Path

OUT = Path(sys.argv[1])
OUT.mkdir(parents=True, exist_ok=True)


def sf(args):
    result = subprocess.run(['sf', *args, '--target-org', 'ng-demo', '--json'], capture_output=True, text=True)
    data = json.loads(result.stdout)
    if result.returncode or data.get('status') != 0:
        raise RuntimeError(result.stdout)
    return data['result']


def query(item):
    name, soql = item
    result = sf(['data', 'query', '--query', soql])
    (OUT / (name + '.json')).write_text(json.dumps(result, indent=2) + '\n')
    return name, result['totalSize']


identity = sf(['data', 'query', '--query', 'SELECT Id FROM Organization'])
assert identity['records'][0]['Id'] == '00Daj00001Ae3iWEAR'
desc = sf(['sobject', 'describe', '--sobject', 'PermissionSet'])
perms = [f['name'] for f in desc['fields'] if f['name'].startswith('Permissions')]
queries = {
    'users': 'SELECT Id, ProfileId, UserRoleId, ContactId, IsActive, UserType FROM User ORDER BY Id',
    'assignments': 'SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment ORDER BY Id',
    'networks': 'SELECT Id, Name, UrlPathPrefix, Status, FirstActivationDate, SelfRegProfileId, OptionsSelfRegistrationEnabled FROM Network ORDER BY Id',
    'network_groups': 'SELECT Id, NetworkId, ParentId FROM NetworkMemberGroup ORDER BY Id',
    'network_members': 'SELECT Id, NetworkId, MemberId FROM NetworkMember ORDER BY Id',
    'profiles': 'SELECT Id, Name, UserLicenseId FROM Profile ORDER BY Id',
    'permission_sets': 'SELECT Id, Name, ProfileId, IsOwnedByProfile FROM PermissionSet ORDER BY Id',
    'object_permissions': 'SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM ObjectPermissions ORDER BY Id',
    'field_permissions': 'SELECT Id, ParentId, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions ORDER BY Id',
    'setup_access': 'SELECT Id, ParentId, SetupEntityId, SetupEntityType FROM SetupEntityAccess ORDER BY Id',
    'external_owd': "SELECT QualifiedApiName, InternalSharingModel, ExternalSharingModel FROM EntityDefinition WHERE QualifiedApiName IN ('Account','Contact','Case','Vehicle__c','Vehicle_Model__c','Delivery__c','Service_Visit__c','Loyalty_Member__c','Loyalty_Transaction__c') ORDER BY QualifiedApiName",
}
for offset in range(0, len(perms), 25):
    queries['system_permissions_' + str(offset)] = 'SELECT Id,' + ','.join(perms[offset:offset + 25]) + ' FROM PermissionSet ORDER BY Id'
for obj in ['Account', 'Contact', 'Case', 'CaseComment', 'Asset', 'Vehicle__c', 'Delivery__c',
            'Service_Visit__c', 'Loyalty_Member__c', 'Loyalty_Transaction__c', 'Opportunity',
            'Quote', 'QuoteLineItem', 'Financing__c', 'Test_Drive__c', 'Product2', 'PricebookEntry']:
    queries['data_' + obj] = 'SELECT Id, SystemModstamp FROM ' + obj + ' ORDER BY Id'
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    counts = dict(pool.map(query, queries.items()))
print(json.dumps({'orgId': identity['records'][0]['Id'], 'snapshot': str(OUT), 'rows': counts}, indent=2))
