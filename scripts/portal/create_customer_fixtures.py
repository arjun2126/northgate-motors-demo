"""Exact owner-authorized two-customer fixture operation; plan default, insert-only, idempotent."""
import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts/tests'))
from audit_p7_batch2 import query, sf

EVIDENCE = ROOT / 'evidence/P8'
OWNER = '005aj00000gE0b3AAC'
PAIRS = ['A', 'B']
RELATED_OBJECTS = ['Delivery__c', 'Vehicle__c', 'Vehicle_Model__c', 'Rooftop__c', 'Test_Drive__c',
                   'Case', 'Service_Visit__c', 'Loyalty_Member__c', 'Loyalty_Transaction__c',
                   'Opportunity', 'Quote', 'Financing__c', 'Consent__c', 'CampaignMember']


def clean(value):
    if isinstance(value, dict):
        return {key: clean(item) for key, item in value.items() if key not in ['attributes', 'accessToken', 'refreshToken', 'username', 'stack']}
    if isinstance(value, list):
        return [clean(item) for item in value]
    return value


def sha(value):
    return hashlib.sha256(json.dumps(clean(value), sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def save(name, value):
    (EVIDENCE / name).write_text(json.dumps(clean(value), indent=2) + '\n')


def literals(values):
    return ','.join("'" + value + "'" for value in values)


def fixtures():
    accounts = query("SELECT Id, Name, OwnerId, Seed_Tag__c FROM Account WHERE Seed_Tag__c IN ("
                     + literals(['P8-PORTAL-ACCOUNT-' + p for p in PAIRS]) + ') OR Name IN ('
                     + literals(['Northgate Portal Test Customer ' + p for p in PAIRS]) + ')')
    contacts = query("SELECT Id, AccountId, OwnerId, FirstName, LastName, Seed_Tag__c FROM Contact WHERE Seed_Tag__c IN ("
                     + literals(['P8-PORTAL-CONTACT-' + p for p in PAIRS])
                     + ") OR (FirstName = 'Northgate Portal' AND LastName IN ('Test Customer A','Test Customer B'))")
    if not accounts and not contacts:
        return None
    assert len(accounts) == len(contacts) == 2, 'Partial/conflicting fixture state; do not create, update or duplicate'
    by_account = {row['Seed_Tag__c']: row for row in accounts}
    by_contact = {row['Seed_Tag__c']: row for row in contacts}
    result = {}
    for p in PAIRS:
        account = by_account['P8-PORTAL-ACCOUNT-' + p]
        contact = by_contact['P8-PORTAL-CONTACT-' + p]
        assert account['Name'] == 'Northgate Portal Test Customer ' + p and account['OwnerId'] == OWNER
        assert contact['AccountId'] == account['Id'] and contact['OwnerId'] == OWNER
        assert contact['FirstName'] == 'Northgate Portal' and contact['LastName'] == 'Test Customer ' + p
        result[p] = {'account': account, 'contact': contact}
    return result


def snapshot():
    accounts = query('SELECT Id, OwnerId, LastModifiedDate FROM Account ORDER BY Id')
    contacts = query('SELECT Id, AccountId, OwnerId, LastModifiedDate FROM Contact ORDER BY Id')
    related = {}
    for obj in RELATED_OBJECTS:
        rows = query('SELECT Id, LastModifiedDate FROM ' + obj + ' ORDER BY Id')
        related[obj] = {'rows': len(rows), 'sha256': sha(rows)}
    users = query('SELECT Id, IsActive, ProfileId, UserRoleId, ContactId FROM User ORDER BY Id')
    roles = query('SELECT Id, DeveloperName, ParentRoleId, PortalType FROM UserRole ORDER BY Id')
    return {'accounts': accounts, 'contacts': contacts, 'relatedBusiness': related,
            'userStateSha256': sha(users), 'userRows': len(users), 'roleStateSha256': sha(roles)}


def request():
    requests = []
    for p in PAIRS:
        requests.append({'method': 'POST', 'url': '/services/data/v68.0/sobjects/Account', 'referenceId': 'account' + p,
                         'body': {'Name': 'Northgate Portal Test Customer ' + p, 'OwnerId': OWNER,
                                  'Seed_Tag__c': 'P8-PORTAL-ACCOUNT-' + p}})
    for p in PAIRS:
        requests.append({'method': 'POST', 'url': '/services/data/v68.0/sobjects/Contact', 'referenceId': 'contact' + p,
                         'body': {'FirstName': 'Northgate Portal', 'LastName': 'Test Customer ' + p,
                                  'OwnerId': OWNER, 'AccountId': '@{account' + p + '.id}',
                                  'Seed_Tag__c': 'P8-PORTAL-CONTACT-' + p}})
    return {'allOrNone': True, 'compositeRequest': requests}


def isolation(pairs):
    account_ids = literals([pairs[p]['account']['Id'] for p in PAIRS])
    contact_ids = literals([pairs[p]['contact']['Id'] for p in PAIRS])
    scopes = {
        'deliveries': ('Delivery__c', 'Buyer__c IN (' + contact_ids + ')'),
        'reservations': ('Vehicle__c', 'Reserved_By__c IN (' + contact_ids + ')'),
        'testDrives': ('Test_Drive__c', 'Contact__c IN (' + contact_ids + ')'),
        'cases': ('Case', 'AccountId IN (' + account_ids + ') OR ContactId IN (' + contact_ids + ')'),
        'serviceVisits': ('Service_Visit__c', 'Contact__c IN (' + contact_ids + ')'),
        'loyaltyMembers': ('Loyalty_Member__c', 'Contact__c IN (' + contact_ids + ')'),
        'loyaltyTransactions': ('Loyalty_Transaction__c', 'Loyalty_Member__r.Contact__c IN (' + contact_ids + ')'),
        'opportunities': ('Opportunity', 'AccountId IN (' + account_ids + ')'),
        'financeApplications': ('Financing__c', 'Applicant__c IN (' + contact_ids + ') OR Co_Signer__c IN (' + contact_ids + ')'),
        'consent': ('Consent__c', 'Contact__c IN (' + contact_ids + ')'),
        'campaignMembers': ('CampaignMember', 'ContactId IN (' + contact_ids + ')'),
        'externalUsers': ('User', 'ContactId IN (' + contact_ids + ')'),
        'territoryAssociations': ('ObjectTerritory2Association', 'ObjectId IN (' + account_ids + ')'),
    }
    counts = {name: query('SELECT COUNT(Id) total FROM ' + obj + ' WHERE ' + where)[0]['total']
              for name, (obj, where) in scopes.items()}
    assert all(value == 0 for value in counts.values()), 'Fixture already associated; do not alter associations'
    all_contacts = query('SELECT Id, AccountId FROM Contact WHERE AccountId IN (' + account_ids + ')')
    assert {row['Id'] for row in all_contacts} == {pairs[p]['contact']['Id'] for p in PAIRS}
    assert len(all_contacts) == 2
    return counts


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true')
    mode.add_argument('--plan', action='store_true')
    args = parser.parse_args()
    assert query('SELECT Id FROM Organization') == [{'Id': '00Daj00001Ae3iWEAR'}]
    owner = query("SELECT Id, IsActive, UserType, ProfileId, UserRoleId, UserRole.DeveloperName, "
                  "UserRole.PortalType, Profile.Name, Profile.UserLicense.Name FROM User WHERE Id = '" + OWNER + "'")[0]
    assert owner['IsActive'] and owner['UserType'] == 'Standard'
    assert owner['Profile']['UserLicense']['Name'] == 'Salesforce'
    assert owner['UserRoleId'] and owner['UserRole']['DeveloperName'] == 'VP_Sales' and owner['UserRole']['PortalType'] == 'None'
    assert query("SELECT ParentId FROM ObjectPermissions WHERE SobjectType = 'Account' AND PermissionsRead = true "
                 "AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = '" + OWNER + "')")
    for obj in ['Account', 'Contact']:
        fields = sf('sobject', 'describe', '--sobject', obj)['fields']
        key = next(field for field in fields if field['name'] == 'Seed_Tag__c')
        assert key['unique'] and key['externalId'] and key['createable']
    prior = fixtures()
    payload = request()
    assert payload['allOrNone'] and len(payload['compositeRequest']) == 4
    assert all(row['method'] == 'POST' for row in payload['compositeRequest'])
    if not args.apply:
        output = {'mode': 'PLAN ONLY', 'owner': owner, 'fixtureState': 'complete/reuse' if prior else 'absent/create four',
                  'request': payload, 'orgWritesPerformed': 0}
        save('CUSTOMER_FIXTURES_PREFLIGHT.json', output)
        print(json.dumps(clean(output), indent=2))
        return
    before = snapshot()
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    created = prior is None
    if created:
        save('CUSTOMER_FIXTURES_REQUEST.json', payload)
        raw = sf('api', 'request', 'rest', '/services/data/v68.0/composite', '--method', 'POST',
                 '--header', 'Content-Type:application/json', '--body', json.dumps(payload))
        save('CUSTOMER_FIXTURES_RESPONSE_' + stamp + '.json', raw)
        body = raw.get('body', raw)
        body = json.loads(body) if isinstance(body, str) else body
        assert isinstance(body, dict) and len(body.get('compositeResponse', [])) == 4, 'Unexpected response; stop without retry'
        for row in body['compositeResponse']:
            assert row['httpStatusCode'] == 201 and row['body']['success'], json.dumps(clean(body))
    pairs = fixtures()
    assert pairs is not None
    counts = isolation(pairs)
    after = snapshot()
    new_accounts = {pairs[p]['account']['Id'] for p in PAIRS} if created else set()
    new_contacts = {pairs[p]['contact']['Id'] for p in PAIRS} if created else set()
    checks = {
        'accountCountDeltaExact': len(after['accounts']) - len(before['accounts']) == len(new_accounts),
        'contactCountDeltaExact': len(after['contacts']) - len(before['contacts']) == len(new_contacts),
        'existingAccountsUnchanged': before['accounts'] == [row for row in after['accounts'] if row['Id'] not in new_accounts],
        'existingContactsUnchanged': before['contacts'] == [row for row in after['contacts'] if row['Id'] not in new_contacts],
        'relatedBusinessUnchanged': before['relatedBusiness'] == after['relatedBusiness'],
        'usersUnchanged': before['userStateSha256'] == after['userStateSha256'],
        'rolesUnchanged': before['roleStateSha256'] == after['roleStateSha256'],
    }
    output = {'status': 'PASS' if all(checks.values()) else 'VERIFICATION DIFFERENCE', 'observedAtUtc': stamp,
              'mode': 'CREATED' if created else 'REUSED_NO_WRITES', 'ownerEligibility': owner,
              'accountsCreated': len(new_accounts), 'contactsCreated': len(new_contacts), 'pairs': pairs,
              'accountRowsBeforeAfter': [len(before['accounts']), len(after['accounts'])],
              'contactRowsBeforeAfter': [len(before['contacts']), len(after['contacts'])],
              'isolationCounts': counts, 'checks': checks,
              'preservation': {'beforeAccountsSha256': sha(before['accounts']),
                               'afterPriorAccountsSha256': sha([row for row in after['accounts'] if row['Id'] not in new_accounts]),
                               'beforeContactsSha256': sha(before['contacts']),
                               'afterPriorContactsSha256': sha([row for row in after['contacts'] if row['Id'] not in new_contacts]),
                               'relatedBusinessBefore': before['relatedBusiness'], 'relatedBusinessAfter': after['relatedBusiness'],
                               'userStateSha256BeforeAfter': [before['userStateSha256'], after['userStateSha256']],
                               'roleStateSha256BeforeAfter': [before['roleStateSha256'], after['roleStateSha256']]},
              'externalUsersCreated': 0, 'siteCreated': False, 'limits': 'Existing-customer check fingerprints IDs/ownership/parent/LastModifiedDate, not every field/history/deleted row.'}
    save('CUSTOMER_FIXTURES_RUN_' + stamp + '.json', output)
    save('CUSTOMER_FIXTURES_VERIFICATION.json', output)
    if created:
        assert not (EVIDENCE / 'CUSTOMER_FIXTURES_CREATION.json').exists(), 'Creation receipt already exists; preserve it'
        save('CUSTOMER_FIXTURES_CREATION.json', output)
    print(json.dumps(clean({key: value for key, value in output.items() if key != 'preservation'}), indent=2))
    assert all(checks.values()), 'Stop on preservation difference; no repairs or delete/retry authorized'


if __name__ == '__main__':
    main()
