#!/usr/bin/env python3
"""Read-only P5-05 job reconciliation. Unknown historical evidence stays unknown."""
import argparse
import csv
import hashlib
import io
import json
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

import phase5

BASE = '/services/data/v68.0/'
LOAD_START = '2026-10-18T03:00:00'
LOAD_END = '2026-10-18T06:00:00'


def api(path, allow_missing=False):
    if not path.startswith(BASE):
        raise ValueError('Only relative ng-demo REST resources are permitted')
    result = phase5.sf('api', 'request', 'rest', path, '--method', 'GET')
    if allow_missing and result['statusCode'] in (404, 410):
        return None
    if result['statusCode'] != 200:
        raise RuntimeError(f"GET failed: HTTP {result['statusCode']}")
    return result['body']


def parse_successes(body):
    if not isinstance(body, str):
        raise ValueError('successfulResults must be CSV, not an inferred object mapping')
    reader = csv.DictReader(io.StringIO(body))
    if not {'sf__Id', 'sf__Created'} <= set(reader.fieldnames or []):
        raise ValueError('Missing Bulk API result columns')
    rows = list(reader)
    if any(row['sf__Created'].strip().casefold() not in ('true', 'false') for row in rows):
        raise ValueError('Unknown sf__Created value; do not classify as zero')
    if len({row['sf__Id'] for row in rows}) != len(rows):
        raise ValueError('Duplicate success IDs within one batch')
    return rows


def reconcile_job(job, body, expected_tags, oli_ids):
    processed = int(job['numberRecordsProcessed'])
    failed = int(job['numberRecordsFailed'])
    rows = None if body is None else parse_successes(body)
    if rows is not None and len(rows) + failed != processed:
        raise ValueError(f"Job {job['id']} counts do not reconcile")
    canonical_ids, inserted_ids, unclassified = set(), set(), 0
    for row in rows or []:
        canonical = (row['sf__Id'] in oli_ids if job['object'] == 'OpportunityLineItem'
                     else row.get('Seed_Tag__c') in expected_tags.get(job['object'], set()))
        if canonical:
            canonical_ids.add(row['sf__Id'])
            if row['sf__Created'].strip().casefold() == 'true':
                inserted_ids.add(row['sf__Id'])
        else:
            unclassified += 1
    return {
        'jobId': job['id'], 'object': job['object'], 'operation': job['operation'],
        'jobState': job['state'], 'startedAt': job['createdDate'],
        'jobFinalModifiedAt': job['systemModstamp'],
        'processed': processed, 'failed': failed, 'successful': processed - failed,
        'inserted': None if rows is None else sum(r['sf__Created'].strip().casefold() == 'true' for r in rows),
        'updated': None if rows is None else sum(r['sf__Created'].strip().casefold() == 'false' for r in rows),
        'resultCountReconciled': rows is not None,
        'metadataSha256': hashlib.sha256(json.dumps(job, sort_keys=True).encode()).hexdigest(),
        'successfulResultsSha256': None if body is None else hashlib.sha256(body.encode()).hexdigest(),
        'canonicalSuccessIds': sorted(canonical_ids), 'canonicalInsertIds': sorted(inserted_ids),
        'successesOutsideCanonicalManifest': unclassified,
        'historicalStorageUsedMb': None, 'historicalStorageObservedAt': None,
    }


def collect():
    phase5.identity()
    expected = {obj: {r['Seed_Tag__c'] for r in phase5.read_csv(phase5.ROOT / 'data/csv' / name)}
                for obj, name in phase5.OBJECTS.items() if obj != 'OpportunityLineItem'}
    parents = phase5.query("SELECT Id FROM Opportunity WHERE Seed_Tag__c LIKE 'SEED-%'")
    parent_ids = ','.join("'" + r['Id'] + "'" for r in parents)
    oli_ids = {r['Id'] for r in phase5.query('SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN (' + parent_ids + ')')} if parents else set()
    records, path = [], BASE + 'jobs/ingest'
    while path:
        page = api(path)
        records.extend(page['records'])
        path = page.get('nextRecordsUrl')
    selected = [r for r in records if r['object'] in phase5.OBJECTS
                and LOAD_START <= r['createdDate'][:19] < LOAD_END]
    def fetch(record):
        job = api(BASE + 'jobs/ingest/' + record['id'])
        body = api(BASE + 'jobs/ingest/' + record['id'] + '/successfulResults', allow_missing=True)
        return reconcile_job(job, body, expected, oli_ids)
    with ThreadPoolExecutor(max_workers=4) as pool:
        jobs = sorted(pool.map(fetch, selected), key=lambda r: (r['startedAt'], r['jobId']))
    covered = set().union(*(set(j['canonicalSuccessIds']) for j in jobs))
    inserted = set().union(*(set(j['canonicalInsertIds']) for j in jobs))
    canonical_expected = sum(phase5.TARGETS)
    return {
        'orgId': phase5.ORG_ID, 'capturedAt': datetime.now(timezone.utc).isoformat(),
        'seedVersion': 'SEED-2026.10.01', 'anchorDate': '2026-10-01',
        'loadWindowStart': LOAD_START, 'loadWindowEnd': LOAD_END,
        'jobs': jobs, 'jobsReconciled': len(jobs), 'objectsCovered': len({j['object'] for j in jobs}),
        'distinctCanonicalIdsCovered': len(covered), 'distinctCanonicalInsertIds': len(inserted),
        'canonicalExpected': canonical_expected,
        'executionCountsReconciled': bool(jobs) and all(j['resultCountReconciled'] for j in jobs) and len(covered) == canonical_expected,
        'attemptTotals': {key: None if any(j[key] is None for j in jobs) else sum(j[key] for j in jobs)
                          for key in ('processed', 'failed', 'inserted', 'updated')},
        'storageAcceptanceComplete': False,
        'orgLedgerWriteReady': False,
        'blockers': ['Historical per-batch storage readings are not reconstructed by current /limits.',
                     '20 canonical ledger placeholders have no evidenced one-to-one mapping to actual jobs.',
                     'Do not overwrite placeholders, merge jobs or add SEED-EXEC tags to force acceptance.'],
        'timestampSemantics': 'systemModstamp is the final recorded job modification, not an invented completion timestamp.',
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    result = collect()
    phase5.write_json(args.output, result)
    print(json.dumps({k: v for k, v in result.items() if k not in ('jobs', 'blockers')}, indent=2))


if __name__ == '__main__':
    main()
