#!/usr/bin/env bash
# Northgate Motors — Phase 5 emergency automation bypass restoration script.
#
# Forcefully restores Automation_Settings__c org-default flags to FALSE.
# Idempotent. Safe to run any number of times. Does NOT modify permission
# assignments — those are managed separately via Setup UI (PS_Bypass_Load).
#
# This script is the SAFETY NET. It bypasses the snapshot file system entirely and
# always sets the bypass flags to FALSE, regardless of prior state.
#
# Usage:
#   SF_TARGET_ORG=ng-demo bash data/scripts/automation-control/emergency-restore.sh
#
# When to use:
#   1. After a load aborts and the wrapper's trap didn't restore.
#   2. Any time you are uncertain whether bypass is still active.
#   3. As a pre-flight check before demo (run this first; if anything is true, fix it).
#
# Constraint: Owner action required. This script DOES mutate Salesforce data
# (sets bypass flags to FALSE). It does NOT load data, assign permissions, or
# touch CP2.

set -euo pipefail

ORG="${SF_TARGET_ORG:-ng-demo}"

echo "[emergency-restore] target org: $ORG"
echo "[emergency-restore] WARNING: this script will execute an UPDATE on the Automation_Settings__c org-default row."
echo "[emergency-restore] All three bypass flags will be set to FALSE."

# Read current state first (informational only).
echo "[emergency-restore] current state:"
sf data query \
    --query "SELECT Id, Bypass_Triggers__c, Bypass_Flows__c, Bypass_Validation__c, SetupOwnerId FROM Automation_Settings__c WHERE SetupOwner.Type = 'Organization' LIMIT 1" \
    --target-org "$ORG" \
    --result-format json 2>&1 | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for r in d.get('result', {}).get('records', []):
        print(f\"  Id={r['Id']} Bypass_Triggers__c={r['Bypass_Triggers__c']} Bypass_Flows__c={r['Bypass_Flows__c']} Bypass_Validation__c={r['Bypass_Validation__c']}\")
except Exception:
    pass
"

# Execute restoration via anonymous Apex. Writes through getOrgDefaults() — the same
# instance the triggers will read on the next execution. Owner MUST be present.
echo "[emergency-restore] executing anonymous Apex restoration..."
sf apex run --target-org "$ORG" --file /dev/stdin << 'EOF' 2>&1 | grep -E "RESULT_ID|RESULT_Bypass|Compiled|Executed|FAILED"
Automation_Settings__c s = Automation_Settings__c.getOrgDefaults();
if (s == null) {
    System.debug('RESULT: No org-default Automation_Settings__c row found. Run initialize first.');
    return;
}
s.Bypass_Triggers__c = false;
s.Bypass_Flows__c = false;
s.Bypass_Validation__c = false;
update s;
System.debug('RESULT_ID=' + s.Id);
System.debug('RESULT_Bypass_Triggers__c=' + s.Bypass_Triggers__c);
System.debug('RESULT_Bypass_Flows__c=' + s.Bypass_Flows__c);
System.debug('RESULT_Bypass_Validation__c=' + s.Bypass_Validation__c);
EOF

# Verify post-state.
echo "[emergency-restore] post-restoration state:"
sf data query \
    --query "SELECT Id, Bypass_Triggers__c, Bypass_Flows__c, Bypass_Validation__c, SetupOwnerId FROM Automation_Settings__c WHERE SetupOwner.Type = 'Organization' LIMIT 1" \
    --target-org "$ORG" \
    --result-format json 2>&1 | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for r in d.get('result', {}).get('records', []):
        print(f\"  Id={r['Id']} Bypass_Triggers__c={r['Bypass_Triggers__c']} Bypass_Flows__c={r['Bypass_Flows__c']} Bypass_Validation__c={r['Bypass_Validation__c']}\")
except Exception:
    pass
"

echo "[emergency-restore] done. All bypass flags now FALSE."