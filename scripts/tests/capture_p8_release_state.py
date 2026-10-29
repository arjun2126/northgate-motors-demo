"""Read-only ng-demo fingerprints for the bounded P8 deployment (no release or repair)."""
import concurrent.futures
import json
import subprocess
import sys
from pathlib import Path

OUT = Path(sys.argv[1])
OUT.mkdir(parents=True, exist_ok=True)


def sf(args):
    result = subprocess.run(['sf', *args, '--target-org', 'ng-demo', '--json'], capture_output=True, text=True)
    assert result.returncode == 0, result.stdout
    return json.loads(result.stdout)['result']


assert sf(['data', 'query', '--query', 'SELECT Id FROM Organization'])['records'][0]['Id'] == '00Daj00001Ae3iWEAR'
available = set(sf(['sobject', 'list', '--sobject', 'all']))
queries = {'users': 'SELECT Id, ProfileId, UserRoleId, UserType, IsActive, ContactId FROM User ORDER BY Id'}
for obj in ['Account', 'Contact', 'Case', 'CaseComment', 'Asset', 'Vehicle__c', 'Delivery__c',
            'Service_Visit__c', 'Loyalty_Member__c', 'Loyalty_Transaction__c', 'Opportunity',
            'Quote', 'QuoteLineItem', 'Financing__c', 'Test_Drive__c', 'Product2', 'PricebookEntry']:
    queries['data_' + obj] = 'SELECT Id, SystemModstamp FROM ' + obj + ' ORDER BY Id'
shares = ['AccountShare', 'ContactShare', 'CaseShare', 'Vehicle__Share', 'Delivery__Share',
          'Service_Visit__Share', 'Loyalty_Member__Share', 'Loyalty_Transaction__Share']
for obj in shares:
    if obj in available:
        fields = [f['name'] for f in sf(['sobject', 'describe', '--sobject', obj])['fields']]
        queries['sharing_' + obj] = 'SELECT ' + ','.join(fields) + ' FROM ' + obj + ' ORDER BY Id'


def capture(item):
    name, soql = item
    result = sf(['data', 'query', '--query', soql])
    (OUT / (name + '.json')).write_text(json.dumps(result, indent=2) + '\n')
    return name, result['totalSize']


with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    counts = dict(pool.map(capture, queries.items()))
result = {'status': 'CONFIRMED', 'rows': counts, 'unavailableShareObjects': [s for s in shares if s not in available]}
(OUT / 'summary.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
