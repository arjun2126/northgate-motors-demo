#!/usr/bin/env bash
# Northgate Motors — Phase 5 automation bypass capture script (read-only).
#
# Captures the current Automation_Settings__c org-default row state (the three
# bypass flags) into a timestamped JSON file under data/automation-snapshots/.
# Does NOT mutate Salesforce data. Safe to run any number of times.
#
# Usage:
#   SF_TARGET_ORG=ng-demo bash data/scripts/automation-control/capture.sh
#
# Output:
#   data/automation-snapshots/<UTC-timestamp>-bypass-state.json
#
# Constraints honored:
#   - No DML (only SELECT via sf data query + Tooling)
#   - No permission assignments
#   - No bypass toggling

set -euo pipefail

ORG="${SF_TARGET_ORG:-ng-demo}"
SNAP_DIR="$(dirname "$0")/../../automation-snapshots"
mkdir -p "$SNAP_DIR"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$SNAP_DIR/${TS}-bypass-state.json"

echo "[capture] target org:        $ORG"
echo "[capture] snapshot file:     $OUT"

# Read current state via SOQL.
RAW="$(sf data query \
    --query "SELECT Id, SetupOwnerId, Bypass_Triggers__c, Bypass_Flows__c, Bypass_Validation__c, CreatedDate, LastModifiedDate FROM Automation_Settings__c ORDER BY CreatedDate ASC" \
    --target-org "$ORG" \
    --result-format json 2>&1)"

TOTAL="$(printf '%s' "$RAW" | python3 -c 'import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get("result",{}).get("totalSize",0))
except Exception:
    print(-1)')"

if [ "$TOTAL" = "0" ]; then
    echo "[capture] WARNING: no Automation_Settings__c rows present in $ORG."
    echo "[capture] Run initialize-automation-settings first."
    exit 0
fi

# Wrap into a stable envelope and write.
printf '%s' "$RAW" | python3 -c "
import sys, json, datetime
raw = json.load(sys.stdin)
records = raw.get('result', {}).get('records', [])
# Org-default row has SetupOwnerId = Organization Id (starts with '00D').
defaults = [r for r in records if r.get('SetupOwnerId', '').startswith('00D')]
out = {
    'captured_at_utc': datetime.datetime.utcnow().isoformat() + 'Z',
    'target_org': '$ORG',
    'total_records': len(records),
    'org_default_present': bool(defaults),
    'org_default': defaults[0] if defaults else None,
}
with open('$OUT', 'w') as f:
    json.dump(out, f, indent=2)
print('[capture] wrote:', '$OUT')
print('[capture] current flag values:')
for k in ('Bypass_Triggers__c', 'Bypass_Flows__c', 'Bypass_Validation__c'):
    v = (defaults[0].get(k) if defaults else None)
    print(f'  {k:25s} = {v}')
"

echo "[capture] done."