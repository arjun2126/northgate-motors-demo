"""Fixed ng-demo regression gate; plan by default, no deploy/repair/reset/assignment operation."""
import argparse
import json
import math
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from validate_p7_batch2 import TESTS

ROOT = Path(__file__).resolve().parents[2]


def commands(storage_mb=None, storage_evidence=None):
    identity = ['sf', 'data', 'query', '--target-org', 'ng-demo', '--query', 'SELECT Id FROM Organization', '--json']
    base = ['sf', 'project', 'deploy', 'start', '--dry-run', '--target-org', 'ng-demo']
    prompt = base + ['--manifest', 'manifest/p7-batch3-check.xml', '--test-level', 'NoTestRun', '--wait', '10', '--json']
    regression = base + ['--manifest', 'manifest/p7-batch2-check.xml', '--test-level', 'RunSpecifiedTests',
                         '--tests', *TESTS, '--wait', '10', '--json']
    dq = ['bash', 'scripts/verify.sh', '--storage-mb', str(storage_mb) if storage_mb is not None else '<observed-MB>',
          '--storage-evidence', str(storage_evidence) if storage_evidence else '<workspace-evidence-file>']
    return [identity, prompt, regression, dq]


def sanitized(value):
    if isinstance(value, dict):
        return {key: sanitized(item) for key, item in value.items()
                if key not in {'createdByName', 'accessToken', 'refreshToken', 'username'}}
    if isinstance(value, list):
        return [sanitized(item) for item in value]
    return value.replace(str(ROOT) + '/', '').replace(str(ROOT), '.') if isinstance(value, str) else value


def execute(selected, executor):
    evidence = []
    for index, command in enumerate(selected):
        result = executor(command)
        try:
            payload = json.loads(result.stdout)
        except ValueError:
            payload = {'unparsedOutput': result.stdout}
        evidence.append({'command': command, 'exitCode': result.returncode,
                         'output': sanitized(payload), 'stderr': sanitized(result.stderr)})
        if result.returncode:
            return {'status': 'FAILED', 'failedStep': index + 1, 'steps': evidence}
        if not isinstance(payload, dict):
            return {'status': 'FAILED', 'failedStep': index + 1, 'reason': 'Unexpected JSON shape', 'steps': evidence}
        if index < 3 and not isinstance(payload.get('result'), dict):
            return {'status': 'FAILED', 'failedStep': index + 1, 'reason': 'Unexpected result shape', 'steps': evidence}
        if index == 0:
            records = payload.get('result', {}).get('records', [])
            valid = (payload.get('status') == 0 and isinstance(records, list) and len(records) == 1
                     and isinstance(records[0], dict) and records[0].get('Id') == '00Daj00001Ae3iWEAR')
        elif index in [1, 2]:
            deploy = payload.get('result', {})
            valid = payload.get('status') == 0 and deploy.get('checkOnly') is True and deploy.get('status') == 'Succeeded'
            valid = valid and deploy.get('numberComponentErrors') == 0 and deploy.get('numberTestErrors') == 0
            if index == 2:
                total = deploy.get('numberTestsTotal')
                valid = valid and isinstance(total, int) and total >= 235 and deploy.get('numberTestsCompleted') == total
        else:
            valid = payload.get('passed') is True
        if not valid:
            return {'status': 'FAILED', 'failedStep': index + 1, 'reason': 'Unexpected or incomplete gate result', 'steps': evidence}
    return {'status': 'PASS', 'steps': evidence}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--run', action='store_true')
    mode.add_argument('--plan', action='store_true')
    parser.add_argument('--storage-mb', type=float)
    parser.add_argument('--storage-evidence', type=Path)
    args = parser.parse_args()
    if os.environ.get('SF_TARGET_ORG', 'ng-demo') != 'ng-demo':
        parser.error('ng-demo only')
    if args.run:
        if args.storage_mb is None or not math.isfinite(args.storage_mb) or args.storage_mb < 0:
            parser.error('--run requires a finite nonnegative observed --storage-mb')
        if args.storage_evidence is None or not args.storage_evidence.is_file():
            parser.error('--run requires an existing --storage-evidence file')
        path = args.storage_evidence.resolve()
        if not path.is_relative_to(ROOT):
            parser.error('storage evidence must be inside this workspace')
        args.storage_evidence = path.relative_to(ROOT)
    selected = commands(args.storage_mb, args.storage_evidence)
    if not args.run:
        print(json.dumps({'mode': 'PLAN ONLY', 'commands': selected, 'orgCallsPerformed': 0,
                          'note': 'Full gate repeats tests only when explicitly requested; accepted DQ exceptions still fail strict criteria.'}, indent=2))
        return
    env = dict(os.environ, SF_TARGET_ORG='ng-demo')
    result = execute(selected, lambda command: subprocess.run(command, cwd=ROOT, env=env, text=True, capture_output=True))
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    path = ROOT / 'evidence/P7' / ('REGRESSION_' + stamp + '.json')
    path.write_text(json.dumps(sanitized(result), indent=2) + '\n')
    print(json.dumps({'status': result['status'], 'failedStep': result.get('failedStep'),
                      'evidence': str(path.relative_to(ROOT))}, indent=2))
    raise SystemExit(0 if result['status'] == 'PASS' else 1)


if __name__ == '__main__':
    main()
