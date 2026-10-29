"""Bounded read-only ng-demo operational preparation; never provisions or repairs."""
import concurrent.futures
import json
import subprocess
import sys
from pathlib import Path

OUT = Path(sys.argv[1])
OUT.mkdir(parents=True, exist_ok=True)


def sf(name, args):
    result = subprocess.run(['sf', *args, '--target-org', 'ng-demo', '--json'], capture_output=True, text=True)
    (OUT / (name + '.json')).write_text(result.stdout)
    (OUT / (name + '.stderr.txt')).write_text(result.stderr)
    assert result.returncode == 0, result.stdout
    return json.loads(result.stdout)['result']


def query(name, soql, tooling=False):
    return sf(name, ['data', 'query', '--query', soql, *(['--use-tooling-api'] if tooling else [])])


assert query('identity', 'SELECT Id FROM Organization')['records'][0]['Id'] == '00Daj00001Ae3iWEAR'
objects = ['Vehicle__c', 'Contact', 'Delivery__c', 'Service_Visit__c', 'Rooftop__c',
           'Vehicle_Model__c', 'Case', 'CaseComment', 'Loyalty_Member__c', 'Loyalty_Transaction__c']
describes = {}
for obj in objects:
    describes[obj] = sf('describe_' + obj, ['sobject', 'describe', '--sobject', obj])

sets = query('security_sets', "SELECT Id, Name, ProfileId, Profile.Name, IsOwnedByProfile FROM PermissionSet "
             "WHERE ProfileId IN ('00eaj00000UB3CcAAL','00eaj00000UBi7iAAD') "
             "OR Name IN ('PS_Owner_Portal_Foundation','PS_Owner_Portal_Batch_B') ORDER BY Id")['records']
assert len(sets) == 4
ids = ','.join("'" + row['Id'] + "'" for row in sets)
permissions = sf('describe_PermissionSet', ['sobject', 'describe', '--sobject', 'PermissionSet'])
flags = sorted(f['name'] for f in permissions['fields'] if f['name'].startswith('Permissions'))
queries = {
    'network': "SELECT Id, Name, UrlPathPrefix, Status, FirstActivationDate, SelfRegProfileId, OptionsSelfRegistrationEnabled, OptionsAllowInternalUserLogin, OptionsGuestMemberVisibility, OptionsInvitationsEnabled FROM Network WHERE Id = '0DBaj000006bf3xGAA'",
    'licenses': "SELECT Id, Name, TotalLicenses, UsedLicenses FROM UserLicense WHERE Name IN ('Customer Community Plus','Guest User License')",
    'identities': "SELECT Id, ContactId, ProfileId, UserRoleId, UserType, IsActive FROM User WHERE ContactId != null OR Id IN ('005aj00000gnLcbAAE','005aj00000gE0b3AAC') ORDER BY Id",
    'technical_owner': "SELECT Id, IsActive, UserRoleId, UserRole.Name, UserRole.PortalType, Profile.UserLicense.Name FROM User WHERE Id = '005aj00000gE0b3AAC'",
    'accounts': "SELECT Id, OwnerId FROM Account WHERE Id IN ('001aj000049ZoXNAA0','001aj000049ZoXOAA0') ORDER BY Id",
    'contacts': "SELECT Id, AccountId FROM Contact WHERE Id IN ('003aj00002Xl4IfAAJ','003aj00002Xl4IgAAJ') ORDER BY Id",
    'memberships': "SELECT Id, NetworkId, ParentId FROM NetworkMemberGroup WHERE NetworkId = '0DBaj000006bf3xGAA' ORDER BY Id",
    'members': "SELECT Id, NetworkId, MemberId FROM NetworkMember WHERE NetworkId = '0DBaj000006bf3xGAA' ORDER BY Id",
    'assignments': 'SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE PermissionSetId IN (' + ids + ') ORDER BY Id',
    'object_permissions': 'SELECT ParentId, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM ObjectPermissions WHERE ParentId IN (' + ids + ') ORDER BY ParentId, SobjectType',
    'field_permissions': 'SELECT ParentId, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE ParentId IN (' + ids + ') ORDER BY ParentId, Field',
    'setup_access': 'SELECT ParentId, SetupEntityId, SetupEntityType FROM SetupEntityAccess WHERE ParentId IN (' + ids + ') ORDER BY ParentId, SetupEntityType, SetupEntityId',
    'custom_permission': "SELECT Id, DeveloperName FROM CustomPermission WHERE DeveloperName = 'Access_Northgate_Owner_Portal'",
    'external_owd': "SELECT QualifiedApiName, InternalSharingModel, ExternalSharingModel FROM EntityDefinition WHERE QualifiedApiName IN ('Account','Contact','Case','Vehicle__c','Vehicle_Model__c','Rooftop__c','Delivery__c','Service_Visit__c','Loyalty_Member__c','Loyalty_Transaction__c') ORDER BY QualifiedApiName",
    'delivery_evidence': 'SELECT Id, Buyer__c, Vehicle__c, Status__c, Completed_Date__c FROM Delivery__c ORDER BY Id',
    'fixture_visits': "SELECT Id, Contact__c, Vehicle__c, Case__c, Status__c FROM Service_Visit__c WHERE Contact__c IN ('003aj00002Xl4IfAAJ','003aj00002Xl4IgAAJ') ORDER BY Id",
    'fixture_cases': "SELECT Id, ContactId, AccountId, OwnerId FROM Case WHERE ContactId IN ('003aj00002Xl4IfAAJ','003aj00002Xl4IgAAJ') ORDER BY Id",
    'fixture_loyalty': "SELECT Id, Contact__c FROM Loyalty_Member__c WHERE Contact__c IN ('003aj00002Xl4IfAAJ','003aj00002Xl4IgAAJ') ORDER BY Id",
    'fixture_account_shares': "SELECT Id, AccountId, UserOrGroupId, AccountAccessLevel, ContactAccessLevel, CaseAccessLevel, OpportunityAccessLevel, RowCause FROM AccountShare WHERE AccountId IN ('001aj000049ZoXNAA0','001aj000049ZoXOAA0') ORDER BY Id",
}
for offset in range(0, len(flags), 50):
    queries['system_permissions_' + str(offset)] = 'SELECT Id,' + ','.join(flags[offset:offset + 50]) + ' FROM PermissionSet WHERE Id IN (' + ids + ') ORDER BY Id'


def capture(item):
    name, soql = item
    return name, query(name, soql)['totalSize']


with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    counts = dict(pool.map(capture, queries.items()))
query('lwc', "SELECT Id, DeveloperName, ApiVersion FROM LightningComponentBundle WHERE DeveloperName IN ('ownerPortalHome','ownerPortalVehicles','ownerPortalHistory','ownerPortalAppointment','ownerPortalCases','ownerPortalLoyalty') ORDER BY DeveloperName", tooling=True)
query('apex', "SELECT Id, Name, ApiVersion, Status, Body FROM ApexClass WHERE Name IN ('OwnerPortalFoundationController','OwnerPortalBatchBController') ORDER BY Name", tooling=True)
summary = {'claim': 'CONFIRMED', 'orgId': '00Daj00001Ae3iWEAR', 'readOnly': True, 'rows': counts}
(OUT / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
print(json.dumps(summary, indent=2))
