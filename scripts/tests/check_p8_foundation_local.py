"""Local-only package/security-boundary checks; no Salesforce, user creation or Apex execution."""
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'force-app/main/default'
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}


def members(path):
    return {node.find('m:name', NS).text: {child.text for child in node.findall('m:members', NS)}
            for node in ET.parse(path).getroot().findall('m:types', NS)}


def main():
    expected = {
        'ApexClass': {'OwnerPortalFoundationController', 'OwnerPortalFoundationControllerTest'},
        'CustomPermission': {'Access_Northgate_Owner_Portal'},
        'PermissionSet': {'PS_Owner_Portal_Foundation'},
    }
    manifest = ROOT / 'manifest/p8-foundation-preparation.xml'
    assert members(manifest) == expected
    converted = ROOT / 'evidence/P8/LOCAL_FOUNDATION_CONVERSION'
    assert members(converted / 'package.xml') == expected
    controller = SOURCE / 'classes/OwnerPortalFoundationController.cls'
    text = controller.read_text()
    assert text.startswith('public with sharing class')
    assert '@AuraEnabled(cacheable=true)' not in text and 'public static CustomerContext getContext()' in text
    assert 'Network.getNetworkId()' in text and "FeatureManagement.checkPermission('Access_Northgate_Owner_Portal')" in text
    assert "userType == 'PowerCustomerSuccess'" in text and "licenseName == 'Customer Community Plus'" in text
    assert "name == 'Northgate Owner Portal' && path == 'owners' && status == 'Live'" in text
    assert 'WHERE Id = :actor.ContactId WITH USER_MODE LIMIT 1' in text
    assert 'WITH USER_MODE' in text and 'WITH SYSTEM_MODE' in text
    assert not re.search(r'\b(insert|update|delete|upsert|undelete)\s', text)
    assert not any(value in text for value in ['Test.isRunningTest', 'Database.query', 'SELECT FIELDS', 'Case', 'Vehicle__c', 'Financing__c'])
    permission = SOURCE / 'permissionsets/PS_Owner_Portal_Foundation.permissionset-meta.xml'
    root = ET.parse(permission).getroot()
    assert root.find('m:classAccesses/m:apexClass', NS).text == 'OwnerPortalFoundationController'
    assert root.find('m:customPermissions/m:name', NS).text == 'Access_Northgate_Owner_Portal'
    assert {node.find('m:object', NS).text for node in root.findall('m:objectPermissions', NS)} == {'Account', 'Contact'}
    for node in root.findall('m:objectPermissions', NS):
        assert node.find('m:allowRead', NS).text == 'true'
        for flag in ['allowCreate', 'allowDelete', 'allowEdit', 'modifyAllRecords', 'viewAllRecords']:
            assert node.find('m:' + flag, NS).text == 'false'
    assert root.find('m:fieldPermissions/m:field', NS).text == 'Contact.AccountId'
    assert root.find('m:fieldPermissions/m:editable', NS).text == 'false'
    tests = (SOURCE / 'classes/OwnerPortalFoundationControllerTest.cls').read_text()
    assert 'System.runAs(current)' in tests and 'System.runAs(customer)' in tests
    # Owner-approved rolled-back user/data fixtures and foundation permission assignments only.
    assert 'SeeAllData=true' not in tests
    assert not any(value in tests for value in ['new NetworkMember', 'new AccountShare', 'new ContactShare'])
    assert "WHERE Name = 'PS_Owner_Portal_Foundation'" in tests
    assert '@TestVisible private static CustomerContext contextForSite' in text
    assert 'return contextForSite(networkId, sites);' in text
    paths = [controller, Path(str(controller) + '-meta.xml'), SOURCE / 'classes/OwnerPortalFoundationControllerTest.cls',
             SOURCE / 'classes/OwnerPortalFoundationControllerTest.cls-meta.xml', permission,
             SOURCE / 'customPermissions/Access_Northgate_Owner_Portal.customPermission-meta.xml', manifest]
    for path in paths:
        if path.suffix == '.xml':
            ET.parse(path)
        assert all(line == line.rstrip() for line in path.read_text().splitlines()), path.name
    output = {'status': 'PASS', 'localMetadataComponents': 4, 'siteProfileUserSharingComponents': 0,
              'customerDataEndpoint': 'Own Contact/Account IDs only; no caller identity selector or writes',
              'contextCacheable': False, 'permissionSetAssigned': False,
              'sourcePolicyTestsProvided': len(re.findall(r'@isTest static void ', tests)), 'apexTestsExecuted': 0, 'serverCompilation': 'NOT RUN',
              'positiveExternalUserSiteFlsProof': 'NOT VERIFIED', 'orgWritesPerformed': 0,
              'sourceSha256': {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}}
    (ROOT / 'evidence/P8/LOCAL_FOUNDATION_CHECK.json').write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps({key: value for key, value in output.items() if key != 'sourceSha256'}, indent=2))


if __name__ == '__main__':
    main()
