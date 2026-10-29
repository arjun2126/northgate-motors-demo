#!/usr/bin/env bash
# Local, offline safety tests for scripts/persona.sh. Uses a fake `sf` binary;
# never calls Salesforce and never performs live DML.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/scripts/persona.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAKE="$TMP/sf"
FAKE_STATE="$TMP/state.json"
FAKE_LOG="$TMP/dml.log"
export FAKE_STATE FAKE_LOG
export SF_BIN="$FAKE"
export PERSONA_BASELINE_DIR="$TMP/evidence"

cat > "$FAKE" <<'PY'
#!/usr/bin/env python3
import json, os, re, sys

state_path = os.environ["FAKE_STATE"]
log_path = os.environ.get("FAKE_LOG", "")
state = json.load(open(state_path))

def save():
    with open(state_path, "w") as f:
        json.dump(state, f)

def emit(status=0, **kw):
    print(json.dumps({"status": status, **kw}))
    sys.exit(0 if status == 0 else 1)

def log(line):
    if log_path:
        with open(log_path, "a") as f:
            f.write(line + "\n")

args = [a for a in sys.argv[1:] if a != "--json"]

if args[:2] == ["org", "display"]:
    emit(0, result={"id": state["org"]["id"], "username": state["user"]["Username"]})

if args[:2] == ["data", "query"]:
    q = args[args.index("--query") + 1]
    if "FROM User WHERE Username" in q:
        recs = [state["user"]]
    elif "FROM UserRole WHERE DeveloperName" in q:
        m = re.search(r"DeveloperName = '([^']+)'", q)
        name = m.group(1) if m else ""
        recs = [{"Id": state["roles"][name], "DeveloperName": name}] if name in state["roles"] else []
    elif "FROM PermissionSetGroup WHERE DeveloperName" in q:
        m = re.search(r"DeveloperName = '([^']+)'", q)
        name = m.group(1) if m else ""
        recs = [{"Id": state["psgs"][name]["Id"], "DeveloperName": name, "Status": state["psgs"][name]["Status"]}] if name in state["psgs"] else []
    elif "FROM PermissionSetAssignment WHERE AssigneeId" in q:
        recs = [a for a in state["assignments"] if a.get("PermissionSetGroupId")]
    elif "FROM ProcessInstance WHERE SubmittedById" in q:
        recs = state["pending"]
    elif "FROM ProcessInstanceWorkitem WHERE ActorId" in q:
        recs = state["workitems"]
    else:
        emit(1, message="FAKE: unsupported query: " + q)
    emit(0, result={"records": recs, "totalSize": len(recs)})

if args[:3] == ["data", "create", "record"]:
    sobject = args[args.index("--sobject") + 1]
    values = dict(re.findall(r"(\w+)=([^\s]+)", args[args.index("--values") + 1]))
    if sobject != "PermissionSetAssignment":
        emit(1, message="FAKE: unsupported create " + sobject)
    psg_id = values["PermissionSetGroupId"]
    name = next((k for k, v in state["psgs"].items() if v["Id"] == psg_id), None)
    if name is None:
        emit(1, message="FAKE: unknown PSG " + psg_id)
    new_id = "A" + str(len(state["assignments"]) + 1)
    state["assignments"].append({
        "Id": new_id,
        "PermissionSetGroupId": psg_id,
        "PermissionSetGroup": {"DeveloperName": name},
    })
    save()
    log("create PermissionSetAssignment " + name)
    emit(0, result={"id": new_id})

if args[:3] == ["data", "update", "record"]:
    sobject = args[args.index("--sobject") + 1]
    values = dict(re.findall(r"(\w+)=([^\s]+)", args[args.index("--values") + 1]))
    if sobject != "User":
        emit(1, message="FAKE: unsupported update " + sobject)
    if os.environ.get("FAKE_FAIL_UPDATE") == "1":
        emit(1, message="FAKE: injected update failure")
    role_id = values["UserRoleId"]
    role_name = next((k for k, v in state["roles"].items() if v == role_id), None)
    if role_name is None:
        emit(1, message="FAKE: unknown role " + role_id)
    state["user"]["UserRoleId"] = role_id
    state["user"]["UserRole"] = {"DeveloperName": role_name}
    save()
    log("update User role=" + role_name)
    emit(0, result={})

if args[:3] == ["data", "delete", "record"]:
    sobject = args[args.index("--sobject") + 1]
    record_id = args[args.index("--record-id") + 1]
    if sobject != "PermissionSetAssignment":
        emit(1, message="FAKE: unsupported delete " + sobject)
    before = len(state["assignments"])
    state["assignments"] = [a for a in state["assignments"] if a["Id"] != record_id]
    if len(state["assignments"]) == before:
        emit(1, message="FAKE: assignment not found " + record_id)
    save()
    log("delete PermissionSetAssignment " + record_id)
    emit(0, result={})

emit(1, message="FAKE: unsupported command: " + " ".join(args))
PY
chmod +x "$FAKE"

reset_state() {
  local org_id="${1:-00Daj00001Ae3iWEAR}"
  cat > "$FAKE_STATE" <<JSON
{
  "org": {"id": "$org_id"},
  "user": {
    "Id": "005aj00000gE0b3AAC",
    "Username": "ngpersona.ngdemo@northgate.demo",
    "UserRoleId": "VP",
    "UserRole": {"DeveloperName": "VP_Sales"},
    "ManagerId": null,
    "ProfileId": "PROF",
    "IsActive": true
  },
  "roles": {
    "VP_Sales": "VP",
    "Sales_Rep": "REP",
    "Sales_Manager_Airport": "MGR",
    "Finance_Manager": "FIN"
  },
  "psgs": {
    "PSG_Rep": {"Id": "P_REP", "Status": "Updated"},
    "PSG_Manager": {"Id": "P_MGR", "Status": "Updated"},
    "PSG_Finance": {"Id": "P_FIN", "Status": "Updated"},
    "PSG_Service": {"Id": "P_SVC", "Status": "Updated"}
  },
  "assignments": [
    {"Id": "SVC1", "PermissionSetGroupId": "P_SVC", "PermissionSetGroup": {"DeveloperName": "PSG_Service"}}
  ],
  "pending": [],
  "workitems": []
}
JSON
  : > "$FAKE_LOG"
  rm -rf "$PERSONA_BASELINE_DIR"
}

dml_count() {
  if [[ -f "$FAKE_LOG" ]]; then
    wc -l < "$FAKE_LOG" | tr -d ' '
  else
    echo 0
  fi
}

role_name() { jq -r '.user.UserRole.DeveloperName' "$FAKE_STATE"; }
persona_names() { jq -r '[.assignments[].PermissionSetGroup.DeveloperName] | sort | join(",")' "$FAKE_STATE"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

reset_state
out=$("$SCRIPT" --dry-run rep)
[[ "$(dml_count)" == "0" ]] || fail "dry-run performed DML"
[[ ! -e "$PERSONA_BASELINE_DIR/persona_baseline.json" ]] || fail "dry-run wrote baseline"
grep -q "Would ADD PSG: PSG_Rep" <<<"$out" || fail "dry-run missing add plan"
grep -q "DRY RUN: no Salesforce DML performed" <<<"$out" || fail "dry-run marker missing"
echo "PASS dry-run: zero DML, no baseline write"

reset_state
"$SCRIPT" rep >/dev/null
[[ "$(role_name)" == "Sales_Rep" ]] || fail "rep role not applied"
[[ "$(persona_names)" == "PSG_Rep,PSG_Service" ]] || fail "rep PSGs wrong: $(persona_names)"
[[ -f "$PERSONA_BASELINE_DIR/persona_baseline.json" ]] || fail "baseline not captured"
base_hash=$(shasum "$PERSONA_BASELINE_DIR/persona_baseline.json" | awk '{print $1}')
[[ "$(jq -r '.user.roleDeveloperName' "$PERSONA_BASELINE_DIR/persona_baseline.json")" == "VP_Sales" ]] || fail "baseline role wrong"
echo "PASS rep switch: baseline captured, service preserved"

before=$(dml_count)
"$SCRIPT" rep >/dev/null
[[ "$(dml_count)" == "$before" ]] || fail "repeated rep performed DML"
echo "PASS idempotent rep: no repeated DML"

"$SCRIPT" manager >/dev/null
[[ "$(role_name)" == "Sales_Manager_Airport" ]] || fail "manager role not applied"
[[ "$(persona_names)" == "PSG_Manager,PSG_Service" ]] || fail "manager PSGs wrong: $(persona_names)"
[[ "$(shasum "$PERSONA_BASELINE_DIR/persona_baseline.json" | awk '{print $1}')" == "$base_hash" ]] || fail "baseline overwritten"
echo "PASS manager switch: baseline unchanged, service preserved"

"$SCRIPT" restore >/dev/null
[[ "$(role_name)" == "VP_Sales" ]] || fail "restore role wrong"
[[ "$(persona_names)" == "PSG_Service" ]] || fail "restore PSGs wrong: $(persona_names)"
[[ "$(shasum "$PERSONA_BASELINE_DIR/persona_baseline.json" | awk '{print $1}')" == "$base_hash" ]] || fail "baseline changed on restore"
echo "PASS restore: VP_Sales, baseline PSGs, service preserved"

reset_state
python3 - "$FAKE_STATE" <<'PY'
import json,sys
p=sys.argv[1]; s=json.load(open(p))
s["pending"]=[{"Id":"PI1","ProcessDefinition":{"DeveloperName":"VP_Discount_Approval"},"Status":"Pending","TargetObjectId":"006X"}]
json.dump(s,open(p,"w"))
PY
if "$SCRIPT" rep >/dev/null 2>&1; then fail "pending approval did not block"; fi
[[ "$(dml_count)" == "0" ]] || fail "blocked switch performed DML"
echo "PASS pending approval blocks switch"

reset_state "00Dwrong000000000"
if "$SCRIPT" rep >/dev/null 2>&1; then fail "wrong org ID did not block"; fi
[[ "$(dml_count)" == "0" ]] || fail "wrong org performed DML"
echo "PASS wrong org ID blocks switch"

reset_state
"$SCRIPT" capture-baseline >/dev/null
if FAKE_FAIL_UPDATE=1 "$SCRIPT" rep >/dev/null 2>&1; then fail "injected failure did not fail"; fi
[[ "$(role_name)" == "VP_Sales" ]] || fail "auto restore did not restore role"
[[ "$(persona_names)" == "PSG_Service" ]] || fail "auto restore PSGs wrong: $(persona_names)"
echo "PASS partial-failure auto restore"

reset_state
"$SCRIPT" capture-baseline >/dev/null
before=$(dml_count)
"$SCRIPT" --dry-run restore >/dev/null
[[ "$(dml_count)" == "$before" ]] || fail "restore dry-run performed DML"
echo "PASS restore dry-run: zero DML"

echo "ALL PERSONA SAFETY TESTS PASSED"
