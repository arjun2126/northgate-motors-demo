#!/usr/bin/env bash
# Northgate Motors — Phase 5 loader wrapper with wrapper-managed bypass-toggle.
#
# Wraps data/scripts/load.ts execution in a state machine:
#   - Detects --execute vs read-only modes.
#   - For --execute: captures pre-toggle state, builds restoration procedure,
#     registers cleanup handlers, enables bypass flags, runs the loader,
#     verifies restoration on completion. Restores bypass on any exit (success/
#     failure/signal) via trap.
#   - For read-only modes: no bypass toggle, no snapshot, no trap.
#
# Usage:
#   SF_TARGET_ORG=ng-demo bash data/scripts/automation-control/load-wrapper.sh --dry-run
#   SF_TARGET_ORG=ng-demo bash data/scripts/automation-control/load-wrapper.sh --validate
#   NG_LOAD_AUTHORIZED=1 SF_TARGET_ORG=ng-demo bash data/scripts/automation-control/load-wrapper.sh --execute
#
# SAFETY MODEL (--execute), strictly ordered:
#   1. Verify target org is ng-demo (refuse otherwise).
#   2. Capture original Automation_Settings__c values.
#   3. Generate restoration procedure (Apex script written to file).
#   4. Register EXIT/INT/TERM cleanup handlers (restore_bypass trap).
#   5. Only then enable Bypass_Triggers__c via Apex UPDATE.
#   6. Execute the loader.
#   7. Trap fires on exit (success or failure): restoration procedure runs.
#   8. Verify restoration succeeded (re-read flags, compare to snapshot) and
#      report failure if not.
#
# CRITICAL: restoration procedure (step 3) and trap (step 4) MUST be set up
# BEFORE bypass toggle (step 5). If toggle happens first and anything between
# toggle and trap fails (e.g., disk full, python crash), bypass is enabled but
# no automatic restoration runs — bypass stays on. This wrapper's order avoids
# that hazard.
#
# For --validate, --dry-run, --resolve (no --execute flag), NO snapshot is
# captured, NO bypass toggle, NO restoration. These modes do not perform
# Salesforce DML.
#
# Bypass window bounded by wrapper: the only entity that enables bypass is the
# wrapper itself, in the same shell session as the loader execution. SIGKILL or
# power loss between toggle and trap leaves bypass TRUE; emergency-restore.sh
# is the recovery path.

set -uo pipefail

ORG="${SF_TARGET_ORG:-ng-demo}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SNAP_DIR="$ROOT_DIR/data/automation-snapshots"
LOG_DIR="$ROOT_DIR/data/automation-control/logs"
APEX_DIR="$ROOT_DIR/data/automation-control/apex"

mkdir -p "$SNAP_DIR" "$LOG_DIR" "$APEX_DIR"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
SNAP="$SNAP_DIR/${TS}-pre-wrapper-bypass.json"
LOG="$LOG_DIR/${TS}-wrapper.log"
RESTORE_APEX="$APEX_DIR/restore-${TS}.apex"

echo "[wrapper] target org:     $ORG" | tee -a "$LOG"
echo "[wrapper] snapshot file:  $SNAP" | tee -a "$LOG"
echo "[wrapper] log file:       $LOG" | tee -a "$LOG"
echo "[wrapper] args:           $*" | tee -a "$LOG"

# Safety guard #1: target org must be ng-demo.
if [ "$ORG" != "ng-demo" ]; then
    echo "[wrapper] REFUSED: target org is '$ORG', expected 'ng-demo'. Aborting before any mutation." | tee -a "$LOG"
    exit 4
fi

# Determine mode. Only --execute triggers capture + toggle + restoration.
WRAPPER_MODE="read-only"
for a in "$@"; do
    if [ "$a" = "--execute" ]; then
        WRAPPER_MODE="execute"
        break
    fi
done
echo "[wrapper] detected mode: $WRAPPER_MODE (args: $*)" | tee -a "$LOG"

# Helper: extract Organization Id once.
fetch_org_id() {
    sf data query --query "SELECT Id FROM Organization LIMIT 1" --target-org "$ORG" --result-format json 2>/dev/null \
        | python3 -c "import sys,json
raw=sys.stdin.read()
try:
    d=json.loads(raw)
    print(d['result']['records'][0]['Id'])
except Exception:
    pass"
}

if [ "$WRAPPER_MODE" = "execute" ]; then
    # Step 2 — Capture original Automation_Settings__c values.
    echo "[wrapper] step 2: capturing Automation_Settings__c state (pre-toggle)..." | tee -a "$LOG"
    ORG_ID="$(fetch_org_id)"
    if [ -z "$ORG_ID" ]; then
        echo "[wrapper] ERROR: cannot resolve Organization Id" | tee -a "$LOG"
        exit 2
    fi
    RAW="$(sf data query \
        --query "SELECT Id, SetupOwnerId, Bypass_Triggers__c, Bypass_Flows__c, Bypass_Validation__c, CreatedDate, LastModifiedDate FROM Automation_Settings__c WHERE SetupOwnerId = '${ORG_ID}' LIMIT 1" \
        --target-org "$ORG" \
        --result-format json 2>&1)" || {
        echo "[wrapper] ERROR: failed to capture state." | tee -a "$LOG"
        exit 2
    }

    printf '%s' "$RAW" | python3 -c "
import sys, json, datetime
raw = json.load(sys.stdin)
recs = raw.get('result', {}).get('records', [])
if not recs:
    raise SystemExit('No org-default Automation_Settings__c row found. Run initialize first.')
r = recs[0]
out = {
    'captured_at_utc': datetime.datetime.utcnow().isoformat() + 'Z',
    'target_org': '$ORG',
    'id': r['Id'],
    'setup_owner_id': r['SetupOwnerId'],
    'bypass_triggers_c': r['Bypass_Triggers__c'],
    'bypass_flows_c': r['Bypass_Flows__c'],
    'bypass_validation_c': r['Bypass_Validation__c'],
}
with open('$SNAP', 'w') as f:
    json.dump(out, f, indent=2)
print('[wrapper] captured flags: T=' + str(out['bypass_triggers_c']) + ' F=' + str(out['bypass_flows_c']) + ' V=' + str(out['bypass_validation_c']))
print('[wrapper] snapshot written: $SNAP')
" 2>&1 | tee -a "$LOG"

    # Step 3 — Generate restoration Apex script (using snapshot values).
    echo "[wrapper] Step 3: generating restoration Apex script..." | tee -a "$LOG"
    python3 - "$SNAP" "$RESTORE_APEX" << 'PY' 2>&1 | tee -a "$LOG"
import json, sys
snap = json.load(open(sys.argv[1]))
path = sys.argv[2]
def b(v): return 'true' if v else 'false'
apex = f"""// Auto-generated restoration Apex. Source: {snap['captured_at_utc']}
// Target org: {snap['target_org']}
// Id: {snap['id']}
Automation_Settings__c s = Automation_Settings__c.getOrgDefaults();
if (s != null) {{
    s.Bypass_Triggers__c   = {b(snap['bypass_triggers_c'])};
    s.Bypass_Flows__c      = {b(snap['bypass_flows_c'])};
    s.Bypass_Validation__c = {b(snap['bypass_validation_c'])};
    update s;
    System.debug('RESTORE_ID=' + s.Id);
    System.debug('RESTORE_Bypass_Triggers__c=' + s.Bypass_Triggers__c);
    System.debug('RESTORE_Bypass_Flows__c=' + s.Bypass_Flows__c);
    System.debug('RESTORE_Bypass_Validation__c=' + s.Bypass_Validation__c);
}} else {{
    System.debug('RESTORE_RESULT: no Automation_Settings__c row');
}}
"""
with open(path, 'w') as f:
    f.write(apex)
print(f"[wrapper] restoration Apex script written: {path}")
PY
    if [ ! -f "$RESTORE_APEX" ]; then
        echo "[wrapper] ERROR: failed to write restoration Apex script at $RESTORE_APEX" | tee -a "$LOG"
        exit 5
    fi

    # Step 4 — Register cleanup handlers. These fire on script exit (any reason).
    LOAD_RC_GUARD=0
    restore_bypass() {
        local rc=${LOAD_RC_GUARD}
        echo "[wrapper] trap triggered (loader exit code $rc). Restoring Automation_Settings__c..." | tee -a "$LOG"
        if [ ! -f "$RESTORE_APEX" ]; then
            echo "[wrapper] WARN: restoration Apex script not found; manual recovery may be needed via emergency-restore.sh" | tee -a "$LOG"
            exit $rc
        fi
        RESTORE_OUT="$(sf apex run --target-org "$ORG" --file "$RESTORE_APEX" 2>&1)"
        RESTORE_RC=$?
        echo "$RESTORE_OUT" | grep -E "RESTORE_|Compiled|Executed|FAILED" | tee -a "$LOG" || true
        # Critical: if restoration fails, the wrapper must report failure (not exit $rc=0).
        if [ "$RESTORE_RC" -ne 0 ] || ! echo "$RESTORE_OUT" | grep -q "RESTORE_ID="; then
            echo "[wrapper] ERROR: restoration Apex failed (rc=$RESTORE_RC). Manual recovery required via emergency-restore.sh." | tee -a "$LOG"
            exit 6
        fi
        # Step 8 — Verify restoration actually set values back to captured snapshot.
        echo "[wrapper] step 8: verifying restoration succeeded..." | tee -a "$LOG"
        VERIFY_OUT="$(sf data query \
            --query "SELECT Bypass_Triggers__c, Bypass_Flows__c, Bypass_Validation__c FROM Automation_Settings__c WHERE SetupOwnerId = '${ORG_ID}' LIMIT 1" \
            --target-org "$ORG" \
            --result-format json 2>&1)"
        echo "$VERIFY_OUT" | python3 -c "
import sys, json
raw = sys.stdin.read()
snap = json.load(open('$SNAP'))
try:
    d = json.loads(raw)
    recs = d.get('result', {}).get('records', [])
    if not recs:
        print('[wrapper] VERIFY_FAILED: no Automation_Settings__c row found post-restoration')
        sys.exit(1)
    cur = recs[0]
    ok = (cur['Bypass_Triggers__c'] == snap['bypass_triggers_c'] and
          cur['Bypass_Flows__c'] == snap['bypass_flows_c'] and
          cur['Bypass_Validation__c'] == snap['bypass_validation_c'])
    if ok:
        print('[wrapper] VERIFY_OK: bypass flags restored to snapshot values (T=' + str(cur['Bypass_Triggers__c']) + ' F=' + str(cur['Bypass_Flows__c']) + ' V=' + str(cur['Bypass_Validation__c']) + ')')
        sys.exit(0)
    else:
        print('[wrapper] VERIFY_FAILED: current values T=' + str(cur['Bypass_Triggers__c']) + ' F=' + str(cur['Bypass_Flows__c']) + ' V=' + str(cur['Bypass_Validation__c']) + ' do NOT match snapshot (T=' + str(snap['bypass_triggers_c']) + ' F=' + str(snap['bypass_flows_c']) + ' V=' + str(snap['bypass_validation_c']) + '). Run emergency-restore.sh.')
        sys.exit(1)
except Exception as e:
    print('[wrapper] VERIFY_FAILED: parse error ' + str(e))
    sys.exit(1)
" | tee -a "$LOG"
        VERIFY_RC=${PIPESTATUS[0]}
        if [ "$VERIFY_RC" -ne 0 ]; then
            echo "[wrapper] ERROR: restoration verification failed (rc=$VERIFY_RC). Run emergency-restore.sh to manually restore." | tee -a "$LOG"
            exit $rc
        fi
        rm -f "$RESTORE_APEX"
        echo "[wrapper] restoration verified. See $LOG for details." | tee -a "$LOG"
        exit $rc
    }
    trap restore_bypass EXIT INT TERM

    # Step 5 — Only now enable Bypass_Triggers__c (Bypass_Flows__c / Bypass_Validation__c UNCHANGED).
    echo "[wrapper] step 5: enabling Bypass_Triggers__c (wrapper-managed window)..." | tee -a "$LOG"
    TOGGLE_APEX="$APEX_DIR/toggle-${TS}.apex"
    cat > "$TOGGLE_APEX" << 'APEX'
Automation_Settings__c s = Automation_Settings__c.getOrgDefaults();
if (s != null) {
    // Only Bypass_Triggers__c is required: 11 production triggers early-return on it
    // (DeliveryTrigger, FinancingTrigger, LeadRoutingTrigger, OpportunityTrigger,
    // QuoteTrigger, VehicleTrigger, etc.). VRs and Apex guards bypass via
    // $Permission.Bypass_Automation (separate Custom Permission). Bypass_Flows__c
    // and Bypass_Validation__c have NO current code paths reading them — leaving them
    // untouched avoids unnecessary mutation surface.
    s.Bypass_Triggers__c = true;
    update s;
    System.debug('TOGGLE_ID=' + s.Id);
    System.debug('TOGGLE_Bypass_Triggers__c=' + s.Bypass_Triggers__c);
    System.debug('TOGGLE_Bypass_Flows__c_unchanged=' + s.Bypass_Flows__c);
    System.debug('TOGGLE_Bypass_Validation__c_unchanged=' + s.Bypass_Validation__c);
}
APEX
    TOGGLE_OUT="$(sf apex run --target-org "$ORG" --file "$TOGGLE_APEX" 2>&1)"
    TOGGLE_RC=$?
    echo "$TOGGLE_OUT" | grep -E "TOGGLE|Compiled|Executed|FAILED" | tee -a "$LOG" || true
    # Fail if either sf apex run failed OR expected TOGGLE_ID line missing.
    if [ "$TOGGLE_RC" -ne 0 ] || ! echo "$TOGGLE_OUT" | grep -q "TOGGLE_ID="; then
        echo "[wrapper] ERROR: bypass toggle failed (sf apex rc=$TOGGLE_RC). Run emergency-restore.sh to recover." | tee -a "$LOG"
        # Trigger the trap to restore from snapshot.
        restore_bypass
        exit 3
    fi
    rm -f "$TOGGLE_APEX"
fi

# Read-only modes: log confirmation and continue without snapshot or restoration.
if [ "$WRAPPER_MODE" = "read-only" ]; then
    echo "[wrapper] step 1 (read-only mode): no snapshot, no restoration, no Salesforce DML" | tee -a "$LOG"
fi

# Step 6 — Run the loader.
echo "[wrapper] step 6: invoking data/scripts/load.ts with args: $*" | tee -a "$LOG"
cd "$ROOT_DIR"
# Use `npx tsx` (matches package.json `data:load` script) rather than raw
# `node --experimental-strip-types`. The raw Node ESM resolver requires the import
# path extension to be `.js`, which TypeScript strips — but the resolver does not
# automatically map `./resolve.js` to `./resolve.ts`. `tsx` does this mapping.
npx tsx data/scripts/load.ts "$@" 2>&1 | tee -a "$LOG"
LOAD_RC=${PIPESTATUS[0]}

echo "[wrapper] loader exit code: $LOAD_RC" | tee -a "$LOG"
# Hand the loader exit code to the trap (avoids trap-function-local-$? shadowing).
LOAD_RC_GUARD=$LOAD_RC
# Trap will fire on script exit and restore bypass from snapshot.
# For read-only modes, explicitly propagate the loader exit code so the wrapper
# surfaces validation failures to the calling shell (the last `echo | tee` would
# otherwise exit 0).
exit "$LOAD_RC"