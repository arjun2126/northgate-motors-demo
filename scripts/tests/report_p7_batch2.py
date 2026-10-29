"""Verify saved check-only results/source continuity and read back unchanged live entry points."""
import hashlib
import json
from collections import Counter
from pathlib import Path

from audit_p7_batch2 import sf
from check_p7_batch2 import CLASSES, REMOVED, TRIGGERS

ROOT = Path(__file__).resolve().parents[2]


def main():
    raw = json.loads((ROOT / 'evidence/P7/BATCH2_CHECK_ONLY.json').read_text())
    result = raw['result']
    assert raw['status'] == 0 and result['status'] == 'Succeeded' and result['checkOnly']
    assert result['numberComponentErrors'] == 0 and result['numberTestErrors'] == 0
    snapshot = json.loads((ROOT / 'evidence/P7/BATCH2_LOCAL_SCOPE_CHECK.json').read_text())
    for relative, digest in snapshot['sourceSha256'].items():
        assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == digest, relative
    successes = result['details']['componentSuccesses']
    selected = {(row['componentType'], row['fullName']) for row in successes if row['componentType']}
    expected = {('ApexClass', name) for name in CLASSES} | {('ApexTrigger', name) for name in TRIGGERS | REMOVED}
    assert selected == expected
    assert {row['fullName'] for row in successes if row.get('deleted')} == REMOVED
    tests = result['details']['runTestResult']
    counts = Counter(row['name'] for row in tests['successes'])
    assert len(tests['successes']) == result['numberTestsTotal'] == 235
    assert not tests.get('failures') and not tests.get('codeCoverageWarnings')
    # Check-only must leave the seven old trigger entry points active in the live org.
    names = ','.join("'" + name + "'" for name in sorted(TRIGGERS | REMOVED))
    live = sf('data', 'query', '--use-tooling-api', '--query',
              'SELECT Name, TableEnumOrId, Status FROM ApexTrigger WHERE Name IN (' + names + ')')
    assert live['done'] and {row['Name'] for row in live['records']} == TRIGGERS | REMOVED
    assert all(row['Status'] == 'Active' for row in live['records'])
    live_rows = [{key: value for key, value in row.items() if key != 'attributes'} for row in live['records']]
    coverage = [{'name': row['name'], 'covered': row['numLocations'] - row['numLocationsNotCovered'],
                 'total': row['numLocations']} for row in tests['codeCoverage']]
    output = {'status': 'PASS', 'id': result['id'], 'completedDate': result['completedDate'],
              'checkOnly': result['checkOnly'], 'componentChanges': len(selected),
              'replacementComponents': 10, 'removedTriggersInValidationOnly': sorted(REMOVED),
              'testsPassed': sum(counts.values()), 'testClasses': len(counts),
              'newTestsPassed': counts['P7TriggerArchitectureTest'] + counts['InventoryReconciliationJobTest'],
              'perClassTestsPassed': dict(sorted(counts.items())), 'coverage': coverage,
              'selectedSourceHashesUnchanged': len(snapshot['sourceSha256']),
              'liveOriginalTriggersStillActive': live_rows, 'actualDeploymentPerformed': False,
              'batch1Acceptance': 'DEFERRED: browser/gallery/events, operational access/placement, VIN credentials'}
    (ROOT / 'evidence/P7/BATCH2_VALIDATION_SUMMARY.json').write_text(json.dumps(output, indent=2) + '\n')
    trigger_tests = [row for row in tests['successes'] if row['name'] == 'P7TriggerArchitectureTest']
    queue_tests = [row for row in tests['successes'] if row['name'] == 'InventoryReconciliationJobTest']
    for filename, rows in [('trigger_tests.txt', trigger_tests), ('queueable.txt', queue_tests)]:
        (ROOT / 'evidence/P7' / filename).write_text(
            'CONFIRMED — raw check-only test successes from ' + result['id'] + '\n'
            + json.dumps(rows, indent=2) + '\n')
    print(json.dumps(output, indent=2))


if __name__ == '__main__':
    main()
