#!/usr/bin/env bash
# Offline, allowlisted validation only. No Salesforce or Git write commands.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PYTHONDONTWRITEBYTECODE=1

usage() {
  echo 'Usage: bash harness/check.sh [fast | focused {harness|portal|finance|inventory|presentation} | full]'
  echo 'All modes are local only; full does not mean Salesforce/release acceptance.'
}
mode="${1:-fast}"
area='harness'
case "$mode" in
  --help|-h) [[ $# -eq 1 ]] || { usage; exit 2; }; usage; exit 0 ;;
  fast|full) [[ $# -le 1 ]] || { usage; exit 2; } ;;
  focused)
    [[ $# -eq 2 ]] || { usage; exit 2; }
    area="$2"
    case "$area" in harness|portal|finance|inventory|presentation) ;; *) usage; exit 2 ;; esac ;;
  *) usage; exit 2 ;;
esac
if ! command -v python3 >/dev/null 2>&1; then
  echo 'SKIPPED: required Python 3.10+ unavailable; local validation incomplete'
  exit 2
fi
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)'; then
  echo 'SKIPPED: required Python 3.10+ unavailable; local validation incomplete'
  exit 2
fi
run() {
  local label="$1"
  shift
  echo "CHECK: $label"
  if "$@"; then
    echo "PASS: $label"
  else
    local code=$?
    echo "FAIL: $label (exit $code); stop and follow harness/TRIAGE.md"
    exit 1
  fi
}
echo "LOCAL ONLY: mode=$mode focus=$area"
state="$(mktemp "${TMPDIR:-/private/var/folders/82/d8xptlz976z981kdf1yg_k3c0000gn/T/opencode}/northgate-preservation.XXXXXX")"
# Remove only this invocation's temporary snapshot, never repository files.
trap 'rm -f "$state"' EXIT
run 'capture scoped validation inputs (read-only worktree)' python3 harness/preservation.py capture --output "$state" --mode "$mode" --area "$area"
run 'entry-point Bash syntax' bash -n harness/check.sh
run 'harness structure, links, syntax and existing receipt consistency' python3 - <<'PY'
import ast
import importlib.util
from pathlib import Path
import re

docs = ['AGENTS.md', 'PLANS.md', 'docs/architecture/OVERVIEW.md', 'docs/decisions/STATUS.md',
        'harness/BASELINE.md', 'harness/REGRESSION_MATRIX.md', 'harness/RUN_TEMPLATE.md',
        'harness/TRIAGE.md', 'harness/VALIDATION.md']
for name in docs:
    path = Path(name)
    text = path.read_text()
    if not text.strip():
        raise ValueError(f'Empty required document: {name}')
    for link in re.findall(r'\]\(([^)]+)\)', text):
        if '://' not in link and not link.startswith('#'):
            target = link.split('#', 1)[0]
            if not (path.parent / target).exists():
                raise ValueError(f'Broken local link: {name} -> {link}')
print(f'Required documents and local links: {len(docs)} checked')
matrix = Path('harness/REGRESSION_MATRIX.md').read_text()
apex = set(re.findall(r'`([A-Za-z0-9_]+Test)`', matrix))
local = set(re.findall(r'`([A-Za-z0-9_]+\.(?:test\.mjs|py))`', matrix))
for name in apex:
    if not (Path('force-app/main/default/classes') / (name + '.cls')).is_file():
        raise ValueError(f'Matrix references missing Apex test: {name}')
for name in local:
    if not (Path('scripts/tests') / name).is_file():
        raise ValueError(f'Matrix references missing local test: {name}')
print(f'Matrix inventory: {len(apex)} Apex and {len(local)} local test files exist (not execution proof)')
for name in ['scripts/uat/orchestrate.py', 'scripts/tests/uat_orchestration_test.py',
             'scripts/tests/p7_regression.py', 'scripts/tests/p7_regression_test.py',
             'scripts/tests/d08_metadata_test.py', 'harness/test_check.py',
             'harness/preservation.py', 'harness/test_preservation.py']:
    ast.parse(Path(name).read_text(), filename=name)
print('Python source syntax: 8 checked; no bytecode written')
spec = importlib.util.spec_from_file_location('northgate_existing_uat', 'scripts/uat/orchestrate.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
result = module.reuse(Path.cwd())
rows = module.coverage((Path.cwd() / module.REGISTER).read_text())
if result['status'] != 'PASS':
    raise ValueError('Existing receipt consistency failed')
print(f"Receipt consistency: {result['status']}; {len(result['receipts'])} receipts; {len(rows)} criterion groups")
print(f"Historical Apex: {result['historicalApex']['passing']} Pass / {result['historicalApex']['failing']} Fail; NOT rerun")
print(f"Historical UAT: {result['historicalUatStatus']}; no acceptance upgrade")
PY
run 'existing offline UAT orchestration guards' python3 scripts/tests/uat_orchestration_test.py
run 'existing offline regression runner guards' python3 scripts/tests/p7_regression_test.py
run 'entry-point safety contract (offline)' python3 harness/test_check.py
run 'scoped concurrent-worktree preservation contracts (offline)' python3 harness/test_preservation.py

ui=()
if [[ "$mode" == full ]]; then
  ui=(finance_launch_context test_drive_vehicle_picker p7_batch1_ui vehicle_photo_header p8_batch_b_ui p8_batch_c_ui p8_broker_ui d08_quote_presentation)
elif [[ "$mode" == focused ]]; then
  case "$area" in
    portal) ui=(p8_batch_b_ui p8_batch_c_ui p8_broker_ui) ;;
    finance) ui=(finance_launch_context) ;;
    inventory) ui=(test_drive_vehicle_picker p7_batch1_ui vehicle_photo_header) ;;
    presentation) ui=(d08_quote_presentation finance_launch_context) ;;
  esac
fi
if [[ ${#ui[@]} -gt 0 ]]; then
  if ! command -v node >/dev/null 2>&1; then
    echo 'SKIPPED: selected UI checks; installed Node 22+ required (no install attempted)'
  elif ! node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 22 ? 0 : 1)'; then
    echo 'SKIPPED: selected UI checks; installed Node is below project requirement 22+'
  else
    files=()
    for suite in "${ui[@]}"; do files+=("scripts/tests/$suite.test.mjs"); done
    run 'selected existing local UI mocks/static checks (not browser)' node --test "${files[@]}"
  fi
else
  echo 'SKIPPED: local UI checks not selected; use focused AREA or full'
fi
if [[ "$mode" == full || "$area" == presentation ]]; then
  run 'existing D08 local metadata checks (not server validation)' python3 scripts/tests/d08_metadata_test.py
else
  echo 'SKIPPED: presentation metadata checks not selected'
fi
echo 'SKIPPED: Salesforce CLI/auth/org availability not probed; no org access authorized'
echo 'SKIPPED: Apex, metadata dry-run, strict DQ, browser/persona acceptance; separately gated'
echo 'SKIPPED: deployment, data/configuration changes and Git writes; never performed by this entry point'
run 'scoped preservation; unrelated drift is informational, attribution unknown' python3 harness/preservation.py verify --snapshot "$state"
echo 'PASS: selected available LOCAL checks only; review SKIPPED lines. Full project acceptance remains BLOCKED.'
