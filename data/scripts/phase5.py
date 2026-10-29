#!/usr/bin/env python3
"""Phase 5 acceptance preparation. Org commands are read-only; no mutation entry point."""

import argparse
import csv
import hashlib
import json
import re
import subprocess
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ORG = 'ng-demo'
ORG_ID = '00Daj00001Ae3iWEAR'
OBJECTS = {
    'Rooftop__c': '01-rooftops.csv', 'Vehicle_Model__c': '02-models.csv',
    'Product2': '03-products.csv', 'PricebookEntry': '04-pricebookentries.csv',
    'Staff__c': '05-staff.csv', 'Vehicle__c': '06-vehicles.csv',
    'Account': '07-accounts.csv', 'Contact': '08-contacts.csv', 'Lead': '09-leads.csv',
    'Opportunity': '10-opportunities.csv', 'OpportunityLineItem': '11-opptylineitems.csv',
    'Quote': '12-quotes.csv', 'QuoteLineItem': '13-quotelineitems.csv',
    'Trade_In__c': '14-tradeins.csv', 'Financing__c': '15-financing.csv',
    'Delivery__c': '16-deliveries.csv', 'Test_Drive__c': '17-testdrives.csv',
    'Case': '18-cases.csv', 'Service_Visit__c': '19-servicevisits.csv',
    'Campaign': '20-campaigns.csv', 'CampaignMember': '21-campaignmembers.csv',
    'Loyalty_Member__c': '22-loyaltymembers.csv',
    'Loyalty_Transaction__c': '23-loyaltytxns.csv', 'Consent__c': '24-consents.csv',
    'Task': '25-tasks.csv', 'Event': '26-events.csv', 'Data_Load_Batch__c': '27-dataloadbatches.csv',
}
TARGETS = [4, 30, 60, 60, 14, 120, 150, 185, 130, 100, 100, 60, 80, 45,
           60, 12, 70, 60, 140, 5, 60, 70, 110, 90, 200, 50, 20]


def sf(*args):
    result = subprocess.run(['sf', *args, '--target-org', ORG, '--json'],
                            capture_output=True, text=True, check=False)
    response = json.loads(result.stdout)
    if result.returncode or response.get('status') != 0:
        raise RuntimeError(response.get('message', result.stderr))
    return response['result']


def identity():
    if sf('org', 'display')['id'] != ORG_ID:
        raise ValueError('ng-demo identity mismatch')


def query(soql):
    return sf('data', 'query', '--query', soql)['records']


def get(path):
    result = sf('api', 'request', 'rest', '/services/data/v68.0/' + path, '--method', 'GET')
    if result['statusCode'] != 200:
        raise RuntimeError(str(result['body']))
    return result['body']


def read_csv(path):
    with Path(path).open(newline='', encoding='utf-8-sig') as stream:
        return list(csv.DictReader(stream))


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write_json(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        raise ValueError(f'Refusing to overwrite {path.name}')
    path.write_text(json.dumps(data, indent=2) + '\n')


def reconcile(csv_dir):
    counts = {obj: len(read_csv(Path(csv_dir) / name)) for obj, name in OBJECTS.items()}
    if list(counts.values()) != TARGETS:
        raise ValueError('CSV volumes differ from preserved per-object envelope')
    clean = sum(counts.values()) - counts['Task'] - counts['Event']
    return {
        'canonicalCounts': counts, 'canonicalRecords': sum(counts.values()),
        'dataPlanClean': clean, 'activities': 250, 'legacyRequired': 30,
        'governingFullTotal': sum(counts.values()) + 30,
        'historicalBacklogClean': 1843, 'historicalBacklogFullTotal': 2123,
        'allocationAdjustment': {'Product2': '+20', 'Delivery__c': '-28', 'net': -8},
        'governingDecision': '2026-10-20: 60 Product2 + 12 Delivery selected; original 2,123 preserved as historical',
        'status': 'RECONCILED_GOVERNING_2026_10_20',
        'criteriaReduced': False,
    }


def legacy_rows(parent_map=None):
    contacts, trades = [], []
    for kind, size in [('PHONE', 10), ('POSTAL', 8), ('EMAIL', 6)]:
        for index in range(size):
            tag = f'SEED-98-{kind}-{index + 1:03d}'
            row = {'Seed_Tag__c': tag, 'FirstName': 'Legacy', 'LastName': f'Fixture {kind} {index + 1}',
                   'Email': f'legacy.{kind.lower()}.{index + 1}@northgate-demo.test',
                   'Phone': '4165550101', 'MailingStreet': '100 Fictional Way',
                   'MailingCity': 'Toronto', 'MailingState': 'Ontario',
                   'MailingCountry': 'Canada', 'MailingPostalCode': 'M5V 2T6'}
            if kind == 'PHONE':
                row['Phone'] = '416-5550' if index % 2 == 0 else 'n/a'
            elif kind == 'POSTAL':
                row['MailingPostalCode'] = ''
            else:
                pair = index // 2 + 1
                email = f'legacy.duplicate.{pair}@northgate-demo.test'
                row['Email'] = email if index % 2 else email.upper()
                row['LastName'] = f'Legacy Duplicate {pair}'
            contacts.append(row)
    for index in range(6):
        tag = f'SEED-98-VIN-{index + 1:03d}'
        row = {'Seed_Tag__c': tag, 'Status__c': 'Requested',
               'Trade_VIN__c': f'O123456789012{index:03d}'}
        if parent_map is not None:
            parent = parent_map[tag]
            for field, prefix in [('Opportunity__c','006'), ('Contact__c','003')]:
                if not re.fullmatch(prefix + r'[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?', parent[field]):
                    raise ValueError('Invalid resolved legacy parent ID')
                row[field] = parent[field]
        trades.append(row)
    return {'Contact': contacts, 'Trade_In__c': trades}


def prepare_legacy(destination, parent_map=None):
    destination = Path(destination).resolve()
    if destination == (ROOT / 'data/csv').resolve() or (ROOT / 'data/csv') in destination.parents:
        raise ValueError('Preserved canonical CSV directory cannot be an output directory')
    if parent_map is None or set(parent_map) != {f'SEED-98-VIN-{i:03d}' for i in range(1, 7)}:
        raise ValueError('Exact six-parent mapping required; run legacy-parents read-only first')
    destination.mkdir(parents=True, exist_ok=True)
    for obj, rows in legacy_rows(parent_map).items():
        path = destination / f'{obj}.csv'
        with path.open('x', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
    return {'prepared': {'Contact': 24, 'Trade_In__c': 6}, 'executed': False,
            'requires': ['owner approval and live recheck of mapped parents', 'bypass snapshot/grant/revoke',
                         'duplicate-rule behavior verification', 'storage preflight',
                         'explicit owner data authorization']}


def legacy_parents():
    """Propose additive fixtures on open, unquoted deals; never modify their parents."""
    identity()
    opportunities = query("SELECT Id, Seed_Tag__c, AccountId, StageName FROM Opportunity WHERE Seed_Tag__c LIKE 'SEED-%' AND IsClosed=false ORDER BY Seed_Tag__c")
    contacts = query("SELECT Id, Seed_Tag__c, AccountId FROM Contact WHERE Seed_Tag__c LIKE 'SEED-%' ORDER BY Seed_Tag__c")
    used = set()
    for obj, field in [('Quote','OpportunityId'), ('Trade_In__c','Opportunity__c'),
                       ('Financing__c','Opportunity__c'), ('Delivery__c','Opportunity__c')]:
        used.update(r[field] for r in query(f'SELECT {field} FROM {obj} WHERE {field}!=null'))
    by_account = {}
    for contact in contacts:
        by_account.setdefault(contact['AccountId'], contact)
    mapping = {}
    for opp in opportunities:
        if opp['Id'] in used or opp['AccountId'] not in by_account:
            continue
        contact = by_account[opp['AccountId']]
        tag = f'SEED-98-VIN-{len(mapping) + 1:03d}'
        mapping[tag] = {'Opportunity__c':opp['Id'], 'Contact__c':contact['Id'],
                        'opportunitySeed':opp['Seed_Tag__c'], 'contactSeed':contact['Seed_Tag__c'],
                        'accountId':opp['AccountId'], 'stage':opp['StageName']}
        if len(mapping) == 6:
            break
    return {'orgId':ORG_ID, 'observedAt':datetime.now(timezone.utc).isoformat(),
            'ownerApproved':False, 'mappingReady':len(mapping)==6, 'parents':mapping,
            'impact':'New Requested Trade-Ins affect future quote eligibility; approve exact links before insertion.'}


def ledger_from_job(job, results, anchor, storage, storage_at):
    """Reconcile final job metadata/results without inventing a completion timestamp."""
    if job.get('state') != 'JobComplete' or not job.get('systemModstamp'):
        raise ValueError('Completed job with final modification timestamp required')
    if not re.fullmatch(r'750[a-zA-Z0-9]{12}(?:[a-zA-Z0-9]{3})?', job.get('id', '')):
        raise ValueError('Full Bulk API job ID required')
    created = [row.get('sf__Created', '').lower() for row in results]
    if any(value not in ('true', 'false') for value in created):
        raise ValueError('Per-record sf__Created evidence required; upsert success is not insert count')
    failures = int(job.get('numberRecordsFailed', 0))
    processed = int(job['numberRecordsProcessed'])
    if processed != len(results) + failures:
        raise ValueError('Processed count does not reconcile to successes plus failures')
    if not anchor or storage is None or not storage_at:
        raise ValueError('Anchor and timestamped storage reading required; do not infer history')
    return {'jobId': job['id'], 'object': job['object'], 'startedAt': job['createdDate'],
            'jobFinalModifiedAt': job['systemModstamp'], 'inserted': created.count('true'),
            'updated': created.count('false'), 'failed': failures,
            'anchorDate': anchor, 'storageUsedMb': storage, 'storageObservedAt': storage_at,
            'status': 'Partial' if failures else 'Loaded'}


def recover_job(job_id, anchor, storage=None, storage_at=None):
    job = get('jobs/ingest/' + job_id)
    result = sf('api', 'request', 'rest', '/services/data/v68.0/jobs/ingest/' + job_id + '/successfulResults', '--method', 'GET')
    if result['statusCode'] != 200 or not isinstance(result['body'], str):
        raise ValueError('Expected successfulResults CSV response')
    import io
    rows = list(csv.DictReader(io.StringIO(result['body'])))
    # A missing historical storage reading is a genuine evidence gap, never today's value.
    return ledger_from_job(job, rows, anchor, storage, storage_at)


def snapshot(destination):
    identity()
    records, manifest = {}, {}
    for obj, name in OBJECTS.items():
        rows = read_csv(ROOT / 'data/csv' / name)
        if obj == 'OpportunityLineItem':
            ids = query("SELECT Id FROM Opportunity WHERE Seed_Tag__c LIKE 'SEED-%'")
            selector = 'OpportunityId IN (' + ','.join("'" + r['Id'] + "'" for r in ids) + ')'
        else:
            selector = "Seed_Tag__c LIKE 'SEED-%'"
        records[obj] = query(f'SELECT FIELDS(ALL) FROM {obj} WHERE {selector} LIMIT 2000')
        if len(records[obj]) >= 2000:
            raise ValueError('Snapshot truncated; increase supported export scope before reset')
        manifest[name] = digest(ROOT / 'data/csv' / name)
    payload = {'orgId': ORG_ID, 'capturedAt': datetime.now(timezone.utc).isoformat(),
               'manifest': manifest, 'records': records, 'limits': get('limits')}
    write_json(destination, payload)
    return {'snapshot': str(destination), 'sha256': digest(destination), 'objects': len(records)}


def reset_plan(snapshot_data, now=None):
    now = now or datetime.now(timezone.utc)
    captured = datetime.fromisoformat(snapshot_data['capturedAt'])
    if captured.tzinfo is None or not timedelta(0) <= now - captured <= timedelta(hours=1):
        raise ValueError('A fresh snapshot (at most one hour old, not future-dated) is required')
    if snapshot_data.get('orgId') != ORG_ID:
        raise ValueError('Snapshot belongs to another org')
    records = snapshot_data['records']
    manifest = snapshot_data.get('manifest', {})
    if (set(records) != set(OBJECTS) or set(manifest) != set(OBJECTS.values())
            or any(not re.fullmatch(r'[0-9a-f]{64}', value) for value in manifest.values())):
        raise ValueError('Incomplete snapshot cannot authorize reset')
    tags = {obj: {r['Seed_Tag__c'] for r in read_csv(ROOT / 'data/csv' / name)}
            for obj, name in OBJECTS.items() if obj != 'OpportunityLineItem'}
    ids = set()
    opp_ids = {r['Id'] for r in records['Opportunity']}
    for obj, rows in records.items():
        for row in rows:
            record_id = row.get('Id', '')
            if not re.fullmatch(r'[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?', record_id) or record_id in ids:
                raise ValueError('Invalid or duplicate reset ID')
            ids.add(record_id)
            if obj == 'OpportunityLineItem':
                if row.get('OpportunityId') not in opp_ids:
                    raise ValueError('OLI is not attached to a snapshotted canonical Opportunity')
            elif row.get('Seed_Tag__c') not in tags[obj]:
                raise ValueError('Historical, UAT or special row outside canonical manifest; reset refused')
    if snapshot_data.get('externalReferences'):
        raise ValueError('Noncanonical dependent records prevent reset')
    return {'orgId': ORG_ID, 'dryRun': True,
            'childFirst': [{'object': obj, 'recordIds': [row['Id'] for row in records[obj]]}
                           for obj in reversed(OBJECTS)],
            'executionBlocked': ['separate exact-ID delete approval', 'external-reference/pending-approval check',
                                 'targeted Recycle Bin purge approval', 'reload authorization',
                                 'post-reload <=4.0 MB Storage Usage proof'],
            'orgWidePurge': False}


def prepare_burst(destination, as_of=None):
    """Separate 200/60/40 schemas; never consume the lossy mixed-object burst CSV."""
    destination = Path(destination).resolve()
    if destination == (ROOT / 'data/csv').resolve() or (ROOT / 'data/csv') in destination.parents:
        raise ValueError('Canonical output cannot be replaced by burst preparation')
    as_of = as_of or datetime.now(timezone.utc)
    contacts = read_csv(ROOT / 'data/csv/08-contacts.csv')
    vehicles = read_csv(ROOT / 'data/csv/06-vehicles.csv')
    staff = read_csv(ROOT / 'data/csv/05-staff.csv')
    opportunities = read_csv(ROOT / 'data/csv/10-opportunities.csv')
    advisor = next(r['Seed_Tag__c'] for r in staff if r['Role__c']=='Service_Advisor')
    technician = next(r['Seed_Tag__c'] for r in staff if r['Role__c']=='Technician')
    rows = {'Lead':[], 'Service_Visit__c':[], 'Task':[]}
    for index in range(200):
        rows['Lead'].append({'Seed_Tag__c':f'SEED-77-BURST-LEAD-{index+1:03d}',
                            'LastName':f'Fictional Burst Buyer {index+1}', 'Company':f'Burst Company {index+1}',
                            'Email':f'burst.{index+1}@northgate-demo.test', 'Phone':'4165550101',
                            'Status':'Open - Not Contacted', 'LeadSource':'Web'})
    for index in range(60):
        rows['Service_Visit__c'].append({'Seed_Tag__c':f'SEED-77-BURST-SV-{index+1:03d}',
            'Contact__c':contacts[index % len(contacts)]['Seed_Tag__c'],
            'Vehicle__c':vehicles[index % len(vehicles)]['Seed_Tag__c'],
            'Advisor_Staff__c':advisor, 'Technician_Staff__c':technician,
            'Status__c':'Scheduled', 'Service_Type__c':'Oil_Change', 'Duration_Minutes__c':30,
            'Scheduled_Start__c':(as_of+timedelta(days=7, hours=index)).isoformat()})
    for index in range(40):
        rows['Task'].append({'Seed_Tag__c':f'SEED-77-BURST-TASK-{index+1:03d}',
            'Subject':'Burst follow-up', 'Status':'Not Started', 'Priority':'Normal',
            'ActivityDate':(as_of+timedelta(days=2)).date().isoformat(),
            'WhoId':contacts[index]['Seed_Tag__c'], 'WhatId':opportunities[index]['Seed_Tag__c']})
    destination.mkdir(parents=True, exist_ok=True)
    for obj, items in rows.items():
        with (destination / f'{obj}.csv').open('x', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=list(items[0])); writer.writeheader(); writer.writerows(items)
    return {'prepared':{o:len(r) for o,r in rows.items()}, 'executed':False,
            'parentResolutionRequired':True, 'leadStatusLiveValidationRequired':True}


def resolve_specials(directory, destination):
    """Read-only parent resolution; outputs a new directory, never runs an insert."""
    identity()
    targets = {'Contact__c':'Contact', 'Vehicle__c':'Vehicle__c', 'Opportunity__c':'Opportunity',
               'Advisor_Staff__c':'Staff__c', 'Technician_Staff__c':'Staff__c',
               'WhoId':'Contact', 'WhatId':'Opportunity'}
    maps = {obj:{r['Seed_Tag__c']:r['Id'] for r in query(f"SELECT Id, Seed_Tag__c FROM {obj} WHERE Seed_Tag__c LIKE 'SEED-%'")}
            for obj in set(targets.values())}
    destination = Path(destination).resolve()
    if destination == Path(directory).resolve() or destination == (ROOT/'data/csv').resolve() or (ROOT/'data/csv') in destination.parents:
        raise ValueError('Resolution needs a distinct noncanonical output directory')
    destination.mkdir(parents=True, exist_ok=True)
    counts = {}
    for path in sorted(Path(directory).glob('*.csv')):
        if path.stem not in ('Lead','Contact','Trade_In__c','Service_Visit__c','Task'):
            raise ValueError('Unexpected special-batch object')
        rows = read_csv(path)
        for row in rows:
            if not row['Seed_Tag__c'].startswith(('SEED-77-BURST-','SEED-98-')):
                raise ValueError('Non-special row in prepared fixture batch')
            for field, obj in targets.items():
                value = row.get(field)
                if value and value.startswith('SEED-'):
                    if value not in maps[obj]: raise ValueError(f'Unresolved parent: {obj}/{value}')
                    row[field] = maps[obj][value]
        if rows:
            with (destination/path.name).open('x', newline='') as stream:
                writer=csv.DictWriter(stream, fieldnames=list(rows[0])); writer.writeheader(); writer.writerows(rows)
        counts[path.stem] = len(rows)
    return {'resolved':counts, 'executed':False}


def burst_teardown(records):
    prefixes = {'Lead':'SEED-77-BURST-LEAD-', 'Service_Visit__c':'SEED-77-BURST-SV-',
                'Task':'SEED-77-BURST-TASK-'}
    if set(records) != set(prefixes): raise ValueError('Exact three burst object sets required')
    ids = set()
    for obj, rows in records.items():
        for row in rows:
            record_id=row.get('Id','')
            if (not row.get('Seed_Tag__c','').startswith(prefixes[obj])
                    or not re.fullmatch(r'[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?',record_id)
                    or record_id in ids):
                raise ValueError('Teardown contains canonical/historical/nonburst or duplicate IDs')
            ids.add(record_id)
    return {'dryRun':True, 'orgWidePurge':False,
            'childFirst':[{'object':o,'recordIds':[r['Id'] for r in records[o]]}
                          for o in ('Task','Service_Visit__c','Lead')],
            'purgeIds':sorted(ids),
            'blockedUntil':'Fresh snapshot, dependency/cascade review, exact-ID delete/purge approval and storage evidence'}


def expected_count(actual, expected):
    return {'actual': actual, 'expected': expected, 'passed': actual == expected}


def integrity():
    identity()
    references = {
        'Contact': {'AccountId':'Account'},
        'Opportunity': {'AccountId':'Account', 'Vehicle__c':'Vehicle__c', 'Sales_Staff__c':'Staff__c'},
        'Quote': {'OpportunityId':'Opportunity', 'Pricebook2Id':'Pricebook2', 'Buyer_Contact__c':'Contact'},
        'QuoteLineItem': {'QuoteId':'Quote', 'PricebookEntryId':'PricebookEntry'},
        'Trade_In__c': {'Opportunity__c':'Opportunity', 'Contact__c':'Contact'},
        'Financing__c': {'Opportunity__c':'Opportunity', 'Applicant__c':'Contact', 'Vehicle__c':'Vehicle__c', 'Quote__c':'Quote'},
        'Delivery__c': {'Opportunity__c':'Opportunity', 'Vehicle__c':'Vehicle__c', 'Buyer__c':'Contact'},
        'Test_Drive__c': {'Vehicle__c':'Vehicle__c', 'Contact__c':'Contact', 'Opportunity__c':'Opportunity'},
        'Service_Visit__c': {'Vehicle__c':'Vehicle__c', 'Contact__c':'Contact', 'Case__c':'Case',
                             'Advisor_Staff__c':'Staff__c', 'Technician_Staff__c':'Staff__c'},
        'Loyalty_Member__c': {'Contact__c':'Contact'},
        'Loyalty_Transaction__c': {'Loyalty_Member__c':'Loyalty_Member__c'},
        'Consent__c': {'Contact__c':'Contact'},
        'CampaignMember': {'CampaignId':'Campaign', 'ContactId':'Contact', 'LeadId':'Lead'},
    }
    checks = {}
    for obj, fields in references.items():
        for field, target in fields.items():
            n = query(f"SELECT COUNT(Id) n FROM {obj} WHERE Seed_Tag__c LIKE 'SEED-%' AND {field}!=null AND {field} NOT IN (SELECT Id FROM {target})")[0]['n']
            checks[f'{obj}.{field}'] = expected_count(n, 0)
    return {'checks':checks, 'passed':all(r['passed'] for r in checks.values()),
            'additionalEvidenceRequired':'Polymorphic Task/Event links and required-parent completeness must also be verified.'}


def findings():
    """Read-only assertions retain all eight original expected-count DQ requirements."""
    identity()
    checks = {}
    for key, soql, expected in [
        ('staleLeads', "SELECT COUNT(Id) n FROM Lead WHERE Seed_Tag__c LIKE 'SEED-%' AND IsConverted=false AND (LastActivityDate < LAST_N_DAYS:60 OR (LastActivityDate=null AND CreatedDate < LAST_N_DAYS:60))", 35),
        ('ignoredCases', "SELECT COUNT(Id) n FROM Case WHERE IsClosed=false AND CreatedDate < LAST_N_DAYS:14 AND Id NOT IN (SELECT ParentId FROM CaseComment)", 8),
        ('overdueVisits', "SELECT COUNT(Id) n FROM Service_Visit__c WHERE Status__c='Scheduled' AND Scheduled_Start__c < TODAY", 12),
        ('agedInventory', "SELECT COUNT(Id) n FROM Vehicle__c WHERE Inventory_Age_Days__c>120", 12),
        ('stalledQuoting', "SELECT COUNT(Id) n FROM Opportunity WHERE StageName='Quoting' AND Stage_Last_Changed__c < LAST_N_DAYS:45", 6),
    ]:
        checks[key] = expected_count(query(soql)[0]['n'], expected)
    revoked = query("SELECT Contact__c FROM Consent__c WHERE Status__c='Revoked'")
    ids = sorted({r['Contact__c'] for r in revoked if r['Contact__c']})
    members = query('SELECT ContactId FROM CampaignMember WHERE ContactId IN (' + ','.join("'" + i + "'" for i in ids) + ')') if ids else []
    checks['revokedOnCampaign'] = expected_count(len({r['ContactId'] for r in members}), 6)
    legacy = {}
    for obj in ('Contact', 'Trade_In__c'):
        for row in query(f"SELECT Seed_Tag__c FROM {obj} WHERE Seed_Tag__c LIKE 'SEED-98-%'"):
            kind = row['Seed_Tag__c'].split('-')[2]
            legacy[kind] = legacy.get(kind, 0) + 1
    for kind, expected in [('PHONE', 10), ('POSTAL', 8), ('VIN', 6), ('EMAIL', 6)]:
        checks['legacy' + kind] = expected_count(legacy.get(kind, 0), expected)
    households = query("SELECT LastName, MailingStreet, MailingPostalCode, AccountId FROM Contact WHERE Seed_Tag__c LIKE 'SEED-%' AND (NOT Seed_Tag__c LIKE 'SEED-98-%')")
    grouped = {}
    for row in households:
        key = tuple((row.get(f) or '').strip().casefold() for f in ('LastName','MailingStreet','MailingPostalCode'))
        if all(key):
            grouped.setdefault(key, set()).add(row['AccountId'])
    checks['duplicateHouseholdPairs'] = expected_count(sum(1 for ids in grouped.values() if len(ids) == 2), 8)
    return {'checks': checks, 'passed': all(row['passed'] for row in checks.values()),
            'note': 'Actual fixture values/pairs still require report and duplicate-rule evidence.'}


def verify(storage_mb=None, storage_evidence=None):
    """Original release gates; missing legacy/ledger/count evidence must never pass."""
    identity()
    checks = {}
    zero_queries = {
        'invalidVin': "SELECT COUNT(Id) n FROM Vehicle__c WHERE Is_VIN_Valid__c=false",
        'nonpositiveOpportunity': "SELECT COUNT(Id) n FROM Opportunity WHERE StageName!='Prospecting' AND Amount<=0",
        'wonWithoutDelivery': "SELECT COUNT(Id) n FROM Opportunity WHERE IsWon=true AND Delivery_Completed__c=false",
        'financeRateTerm': "SELECT COUNT(Id) n FROM Financing__c WHERE Annual_Rate__c<0 OR Annual_Rate__c>25 OR Term_Months__c NOT IN (36,48,60,72,84,96)",
        'negativeLoyalty': "SELECT COUNT(Id) n FROM Loyalty_Member__c WHERE Points_Balance__c<0",
        'completedVisitZeroCost': "SELECT COUNT(Id) n FROM Service_Visit__c WHERE Status__c='Completed' AND Total_Cost__c=0",
        'revokedMissingDate': "SELECT COUNT(Id) n FROM Consent__c WHERE Status__c='Revoked' AND Revoked_On__c=null",
    }
    for name, soql in zero_queries.items():
        checks[name] = expected_count(query(soql)[0]['n'], 0)
    checks['duplicateVin'] = expected_count(len(query('SELECT VIN__c, COUNT(Id) n FROM Vehicle__c GROUP BY VIN__c HAVING COUNT(Id)>1')), 0)
    extras, missing, duplicates = [], [], []
    canonical_total = 0
    legacy_expected = {obj: {r['Seed_Tag__c'] for r in rows} for obj, rows in legacy_rows().items()}
    for obj, name in OBJECTS.items():
        if obj == 'OpportunityLineItem':
            parents = query("SELECT Id FROM Opportunity WHERE Seed_Tag__c LIKE 'SEED-%'")
            rows = query('SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN (' + ','.join("'" + r['Id'] + "'" for r in parents) + ')') if parents else []
            canonical_total += len(rows)
            checks['canonicalOli'] = expected_count(len(rows), 100)
            continue
        expected = {r['Seed_Tag__c'] for r in read_csv(ROOT / 'data/csv' / name)}
        rows = query(f"SELECT Seed_Tag__c FROM {obj} WHERE Seed_Tag__c LIKE 'SEED-%'")
        found = Counter(r['Seed_Tag__c'] for r in rows)
        allowed = expected | legacy_expected.get(obj, set())
        extras += [f'{obj}/{tag}' for tag in found if tag not in allowed]
        missing += [f'{obj}/{tag}' for tag in allowed if not found[tag]]
        duplicates += [f'{obj}/{tag}' for tag, count in found.items() if count != 1]
        canonical_total += sum(found[tag] for tag in expected)
    checks['seedIdentity'] = {'passed': not (extras or missing or duplicates),
                              'missing': missing, 'extra': extras, 'duplicates': duplicates}
    ledger = query('SELECT Seed_Version__c, Inserted_Count__c, Failed_Count__c, Loaded_At__c, Status__c, Notes__c FROM Data_Load_Batch__c')
    bad_ledger = 0
    for row in ledger:
        try:
            evidence = json.loads(row['Notes__c'])
            valid = (row['Status__c'] in ('Loaded','Partial') and row['Seed_Version__c']=='SEED-2026.10.01'
                     and row['Loaded_At__c'] and evidence['jobId'] and evidence['anchorDate']=='2026-10-01'
                     and evidence['storageUsedMb'] is not None and evidence['storageObservedAt']
                     and float(row['Inserted_Count__c'] or 0) + float(row['Failed_Count__c'] or 0)
                     + float(evidence['updated']) > 0)
        except (ValueError, KeyError, TypeError):
            valid = False
        bad_ledger += not valid
    checks['ledgerCountsAndEvidence'] = {'passed': bool(ledger) and bad_ledger==0,
                                        'rows': len(ledger), 'invalidRows': bad_ledger}
    legacy_actual = sum(query(f"SELECT COUNT(Id) n FROM {o} WHERE Seed_Tag__c LIKE 'SEED-98-%'")[0]['n'] for o in ('Contact','Trade_In__c'))
    checks['fullGoverningEnvelope'] = expected_count(canonical_total + legacy_actual, 2115)
    checks['legacyRequired'] = expected_count(legacy_actual, 30)
    emails = query("SELECT Email FROM Contact WHERE Seed_Tag__c LIKE 'SEED-%' AND Email!=null") + query("SELECT Email FROM Lead WHERE Seed_Tag__c LIKE 'SEED-%' AND Email!=null")
    checks['reservedEmailDomains'] = expected_count(sum(not r['Email'].casefold().endswith('.test') for r in emails), 0)
    checks['storage'] = {'passed': storage_mb is not None and 0 <= storage_mb <= 4.0
                         and bool(storage_evidence) and Path(storage_evidence).is_file(),
                         'exactUsedMb': storage_mb, 'limits': get('limits')['DataStorageMB'],
                         'evidenceRequired': True}
    return {'checks': checks, 'passed': all(c['passed'] for c in checks.values()),
            'originalBacklogRetained': True, 'governingFullTotal': 2115,
            'historicalBacklogFullTotal': 2123, 'canonicalRecordsObserved': canonical_total}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('counts')
    p = sub.add_parser('legacy-plan'); p.add_argument('--output', required=True); p.add_argument('--parent-map', required=True)
    p = sub.add_parser('legacy-parents'); p.add_argument('--output', required=True)
    p = sub.add_parser('burst-plan'); p.add_argument('--output', required=True)
    p = sub.add_parser('resolve-specials'); p.add_argument('--directory', required=True); p.add_argument('--output', required=True)
    p = sub.add_parser('snapshot'); p.add_argument('--output', required=True)
    p = sub.add_parser('reset-plan'); p.add_argument('--snapshot', required=True)
    p = sub.add_parser('recover-job'); p.add_argument('--job-id', required=True); p.add_argument('--anchor', required=True)
    p.add_argument('--storage-mb', type=float); p.add_argument('--storage-observed-at')
    sub.add_parser('findings')
    sub.add_parser('integrity')
    p = sub.add_parser('verify'); p.add_argument('--storage-mb', type=float); p.add_argument('--storage-evidence')
    args = parser.parse_args()
    if args.command == 'counts': result = reconcile(ROOT / 'data/csv')
    elif args.command == 'legacy-plan': result = prepare_legacy(args.output, json.loads(Path(args.parent_map).read_text())['parents'])
    elif args.command == 'legacy-parents':
        result=legacy_parents(); write_json(args.output,result)
    elif args.command == 'burst-plan': result=prepare_burst(args.output)
    elif args.command == 'resolve-specials': result=resolve_specials(args.directory,args.output)
    elif args.command == 'snapshot': result = snapshot(args.output)
    elif args.command == 'reset-plan':
        result = reset_plan(json.loads(Path(args.snapshot).read_text()))
        for name, expected in json.loads(Path(args.snapshot).read_text())['manifest'].items():
            if digest(ROOT / 'data/csv' / name) != expected:
                raise ValueError('Canonical CSV changed since snapshot')
    elif args.command == 'recover-job':
        identity(); result = recover_job(args.job_id, args.anchor, args.storage_mb, args.storage_observed_at)
    elif args.command == 'verify': result = verify(args.storage_mb, args.storage_evidence)
    elif args.command == 'integrity': result = integrity()
    else: result = findings()
    print(json.dumps(result, indent=2))
    if result.get('passed') is False:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
