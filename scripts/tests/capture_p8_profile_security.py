"""Read-only, profile-scoped ng-demo evidence; no deployment or corrective writes."""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(sys.argv[1])
OUT.mkdir(parents=True, exist_ok=True)
PLAN = json.loads((ROOT / 'evidence/P8/BLOCKER_REMEDIATION/profile_deny_plan.json').read_text())


def query(name, soql):
    result = subprocess.run(['sf', 'data', 'query', '--target-org', 'ng-demo', '--query', soql, '--json'], capture_output=True, text=True)
    (OUT / (name + '.json')).write_text(result.stdout)
    assert result.returncode == 0, result.stdout
    return json.loads(result.stdout)['result']['records']


assert query('identity', 'SELECT Id FROM Organization')[0]['Id'] == '00Daj00001Ae3iWEAR'
profile = query('profile', "SELECT Id, Name, UserType, UserLicense.Name FROM Profile WHERE Name = 'NG_Owner_Portal_User'")[0]
sets = query('profile_set', "SELECT Id, Name, ProfileId FROM PermissionSet WHERE ProfileId = '" + profile['Id'] + "'")
assert len(sets) == 1
pid = sets[0]['Id']
fields = sorted({'Permissions' + name for name in PLAN['explicitlyDeniedSystemPermissions']} | {
    'PermissionsEnableNotifications', 'PermissionsEmailAdministration', 'PermissionsEmailTemplateManagement',
    'PermissionsApiEnabled', 'PermissionsViewAllData', 'PermissionsModifyAllData', 'PermissionsAuthorApex',
    'PermissionsManageUsers', 'PermissionsManageSharing', 'PermissionsViewSetup', 'PermissionsRunReports', 'PermissionsDataExport'})
query('system_permissions', 'SELECT Id,' + ','.join(fields) + " FROM PermissionSet WHERE Id = '" + pid + "'")
query('object_permissions', "SELECT SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM ObjectPermissions WHERE ParentId = '" + pid + "' ORDER BY SobjectType")
query('field_permissions', "SELECT SobjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE ParentId = '" + pid + "' ORDER BY Field")
query('setup_access', "SELECT SetupEntityId, SetupEntityType FROM SetupEntityAccess WHERE ParentId = '" + pid + "' ORDER BY SetupEntityId")
query('profile_users', "SELECT Id FROM User WHERE ProfileId = '" + profile['Id'] + "'")
query('assignments', 'SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment ORDER BY Id')
query('network', "SELECT Id, Status, FirstActivationDate FROM Network WHERE Id = '0DBaj000006bf3xGAA'")
query('network_groups', "SELECT Id, ParentId FROM NetworkMemberGroup WHERE NetworkId = '0DBaj000006bf3xGAA' ORDER BY Id")
query('network_members', "SELECT Id, MemberId FROM NetworkMember WHERE NetworkId = '0DBaj000006bf3xGAA' ORDER BY Id")
query('batch_b_classes', "SELECT Id, Name FROM ApexClass WHERE Name IN ('OwnerPortalBatchBController','OwnerPortalBatchBControllerTest')")
query('batch_b_permission_set', "SELECT Id FROM PermissionSet WHERE Name = 'PS_Owner_Portal_Batch_B'")
print(json.dumps({'status': 'CONFIRMED', 'profileId': profile['Id'], 'profileOwnedPermissionSetId': pid, 'snapshot': str(OUT)}, indent=2))
