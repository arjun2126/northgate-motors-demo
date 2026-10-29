#!/usr/bin/env bash
# Northgate Motors — Phase 5 confirmed-state verifier (read-only).
#
# Asserts that Automation_Settings__c org-default flags are all FALSE.
# Prints PASS/FAIL with the actual values. Does NOT mutate Salesforce data.
#
# Usage:
#   SF_TARGET_ORG=ng-demo bash data/scripts/automation-control/verify-bypass-off.sh
#
# Exit code:
#   0  if all three flags are FALSE (safe)
#   1  if any flag is TRUE (UNSAFE — bypass is active)
#   2  if no org-default row found
#
# Constraints honored:
#   - No DML
#   - No permission assignments
#   - Read-only

set -uo pipefail

ORG="${SF_TARGET_ORG:-ng-demo}"
echo "[verify] target org: $ORG"

# Resolve organization Id for exact-match query (SetupOwnerId is polymorphic Id; LIKE not allowed).
ORG_ID="$(sf data query --query "SELECT Id FROM Organization LIMIT 1" --target-org "$ORG" --result-format json 2>/dev/null \
    | python3 -c "import sys,json; raw=sys.stdin.read(); d=json.loads(raw); print(d['result']['records'][0]['Id'])")"
if [ -z "$ORG_ID" ]; then
    echo "[verify] ERROR: cannot resolve Organization Id"
    exit 2
fi

RESULT="$(sf data query \
    --query "SELECT Id, Bypass_Triggers__c, Bypass_Flows__c, Bypass_Validation__c, SetupOwnerId FROM Automation_Settings__c WHERE SetupOwnerId = '${ORG_ID}' LIMIT 1" \
    --target-org "$ORG" \
    --result-format json 2>&1)"

echo "$RESULT" | python3 -c "
import sys, json
raw = sys.stdin.read()
try:
    d = json.loads(raw)
except Exception:
    print('[verify] parse error')
    sys.exit(1)
records = d.get('result', {}).get('records', [])
if not records:
    print('[verify] FAIL: no org-default Automation_Settings__c row')
    sys.exit(2)
r = records[0]
flags = {
    'Bypass_Triggers__c': r['Bypass_Triggers__c'],
    'Bypass_Flows__c': r['Bypass_Flows__c'],
    'Bypass_Validation__c': r['Bypass_Validation__c'],
}
print('[verify] Id:                  ' + r['Id'])
print('[verify] SetupOwnerId:        ' + r['SetupOwnerId'])
print('[verify] Bypass_Triggers__c: ' + str(flags['Bypass_Triggers__c']))
print('[verify] Bypass_Flows__c:    ' + str(flags['Bypass_Flows__c']))
print('[verify] Bypass_Validation__c: ' + str(flags['Bypass_Validation__c']))
if all(v is False for v in flags.values()):
    print('[verify] PASS: all bypass flags FALSE (safe)')
    sys.exit(0)
else:
    print('[verify] FAIL: at least one bypass flag is TRUE (UNSAFE)')
    sys.exit(1)
"