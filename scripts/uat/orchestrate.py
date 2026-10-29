"""Local-first UAT evidence runner. No Apex execution, deployment or Salesforce writes."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = Path('evidence/UAT/FULL_PROJECT_2026-10-28')
REGISTER = BASE / 'UAT_REGISTER.md'
ORG_ID = '00Daj00001Ae3iWEAR'
UI = ['finance_launch_context', 'test_drive_vehicle_picker', 'p7_batch1_ui',
      'vehicle_photo_header', 'p8_batch_b_ui', 'p8_batch_c_ui', 'p8_broker_ui']
QUERIES = {
    'identity': 'SELECT Id FROM Organization',
    'portal': "SELECT Id, Name, Status FROM Network WHERE Id = '0DBaj000006bf3xGAA'",
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def query_command(name):
    return ['sf', 'data', 'query', '--target-org', 'ng-demo', '--query', QUERIES[name], '--json']


def plan(batch):
    return {'reuse': [], 'local-ui': [['node', '--test', *[
        f'scripts/tests/{name}.test.mjs' for name in UI]]],
        'live-readonly': [query_command(name) for name in QUERIES]}[batch]


def coverage(text):
    """Keep every grouped checklist criterion verbatim; do not replace acceptance statuses."""
    section = text.split('## Complete feature checklist', 1)[1].split('## Consolidated defect', 1)[0]
    rows = []
    for line in section.splitlines():
        if not line.startswith('| P'):
            continue
        feature, status, remaining = [cell.strip() for cell in line.strip('|').split('|')]
        rows.append({'feature': feature, 'existingStatusAndScope': status,
                     'remainingAcceptance': remaining,
                     'automation': 'Reuse scoped receipts; no automatic acceptance upgrade',
                     'browserAssisted': 'Read-only actual-persona inspection where applicable',
                     'ownerOnly': 'Mutations, credentials, activation and final acceptance where applicable'})
    if {int(re.match(r'P(\d)', row['feature'])[1]) for row in rows} != set(range(1, 9)):
        raise ValueError('Incomplete phase coverage')
    return rows


def reuse(root):
    """Receipt integrity is distinct from the historical test outcome."""
    paths = ['execution_summary.json', 'raw/apex-test-run.json', 'triage/results.json',
             'triage/reconciliation.json', 'raw/local-ui-tests.tap', 'raw/cp2_quote.json',
             'raw/network.json', 'raw/source_parity.json']
    receipts = []
    for name in paths:
        path = root / BASE / name
        receipts.append({'path': str(BASE / name), 'sha256': digest(path)})
    summary = json.loads((root / BASE / 'execution_summary.json').read_text())['summary']
    counts = json.loads((root / BASE / 'triage/reconciliation.json').read_text())['counts']
    if summary['orgId'] != ORG_ID or summary['testRunId'] != '707aj00001OOD4U':
        raise ValueError('Unexpected historical org/run identity')
    if (summary['passing'], summary['failing'], summary['testsRan']) != (360, 10, 370):
        raise ValueError('Historical summary changed; owner review required')
    if counts['outcomes'] != {'Pass': 360, 'Fail': 10} or counts['total'] != 370:
        raise ValueError('Historical reconciliation changed; owner review required')
    tap = (root / BASE / 'raw/local-ui-tests.tap').read_text()
    if not all(re.search(rf'^# {key} {value}\s*$', tap, re.M) for key, value in
               [('tests', 48), ('pass', 48), ('fail', 0)]):
        raise ValueError('Historical local UI receipt changed')
    return {'status': 'PASS', 'scope': 'Historical receipt collection/consistency only',
            'receipts': receipts, 'historicalApex': summary,
            'historicalUatStatus': 'FAIL', 'openDefects': [f'D{i:02}' for i in range(1, 15)],
            'limits': 'Not a new test run, current source parity, browser PASS or phase acceptance'}


def execute_batch(batch, runner):
    steps = []
    commands = plan(batch)
    for index, command in enumerate(commands):
        try:
            result = runner(command)
            step = {'command': command, 'exitCode': result.returncode,
                    'stdout': result.stdout, 'stderr': result.stderr}
            steps.append(step)
            if result.returncode:
                return {'status': 'BLOCKED', 'reason': 'Command failed; stop and ask owner', 'steps': steps}
            if batch == 'live-readonly':
                payload = json.loads(result.stdout)
                records = payload['result']['records']
                if payload.get('status') != 0 or payload['result'].get('done') is not True:
                    raise ValueError('Incomplete/unsuccessful query response')
                if index == 0:
                    valid = len(records) == 1 and records[0].get('Id') == ORG_ID
                else:
                    valid = len(records) == 1 and records[0].get('Id') == '0DBaj000006bf3xGAA' and records[0].get('Status') == 'Live'
                if not valid:
                    return {'status': 'FAIL', 'reason': 'Identity/inventory assertion failed; stop', 'steps': steps}
            else:
                if not re.search(r'^# fail 0\s*$', result.stdout, re.M):
                    raise ValueError('Missing complete TAP success summary')
        except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
            return {'status': 'BLOCKED', 'reason': str(error), 'steps': steps}
    return {'status': 'PASS', 'steps': steps,
            'scope': 'Mocked local UI/state only' if batch == 'local-ui' else 'Admin identity/portal inventory only'}


def publish(root, run):
    path = (root / run).resolve()
    runs = (root / BASE / 'orchestration').resolve()
    if not path.is_relative_to(runs):
        raise ValueError('Only orchestration evidence inside this workspace may be published')
    data = json.loads((path / 'results.json').read_text())
    if data['batch'] not in ('reuse', 'local-ui', 'live-readonly') or data['status'] not in ('PASS', 'FAIL', 'BLOCKED'):
        raise ValueError('Invalid result')
    marker = f'<!-- orchestration:{path.name} -->'
    register = root / REGISTER
    text = register.read_text()
    if marker not in text:
        ref = str(path.relative_to(root))
        register.write_text(text + f'\n{marker}\n### Local orchestration receipt — {path.name}\n\n'
                            f'- Batch: `{data["batch"]}`; collection status: **{data["status"]}**.\n'
                            f'- Evidence: `{ref}/results.json`; `{ref}/coverage.json`.\n'
                            '- Existing feature/defect statuses and historical acceptances are unchanged.\n'
                            '- A collection PASS is not a full UAT PASS. No defect is auto-closed.\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['plan', 'run', 'publish'])
    parser.add_argument('--batch', choices=['reuse', 'local-ui', 'live-readonly'], default='reuse')
    parser.add_argument('--allow-readonly-org', action='store_true')
    parser.add_argument('--evidence', type=Path, help='Existing run directory for publish')
    args = parser.parse_args()
    if os.environ.get('SF_TARGET_ORG', 'ng-demo') != 'ng-demo':
        parser.error('ng-demo only; no default-org fallback')
    if args.action == 'publish':
        if not args.evidence:
            parser.error('publish requires --evidence')
        publish(ROOT, args.evidence)
        print(json.dumps({'status': 'PASS', 'scope': 'local register append only'}))
        return
    if args.action == 'plan':
        print(json.dumps({'batch': args.batch, 'commands': plan(args.batch), 'salesforceCallsPerformed': 0,
                          'note': 'reuse reads existing receipts only; run and publish are separate'}, indent=2))
        return
    if args.batch == 'live-readonly' and not args.allow_readonly_org:
        parser.error('live-readonly requires --allow-readonly-org; never use for persona acceptance')
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    dest = ROOT / BASE / 'orchestration' / stamp
    dest.mkdir(parents=True, exist_ok=False)
    try:
        rows = coverage((ROOT / REGISTER).read_text())
        data = reuse(ROOT) if args.batch == 'reuse' else execute_batch(args.batch, lambda command:
            subprocess.run(command, cwd=ROOT, env=dict(os.environ, SF_TARGET_ORG='ng-demo',
                           SF_DISABLE_TELEMETRY='true'), capture_output=True, text=True, timeout=120))
    except (OSError, ValueError, KeyError, TypeError) as error:
        rows = []
        data = {'status': 'BLOCKED', 'reason': str(error)}
    data.update(batch=args.batch, collectedAt=stamp, target='ng-demo',
                salesforceWrites=0, apexTestsRerun=0)
    (dest / 'results.json').write_text(json.dumps(data, indent=2) + '\n')
    (dest / 'coverage.json').write_text(json.dumps(rows, indent=2) + '\n')
    print(json.dumps({'status': data['status'], 'batch': args.batch,
                      'evidence': str(dest.relative_to(ROOT)), 'criteriaGroups': len(rows)}, indent=2))
    raise SystemExit(0 if data['status'] == 'PASS' else 1)


if __name__ == '__main__':
    main()
