"""Read-only scoped worktree checks. Attribution is always unknown; no Git writes or org calls."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OWNED = {
    'AGENTS.md', 'PLANS.md', 'docs/architecture/OVERVIEW.md', 'docs/decisions/STATUS.md',
    *('harness/' + name for name in [
        'BASELINE.md', 'REGRESSION_MATRIX.md', 'RUN_TEMPLATE.md', 'TRIAGE.md', 'VALIDATION.md',
        'check.sh', 'test_check.py', 'preservation.py', 'test_preservation.py']),
}
BASE = 'evidence/UAT/FULL_PROJECT_2026-10-28/'
RECEIPTS = ['execution_summary.json', 'raw/apex-test-run.json', 'triage/results.json',
            'triage/reconciliation.json', 'raw/local-ui-tests.tap', 'raw/cp2_quote.json',
            'raw/network.json', 'raw/source_parity.json', 'UAT_REGISTER.md']
UI = {
    'portal': ['p8_batch_b_ui', 'p8_batch_c_ui', 'p8_broker_ui'],
    'finance': ['finance_launch_context'],
    'inventory': ['test_drive_vehicle_picker', 'p7_batch1_ui', 'vehicle_photo_header'],
    'presentation': ['d08_quote_presentation', 'finance_launch_context'],
    'harness': [],
}
BUNDLES = {
    'portal': ['ownerPortal' + name for name in ['Home', 'Cases', 'History', 'Loyalty', 'Vehicles', 'Appointment']],
    'finance': ['financeApplication'],
    'inventory': ['testDriveVehiclePicker', 'inventoryGallery', 'opportunityCalculator', 'vehiclePhotoHeader'],
    'presentation': ['quoteSummary', 'financeApplication'],
}


def owned(path):
    # Unexpected files in the harness namespace cannot hide as unrelated additions.
    return path in OWNED or path.startswith('harness/')


def inventory(root):
    result = subprocess.run(['git', '-c', 'core.fsmonitor=false', 'ls-files', '--cached',
                             '--others', '--exclude-standard', '-z'], cwd=root,
                            capture_output=True, check=True)
    return set(filter(None, result.stdout.decode().split('\0')))


def fingerprint(root, name):
    path = root / name
    if not path.resolve().is_relative_to(root.resolve()):
        return {'kind': 'external-path'}
    try:
        before = path.lstat()
        if path.is_symlink():
            return {'kind': 'symlink'}
        if not path.is_file():
            return {'kind': 'non-file'}
        sha = hashlib.sha256(path.read_bytes()).hexdigest()
        after = path.lstat()
        identity = lambda s: (s.st_mtime_ns, s.st_ctime_ns, s.st_ino, s.st_size, s.st_mode)
        return {'kind': 'file', 'sha256': sha, 'identity': list(identity(after)),
                'unstable': identity(before) != identity(after)}
    except FileNotFoundError:
        return {'kind': 'missing'}
    except OSError as error:
        return {'kind': 'unreadable', 'error': str(error)}


def inputs(root, mode, area):
    """Explicit transitive file inputs; update when an allowlisted test starts reading more files."""
    required = set(OWNED)
    required.update(BASE + path for path in RECEIPTS)
    required.update('scripts/tests/' + name + '.py' for name in [
        'uat_orchestration_test', 'p7_regression', 'p7_regression_test', 'validate_p7_batch2',
        'd08_metadata_test'])
    required.add('scripts/uat/orchestrate.py')
    # Matrix and link checks claim existence only, not tested source content/parity.
    presence = set()
    for name in OWNED:
        if name.endswith('.md'):
            for link in re.findall(r'\]\(([^)]+)\)', (root / name).read_text()):
                if '://' not in link and not link.startswith('#'):
                    target = (Path(name).parent / link.split('#', 1)[0])
                    presence.add(str(target))
    matrix = (root / 'harness/REGRESSION_MATRIX.md').read_text()
    presence.update('force-app/main/default/classes/' + name + '.cls'
                    for name in re.findall(r'`([A-Za-z0-9_]+Test)`', matrix))
    presence.update('scripts/tests/' + name for name in
                    re.findall(r'`([A-Za-z0-9_]+\.(?:test\.mjs|py))`', matrix))
    areas = list(BUNDLES) if mode == 'full' else ([area] if mode == 'focused' else [])
    for selected in areas:
        required.update('scripts/tests/' + name + '.test.mjs' for name in UI[selected])
        for bundle in BUNDLES.get(selected, []):
            required.update(str(path.relative_to(root)) for path in
                            (root / 'force-app/main/default/lwc' / bundle).glob('*') if path.is_file())
    if 'inventory' in areas:
        required.update('force-app/main/default/' + path for path in [
            'flows/TestDrive_Book_Screen.flow-meta.xml',
            'objects/Vehicle__c/listViews/All_Vehicles.listView-meta.xml',
            'permissionsets/PS_Test_Drive_Booking.permissionset-meta.xml'])
    if mode == 'full' or area == 'presentation':
        # d08_metadata_test reads every path in this historical fingerprint receipt.
        receipt = BASE + 'D08_LOCAL/before_hashes.json'
        required.add(receipt)
        required.update(json.loads((root / receipt).read_text()))
        required.add('manifest/d08-presentation-local.xml')
        required.add('force-app/main/default/dashboards/NG_Sales/DM_Exec_OperationsOverview.dashboard-meta.xml')
        for obj in ['Financing__c', 'Trade_In__c', 'Delivery__c', 'Loyalty_Member__c',
                    'Loyalty_Transaction__c', 'Consent__c']:
            view = f'force-app/main/default/objects/{obj}/listViews/NG_Overview.listView-meta.xml'
            required.add(view)
            # Field metadata is checked for existence, not read by the test.
            text = (root / view).read_text()
            presence.update(f'force-app/main/default/objects/{obj}/fields/{field}.field-meta.xml'
                            for field in re.findall(r'<columns>(.*?)</columns>', text) if field != 'NAME')
    return required, presence


def snapshot(root, required=(), presence=()):
    required, presence = set(required), set(presence)
    paths = inventory(root) | required
    return {'files': {p: fingerprint(root, p) for p in sorted(paths)},
            'required': sorted(required),
            'presence': {p: (root / p).exists() for p in sorted(presence)}}


def compare(before, after, expected=None):
    """Validation freezes protected bytes; edit review permits exact declared owned hashes only."""
    expected = {} if expected is None else expected
    invalid = sorted(p for p in expected if not owned(p) or '..' in Path(p).parts or Path(p).is_absolute())
    conflicts, accepted, informational = [], [], []
    required = set(before.get('required', [])) | set(after.get('required', []))
    for path in sorted(before['files'].keys() | after['files'].keys() | expected.keys()):
        old = before['files'].get(path, {'kind': 'missing'})
        new = after['files'].get(path, {'kind': 'missing'})
        protected = owned(path) or path in required
        if path in expected and path not in invalid:
            actual = new.get('sha256') if new.get('kind') == 'file' else None
            valid_kind = new.get('kind') == ('missing' if expected[path] is None else 'file')
            if valid_kind and actual == expected[path] and not new.get('unstable'):
                accepted.append(path)
            else:
                conflicts.append({'path': path, 'reason': 'intended harness fingerprint mismatch'})
        elif protected and (old != new or new.get('kind') != 'file' or new.get('unstable')):
            conflicts.append({'path': path, 'reason': 'protected file/input changed or unavailable'})
        elif old != new:
            informational.append({'path': path, 'attribution': 'unknown', 'status': 'INFO'})
    for path in sorted(before.get('presence', {}).keys() | after.get('presence', {}).keys()):
        if not before.get('presence', {}).get(path) or not after.get('presence', {}).get(path):
            conflicts.append({'path': path, 'reason': 'required inventory/link target missing'})
    conflicts.extend({'path': p, 'reason': 'expected edit outside harness scope'} for p in invalid)
    return {'status': 'FAIL' if conflicts else 'PASS', 'conflicts': conflicts,
            'acceptedHarnessEdits': accepted, 'informationalChanges': informational,
            'attribution': 'unknown', 'requiredInputCount': len(required),
            'limitation': 'Endpoint fingerprints are not an atomic snapshot or writer attribution; '
                          'results apply only to recorded inputs at this interval. No automatic retries.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='action', required=True)
    capture = sub.add_parser('capture')
    capture.add_argument('--output', type=Path, required=True)
    capture.add_argument('--mode', choices=['fast', 'focused', 'full'], required=True)
    capture.add_argument('--area', choices=list(UI), default='harness')
    verify = sub.add_parser('verify')
    verify.add_argument('--snapshot', type=Path, required=True)
    edits = sub.add_parser('edits')
    edits.add_argument('--before', type=Path, required=True, help='Pre-edit flat path -> SHA256/null snapshot')
    edits.add_argument('--expected', type=Path, required=True, help='Reviewed intended harness path -> SHA256/null')
    args = parser.parse_args()
    try:
        if args.action == 'capture':
            required, presence = inputs(ROOT, args.mode, args.area)
            data = snapshot(ROOT, required, presence)
            result = compare(data, data)
            if result['status'] == 'PASS':
                # Exclusive replacement is limited to an operator-provided empty temporary file.
                if not args.output.is_file() or args.output.stat().st_size:
                    raise ValueError('--output must be an existing empty temporary file outside the repository')
                if args.output.resolve().is_relative_to(ROOT):
                    raise ValueError('snapshot must be outside the repository')
                args.output.write_text(json.dumps(data, sort_keys=True))
            print(json.dumps({'status': result['status'], 'requiredInputCount': len(required),
                              'conflicts': result['conflicts']}, indent=2))
        elif args.action == 'verify':
            before = json.loads(args.snapshot.read_text())
            after = snapshot(ROOT, before['required'], before['presence'])
            result = compare(before, after)
            print(json.dumps(result, indent=2))
        else:
            flat = json.loads(args.before.read_text())
            before = {'files': {p: {'kind': 'file', 'sha256': sha} if sha else {'kind': 'missing'}
                                for p, sha in flat.items()}}
            # Content-only task diff; validation intervals additionally compare file identity/times.
            after = snapshot(ROOT)
            after['files'] = {p: {k: v for k, v in state.items() if k in ('kind', 'sha256')}
                              for p, state in after['files'].items()}
            result = compare(before, after, json.loads(args.expected.read_text()))
            print(json.dumps(result, indent=2))
        return 0 if result['status'] == 'PASS' else 1
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(json.dumps({'status': 'FAIL', 'error': str(error), 'attribution': 'unknown'}))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
