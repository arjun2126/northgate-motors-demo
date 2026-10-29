#!/usr/bin/env bash
# Controlled persona switching for ngpersona.ngdemo@northgate.demo on ng-demo only.
#
# Usage:
#   scripts/persona.sh --dry-run rep|manager|finance|vp
#   scripts/persona.sh rep|manager|finance|vp
#   scripts/persona.sh capture-baseline
#   scripts/persona.sh --dry-run restore
#   scripts/persona.sh restore
#
# Live switching requires explicit owner authorization. This script never changes
# ManagerId, profile, Lightning access, approval routing, OWDs, or business data.
set -euo pipefail

EXPECTED_ORG_ALIAS="ng-demo"
EXPECTED_ORG_ID="00Daj00001Ae3iWEAR"
EXPECTED_USERNAME="ngpersona.ngdemo@northgate.demo"
EXPECTED_USER_ID="005aj00000gE0b3AAC"

BASELINE_DIR="${PERSONA_BASELINE_DIR:-evidence/UAT}"
BASELINE_FILE="$BASELINE_DIR/persona_baseline.json"
HISTORY_FILE="$BASELINE_DIR/persona_history.log"
SF_BIN="${SF_BIN:-sf}"

SERVICE_PSG="PSG_Service"
MANAGED_PSGS=(PSG_Rep PSG_Manager PSG_Finance)
ALL_PERSONA_PSGS=(PSG_Rep PSG_Manager PSG_Finance PSG_Service)
MANAGED_ALLOWED_JSON='["PSG_Rep","PSG_Manager","PSG_Finance"]'
PERSONA_ALLOWED_JSON='["PSG_Rep","PSG_Manager","PSG_Finance","PSG_Service"]'

DRY_RUN=0
BLOCKED=0
CHANGED=0
IN_RESTORE=0
ACTION=""
PERSONA=""
ORG=""
ORG_ID=""
USER_ID=""
USER_ROLE_ID=""
USER_ROLE_NAME=""
MANAGER_ID=""
PROFILE_ID=""
ROLE_ID=""
ROLE_API=""
PSG_ID=""
PSG_API=""
PSG_STATUS=""
CURRENT_ALL_NAMES=""
CURRENT_MANAGED_NAMES=""
USER_JSON=""
PSA_JSON=""

usage() {
  cat <<'USAGE'
Usage:
  scripts/persona.sh --dry-run rep|manager|finance|vp
  scripts/persona.sh rep|manager|finance|vp
  scripts/persona.sh capture-baseline
  scripts/persona.sh --dry-run restore
  scripts/persona.sh restore

Personas:
  rep      Sales_Rep + PSG_Rep
  manager  Sales_Manager_Airport + PSG_Manager
  finance  Finance_Manager + PSG_Finance
  vp       VP_Sales + PSG_Manager

Safety:
  - ng-demo only; org ID must be 00Daj00001Ae3iWEAR
  - user must be ngpersona.ngdemo@northgate.demo / 005aj00000gE0b3AAC
  - blocks when ngpersona has pending approvals
  - baseline is captured once and never overwritten
  - PSG_Service, ManagerId, profile, and unrelated permission sets are preserved
  - restore is the only complete rollback; `vp` is not a rollback
USAGE
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '%s\n' "$*"
}

require_tools() {
  command -v jq >/dev/null 2>&1 || die "jq is required."
  command -v "$SF_BIN" >/dev/null 2>&1 || die "Salesforce CLI not found: $SF_BIN"
}

# Run a Salesforce CLI command that supports --json. Returns non-zero and prints a
# short message on failure. Never call directly for DML unless the caller handles
# the failure path.
sf_json_call() {
  local out rc status msg
  set +e
  out=$("$SF_BIN" "$@" --json 2>&1)
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    msg=$(printf '%s' "$out" | jq -r '.message // empty' 2>/dev/null || true)
    printf 'Salesforce CLI failed (rc=%s): %s\n' "$rc" "${msg:-$out}" >&2
    return 1
  fi
  status=$(printf '%s' "$out" | jq -r '.status // 0' 2>/dev/null || echo 0)
  if [[ "$status" != "0" ]]; then
    msg=$(printf '%s' "$out" | jq -r '.message // empty' 2>/dev/null || true)
    printf 'Salesforce API failed (status=%s): %s\n' "$status" "${msg:-$out}" >&2
    return 1
  fi
  printf '%s' "$out"
}

# Read-only calls retry transient CLI/network failures. DML uses sf_call and
# never retries, because a failed DML response is ambiguous.
sf_json_retry() {
  local attempt=1 out
  while [[ $attempt -le 4 ]]; do
    if out=$(sf_json_call "$@"); then
      printf '%s' "$out"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 3
  done
  return 1
}

sf_query() {
  local soql="$1"
  shift
  sf_json_retry data query --target-org "$ORG" --query "$soql" "$@"
}

sf_call() {
  sf_json_call "$@"
}

has_name() {
  local list=",$1,"
  [[ "$list" == *",$2,"* ]]
}

load_org() {
  ORG="${SF_TARGET_ORG:-ng-demo}"
  if [[ "$ORG" != "$EXPECTED_ORG_ALIAS" ]]; then
    printf 'Refusing org %s. Only %s is permitted.\n' "$ORG" "$EXPECTED_ORG_ALIAS" >&2
    return 1
  fi

  local org_json
  org_json=$(sf_json_retry org display --target-org "$ORG") || return 1
  ORG_ID=$(jq -r '.result.id // empty' <<<"$org_json")
  if [[ "$ORG_ID" != "$EXPECTED_ORG_ID" ]]; then
    printf 'Refusing org ID %s. Expected %s.\n' "${ORG_ID:-<missing>}" "$EXPECTED_ORG_ID" >&2
    return 1
  fi
  return 0
}

load_user() {
  local user_json count
  user_json=$(sf_query "SELECT Id, Username, UserRoleId, UserRole.DeveloperName, ManagerId, ProfileId, IsActive FROM User WHERE Username = '$EXPECTED_USERNAME'") || return 1
  count=$(jq -r '(.result.records // []) | length' <<<"$user_json")
  if [[ "$count" != "1" ]]; then
    printf 'Expected exactly one user %s; found %s.\n' "$EXPECTED_USERNAME" "$count" >&2
    return 1
  fi

  USER_JSON="$user_json"
  USER_ID=$(jq -r '.result.records[0].Id // empty' <<<"$user_json")
  USER_ROLE_ID=$(jq -r '.result.records[0].UserRoleId // empty' <<<"$user_json")
  USER_ROLE_NAME=$(jq -r '.result.records[0].UserRole.DeveloperName // empty' <<<"$user_json")
  MANAGER_ID=$(jq -r 'if .result.records[0].ManagerId == null then "" else .result.records[0].ManagerId end' <<<"$user_json")
  PROFILE_ID=$(jq -r '.result.records[0].ProfileId // empty' <<<"$user_json")

  if [[ "$USER_ID" != "$EXPECTED_USER_ID" ]]; then
    printf 'Refusing user ID %s. Expected %s.\n' "${USER_ID:-<missing>}" "$EXPECTED_USER_ID" >&2
    return 1
  fi
  if [[ "$(jq -r '.result.records[0].IsActive' <<<"$user_json")" != "true" ]]; then
    printf 'User %s is not active.\n' "$EXPECTED_USERNAME" >&2
    return 1
  fi
  return 0
}

load_target_role() {
  local role_json count
  role_json=$(sf_query "SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = '$ROLE_API'") || return 1
  count=$(jq -r '(.result.records // []) | length' <<<"$role_json")
  if [[ "$count" != "1" ]]; then
    printf 'Role %s not found exactly once; found %s.\n' "$ROLE_API" "$count" >&2
    return 1
  fi
  ROLE_ID=$(jq -r '.result.records[0].Id // empty' <<<"$role_json")
  return 0
}

load_target_psg() {
  local psg_json count
  psg_json=$(sf_query "SELECT Id, DeveloperName, Status FROM PermissionSetGroup WHERE DeveloperName = '$PSG_API'" --use-tooling-api) || return 1
  count=$(jq -r '(.result.records // []) | length' <<<"$psg_json")
  if [[ "$count" != "1" ]]; then
    printf 'Permission set group %s not found exactly once; found %s.\n' "$PSG_API" "$count" >&2
    return 1
  fi
  PSG_ID=$(jq -r '.result.records[0].Id // empty' <<<"$psg_json")
  PSG_STATUS=$(jq -r '.result.records[0].Status // empty' <<<"$psg_json")
  if [[ "$PSG_STATUS" != "Updated" ]]; then
    printf 'Permission set group %s is not ready (status=%s). Wait for recalculation, then retry.\n' "$PSG_API" "${PSG_STATUS:-<missing>}" >&2
    return 1
  fi
  return 0
}

load_current_assignments() {
  local psa_json
  psa_json=$(sf_query "SELECT Id, PermissionSetGroupId, PermissionSetGroup.DeveloperName FROM PermissionSetAssignment WHERE AssigneeId = '$USER_ID' AND PermissionSetGroupId != null" --use-tooling-api) || return 1
  PSA_JSON="$psa_json"
  CURRENT_ALL_NAMES=$(jq -r --argjson allowed "$PERSONA_ALLOWED_JSON" '[.result.records[]? | select(.PermissionSetGroup.DeveloperName as $d | $allowed | index($d)) | .PermissionSetGroup.DeveloperName] | unique | sort | join(",")' <<<"$psa_json")
  CURRENT_MANAGED_NAMES=$(jq -r --argjson managed "$MANAGED_ALLOWED_JSON" '[.result.records[]? | select(.PermissionSetGroup.DeveloperName as $d | $managed | index($d)) | .PermissionSetGroup.DeveloperName] | unique | sort | join(",")' <<<"$psa_json")
  return 0
}

assignment_ids_for_name() {
  local name="$1"
  jq -r --arg n "$name" '.result.records[]? | select(.PermissionSetGroup.DeveloperName == $n) | .Id' <<<"$PSA_JSON"
}

read_baseline() {
  if [[ ! -f "$BASELINE_FILE" ]]; then
    printf 'No baseline snapshot at %s. Run a live switch or `scripts/persona.sh capture-baseline` first.\n' "$BASELINE_FILE" >&2
    return 1
  fi
  if ! jq -e --arg org "$EXPECTED_ORG_ID" --arg user "$EXPECTED_USER_ID" '.version == 1 and .org.id == $org and .user.id == $user' "$BASELINE_FILE" >/dev/null 2>&1; then
    printf 'Baseline %s is invalid, corrupt, or belongs to another org/user. Refusing to continue.\n' "$BASELINE_FILE" >&2
    return 1
  fi

  BASELINE_ROLE_ID=$(jq -r '.user.roleId // empty' "$BASELINE_FILE")
  BASELINE_ROLE_NAME=$(jq -r '.user.roleDeveloperName // empty' "$BASELINE_FILE")
  BASELINE_MANAGER_ID=$(jq -r 'if .user.managerId == null then "" else .user.managerId end' "$BASELINE_FILE")
  BASELINE_PROFILE_ID=$(jq -r '.user.profileId // empty' "$BASELINE_FILE")
  BASELINE_MANAGED_NAMES=$(jq -r --argjson managed "$MANAGED_ALLOWED_JSON" '[.personaAssignments[]? | select(.developerName as $d | $managed | index($d)) | .developerName] | unique | sort | join(",")' "$BASELINE_FILE")
  BASELINE_SERVICE_NAMES=$(jq -r '[.personaAssignments[]? | select(.developerName == "PSG_Service") | .developerName] | unique | join(",")' "$BASELINE_FILE")

  if [[ -z "$BASELINE_ROLE_ID" || -z "$BASELINE_ROLE_NAME" || -z "$BASELINE_PROFILE_ID" ]]; then
    printf 'Baseline %s is missing role or profile data. Refusing to continue.\n' "$BASELINE_FILE" >&2
    return 1
  fi

  local p psg_id
  if [[ -n "$BASELINE_MANAGED_NAMES" ]]; then
    for p in $(printf '%s' "$BASELINE_MANAGED_NAMES" | tr ',' ' '); do
      psg_id=$(baseline_psg_id_for "$p")
      if [[ -z "$psg_id" ]]; then
        printf 'Baseline assignment for %s has no permission set group ID. Refusing to continue.\n' "$p" >&2
        return 1
      fi
    done
  fi
  return 0
}

baseline_psg_id_for() {
  local name="$1"
  jq -r --arg n "$name" '.personaAssignments[]? | select(.developerName == $n) | .permissionSetGroupId' "$BASELINE_FILE" | head -n 1
}

baseline_has_managed() {
  has_name "$BASELINE_MANAGED_NAMES" "$1"
}

verify_identity_against_baseline() {
  if [[ "$PROFILE_ID" != "$BASELINE_PROFILE_ID" ]]; then
    printf 'Profile changed outside this UAT process (%s != baseline %s). Refusing to continue.\n' "$PROFILE_ID" "$BASELINE_PROFILE_ID" >&2
    return 1
  fi
  if [[ "${MANAGER_ID:-}" != "${BASELINE_MANAGER_ID:-}" ]]; then
    printf 'ManagerId changed outside this UAT process (%s != baseline %s). Refusing to continue; reconcile manually.\n' "${MANAGER_ID:-null}" "${BASELINE_MANAGER_ID:-null}" >&2
    return 1
  fi
  return 0
}

require_known_baseline_state() {
  if [[ "$USER_ROLE_NAME" != "VP_Sales" ]]; then
    printf 'Refusing to capture baseline: current role is %s, expected VP_Sales.\n' "${USER_ROLE_NAME:-<none>}" >&2
    return 1
  fi
  if [[ -n "$MANAGER_ID" ]]; then
    printf 'Refusing to capture baseline: ManagerId is %s, expected null.\n' "$MANAGER_ID" >&2
    return 1
  fi
  if [[ -n "$CURRENT_MANAGED_NAMES" ]]; then
    printf 'Refusing to capture baseline: managed persona PSGs present (%s), expected none.\n' "$CURRENT_MANAGED_NAMES" >&2
    return 1
  fi
  return 0
}

capture_baseline() {
  if [[ -f "$BASELINE_FILE" ]]; then
    read_baseline || return 1
    info "Baseline already exists: $BASELINE_FILE (not overwritten)."
    return 0
  fi
  require_known_baseline_state || return 1

  mkdir -p "$BASELINE_DIR"
  local tmp user_rec persona_rec all_rec
  tmp=$(mktemp "$BASELINE_DIR/.persona_baseline.XXXXXX") || return 1
  user_rec=$(jq -c '.result.records[0]' <<<"$USER_JSON")
  persona_rec=$(jq -c --argjson allowed "$PERSONA_ALLOWED_JSON" '[.result.records[]? | select(.PermissionSetGroup.DeveloperName as $d | $allowed | index($d)) | {id:.Id, permissionSetGroupId:.PermissionSetGroupId, developerName:.PermissionSetGroup.DeveloperName}] | sort_by(.developerName)' <<<"$PSA_JSON")
  all_rec=$(jq -c '[.result.records[]? | {id:.Id, permissionSetGroupId:.PermissionSetGroupId, developerName:.PermissionSetGroup.DeveloperName}] | sort_by(.developerName)' <<<"$PSA_JSON")

  if ! jq -n \
    --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg orgAlias "$ORG" \
    --arg orgId "$ORG_ID" \
    --argjson u "$user_rec" \
    --argjson p "$persona_rec" \
    --argjson all "$all_rec" \
    '{
      version: 1,
      capturedAt: $ts,
      org: {alias: $orgAlias, id: $orgId},
      user: {
        username: $u.Username,
        id: $u.Id,
        roleId: $u.UserRoleId,
        roleDeveloperName: $u.UserRole.DeveloperName,
        managerId: $u.ManagerId,
        profileId: $u.ProfileId,
        isActive: $u.IsActive
      },
      personaAssignments: $p,
      allPermissionSetGroupAssignments: $all
    }' > "$tmp"; then
    rm -f "$tmp"
    printf 'Failed to write baseline snapshot.\n' >&2
    return 1
  fi
  chmod 600 "$tmp"
  if [[ -e "$BASELINE_FILE" ]]; then
    rm -f "$tmp"
    printf 'Baseline appeared concurrently at %s; refusing to overwrite.\n' "$BASELINE_FILE" >&2
    return 1
  fi
  mv "$tmp" "$BASELINE_FILE"
  info "Baseline captured: $BASELINE_FILE"
  return 0
}

check_pending_approvals() {
  local submitted workitems s_count w_count
  submitted=$(sf_query "SELECT Id, ProcessDefinition.DeveloperName, Status, TargetObjectId FROM ProcessInstance WHERE SubmittedById = '$USER_ID' AND Status IN ('Pending','Started') LIMIT 200") || return 2
  workitems=$(sf_query "SELECT Id, ProcessInstanceId, ActorId, ProcessInstance.Status, ProcessInstance.ProcessDefinition.DeveloperName, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ActorId = '$USER_ID' AND ProcessInstance.Status IN ('Pending','Started') LIMIT 200") || return 2

  s_count=$(jq -r '(.result.records // []) | length' <<<"$submitted")
  w_count=$(jq -r '(.result.records // []) | length' <<<"$workitems")
  if [[ "$s_count" != "0" ]]; then
    printf 'Pending approvals submitted by ngpersona:\n'
    jq -r '.result.records[]? | "  - \(.ProcessDefinition.DeveloperName // "unknown") status=\(.Status) target=\(.TargetObjectId // "")"' <<<"$submitted"
  fi
  if [[ "$w_count" != "0" ]]; then
    printf 'Pending approvals awaiting ngpersona as approver:\n'
    jq -r '.result.records[]? | "  - \(.ProcessInstance.ProcessDefinition.DeveloperName // "unknown") status=\(.ProcessInstance.Status) target=\(.ProcessInstance.TargetObjectId // "")"' <<<"$workitems"
  fi
  if [[ "$s_count" != "0" || "$w_count" != "0" ]]; then
    return 1
  fi
  return 0
}

preflight_common() {
  load_org || return 1
  load_user || return 1
  load_current_assignments || return 1
  return 0
}

preflight_switch() {
  load_org || return 1
  load_user || return 1
  load_target_role || return 1
  load_target_psg || return 1
  load_current_assignments || return 1

  if [[ -f "$BASELINE_FILE" ]]; then
    read_baseline || return 1
    verify_identity_against_baseline || return 1
  else
    require_known_baseline_state || return 1
  fi

  local rc
  set +e
  check_pending_approvals
  rc=$?
  set -e
  if [[ $rc -eq 2 ]]; then
    printf 'Could not verify pending approvals; refusing to switch.\n' >&2
    return 1
  elif [[ $rc -eq 1 ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      BLOCKED=1
    else
      printf 'Refusing to switch while an approval is pending; it would strand the approval.\n' >&2
      return 1
    fi
  fi
  return 0
}

preflight_restore() {
  load_org || return 1
  load_user || return 1
  load_current_assignments || return 1
  read_baseline || return 1
  verify_identity_against_baseline || return 1

  local rc
  set +e
  check_pending_approvals
  rc=$?
  set -e
  if [[ $rc -eq 2 ]]; then
    printf 'Could not verify pending approvals; refusing to restore.\n' >&2
    return 1
  elif [[ $rc -eq 1 ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      BLOCKED=1
    else
      printf 'Refusing to restore while an approval is pending; it would strand the approval.\n' >&2
      return 1
    fi
  fi
  return 0
}

plan_delete_psgs() {
  local p out=""
  for p in "${MANAGED_PSGS[@]}"; do
    [[ "$p" == "$PSG_API" ]] && continue
    if has_name "$CURRENT_MANAGED_NAMES" "$p"; then
      out="${out}${out:+,}$p"
    fi
  done
  printf '%s' "$out"
}

print_switch_plan() {
  local role_change=0 add_psg=0 deletes
  [[ "$USER_ROLE_NAME" != "$ROLE_API" ]] && role_change=1
  has_name "$CURRENT_ALL_NAMES" "$PSG_API" || add_psg=1
  deletes=$(plan_delete_psgs)

  info "Org: $ORG ($ORG_ID) CONFIRMED"
  info "User: $EXPECTED_USERNAME ($USER_ID) CONFIRMED"
  info "Current role: ${USER_ROLE_NAME:-<none>} ($USER_ROLE_ID)"
  info "Current persona PSGs: ${CURRENT_ALL_NAMES:-<none>}"
  info "Target persona: $PERSONA -> role $ROLE_API ($ROLE_ID), PSG $PSG_API ($PSG_ID, status $PSG_STATUS)"

  if [[ $role_change -eq 0 && $add_psg -eq 0 && -z "$deletes" ]]; then
    info "No changes required; already on $PERSONA."
  else
    [[ $add_psg -eq 1 ]] && info "Would ADD PSG: $PSG_API ($PSG_ID)"
    [[ $role_change -eq 1 ]] && info "Would UPDATE ROLE: ${USER_ROLE_NAME:-<none>} -> $ROLE_API ($ROLE_ID)"
    [[ -n "$deletes" ]] && info "Would DELETE PSG: $deletes"
  fi
  info "Would PRESERVE: ManagerId=${MANAGER_ID:-null}, profile=$PROFILE_ID, $SERVICE_PSG, unrelated permission sets."
  info "DRY RUN: no Salesforce DML performed."
}

print_restore_plan() {
  local deletes="" p
  for p in $(printf '%s' "$CURRENT_MANAGED_NAMES" | tr ',' ' '); do
    if ! baseline_has_managed "$p"; then
      deletes="${deletes}${deletes:+,}$p"
    fi
  done
  info "Baseline: $BASELINE_FILE"
  info "Would RESTORE ROLE: ${USER_ROLE_NAME:-<none>} -> $BASELINE_ROLE_NAME ($BASELINE_ROLE_ID)"
  info "Would ENSURE baseline PSGs: ${BASELINE_MANAGED_NAMES:-<none>}"
  [[ -n "$deletes" ]] && info "Would DELETE non-baseline PSGs: $deletes"
  info "Would PRESERVE: ManagerId=${BASELINE_MANAGER_ID:-null}, profile=$BASELINE_PROFILE_ID, $SERVICE_PSG."
  info "DRY RUN: no Salesforce DML performed."
}

switch_fail() {
  printf 'ERROR: %s\n' "$1" >&2
  if [[ $CHANGED -eq 1 && $IN_RESTORE -eq 0 ]]; then
    printf 'Attempting automatic restore from baseline...\n' >&2
    IN_RESTORE=1
    if restore_internal; then
      printf 'Automatic restore succeeded; baseline re-verified.\n' >&2
    else
      printf 'AUTOMATIC RESTORE FAILED. Run: scripts/persona.sh restore\n' >&2
    fi
    IN_RESTORE=0
  fi
  exit 1
}

log_history() {
  mkdir -p "$BASELINE_DIR"
  printf '%s\taction=%s\trole=%s\tpsgs=%s\tbaseline=%s\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$1" "${2:-}" "${3:-}" "$BASELINE_FILE" >> "$HISTORY_FILE"
}

perform_switch() {
  local role_change=0 add_psg=0 deletes p ids id
  [[ "$USER_ROLE_NAME" != "$ROLE_API" ]] && role_change=1
  has_name "$CURRENT_ALL_NAMES" "$PSG_API" || add_psg=1
  deletes=$(plan_delete_psgs)

  if [[ $role_change -eq 0 && $add_psg -eq 0 && -z "$deletes" ]]; then
    info "No changes required; already on $PERSONA."
    return 0
  fi

  local pre_manager="$MANAGER_ID" pre_profile="$PROFILE_ID"
  CHANGED=0

  if [[ $add_psg -eq 1 ]]; then
    CHANGED=1
    if ! sf_call data create record --target-org "$ORG" --sobject PermissionSetAssignment \
      --values "AssigneeId=$USER_ID PermissionSetGroupId=$PSG_ID" >/dev/null; then
      switch_fail "Failed to assign $PSG_API."
    fi
  fi

  if [[ $role_change -eq 1 ]]; then
    CHANGED=1
    if ! sf_call data update record --target-org "$ORG" --sobject User \
      --record-id "$USER_ID" --values "UserRoleId=$ROLE_ID" >/dev/null; then
      switch_fail "Failed to update UserRoleId to $ROLE_API."
    fi
  fi

  if [[ -n "$deletes" ]]; then
    for p in $(printf '%s' "$deletes" | tr ',' ' '); do
      ids=$(assignment_ids_for_name "$p")
      if [[ -z "$ids" ]]; then
        printf 'Warning: no assignment ID found for %s; verifying final state.\n' "$p" >&2
        continue
      fi
      while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        CHANGED=1
        if ! sf_call data delete record --target-org "$ORG" --sobject PermissionSetAssignment \
          --record-id "$id" >/dev/null; then
          switch_fail "Failed to delete $p assignment $id."
        fi
      done <<<"$ids"
    done
  fi

  load_user || switch_fail "Switch applied but user verification query failed."
  load_current_assignments || switch_fail "Switch applied but PSG verification query failed."

  if [[ "$USER_ROLE_ID" != "$ROLE_ID" ]]; then
    switch_fail "Role verification failed: $USER_ROLE_NAME != $ROLE_API."
  fi
  if ! has_name "$CURRENT_ALL_NAMES" "$PSG_API"; then
    switch_fail "PSG verification failed: $PSG_API is not assigned."
  fi
  for p in "${MANAGED_PSGS[@]}"; do
    [[ "$p" == "$PSG_API" ]] && continue
    if has_name "$CURRENT_MANAGED_NAMES" "$p"; then
      switch_fail "PSG verification failed: unexpected managed PSG $p remains."
    fi
  done
  if [[ "${MANAGER_ID:-}" != "${pre_manager:-}" ]]; then
    switch_fail "ManagerId changed unexpectedly."
  fi
  if [[ "$PROFILE_ID" != "$pre_profile" ]]; then
    switch_fail "Profile changed unexpectedly."
  fi

  info "Active persona: $PERSONA (role $ROLE_API, PSG $PSG_API)"
  info "Preserved: ManagerId=${MANAGER_ID:-null}, profile=$PROFILE_ID, $SERVICE_PSG."
  log_history "switch:$PERSONA" "$ROLE_API" "$CURRENT_ALL_NAMES"
  return 0
}

restore_internal() {
  read_baseline || return 1
  load_org || return 1
  load_user || return 1
  load_current_assignments || return 1

  if [[ "$PROFILE_ID" != "$BASELINE_PROFILE_ID" ]]; then
    printf 'Restore refused: profile %s != baseline %s.\n' "$PROFILE_ID" "$BASELINE_PROFILE_ID" >&2
    return 1
  fi
  if [[ "${MANAGER_ID:-}" != "${BASELINE_MANAGER_ID:-}" ]]; then
    printf 'Restore refused: ManagerId %s != baseline %s. Reconcile manually.\n' "${MANAGER_ID:-null}" "${BASELINE_MANAGER_ID:-null}" >&2
    return 1
  fi

  local p psg_id id ids
  if [[ -n "$BASELINE_MANAGED_NAMES" ]]; then
    for p in $(printf '%s' "$BASELINE_MANAGED_NAMES" | tr ',' ' '); do
      if ! has_name "$CURRENT_MANAGED_NAMES" "$p"; then
        psg_id=$(baseline_psg_id_for "$p")
        if [[ -z "$psg_id" ]]; then
          printf 'Restore failed: baseline PSG ID missing for %s.\n' "$p" >&2
          return 1
        fi
        if ! sf_call data create record --target-org "$ORG" --sobject PermissionSetAssignment \
          --values "AssigneeId=$USER_ID PermissionSetGroupId=$psg_id" >/dev/null; then
          printf 'Restore failed: could not add %s.\n' "$p" >&2
          return 1
        fi
      fi
    done
  fi

  if [[ -n "$BASELINE_SERVICE_NAMES" ]] && ! has_name "$CURRENT_ALL_NAMES" "$SERVICE_PSG"; then
    psg_id=$(baseline_psg_id_for "$SERVICE_PSG")
    if [[ -n "$psg_id" ]]; then
      if ! sf_call data create record --target-org "$ORG" --sobject PermissionSetAssignment \
        --values "AssigneeId=$USER_ID PermissionSetGroupId=$psg_id" >/dev/null; then
        printf 'Restore failed: could not restore %s.\n' "$SERVICE_PSG" >&2
        return 1
      fi
    fi
  fi

  if [[ "$USER_ROLE_ID" != "$BASELINE_ROLE_ID" ]]; then
    if ! sf_call data update record --target-org "$ORG" --sobject User \
      --record-id "$USER_ID" --values "UserRoleId=$BASELINE_ROLE_ID" >/dev/null; then
      printf 'Restore failed: could not restore role %s.\n' "$BASELINE_ROLE_NAME" >&2
      return 1
    fi
  fi

  load_current_assignments || return 1
  for p in $(printf '%s' "$CURRENT_MANAGED_NAMES" | tr ',' ' '); do
    if ! baseline_has_managed "$p"; then
      ids=$(assignment_ids_for_name "$p")
      while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        if ! sf_call data delete record --target-org "$ORG" --sobject PermissionSetAssignment \
          --record-id "$id" >/dev/null; then
          printf 'Restore failed: could not delete non-baseline %s assignment %s.\n' "$p" "$id" >&2
          return 1
        fi
      done <<<"$ids"
    fi
  done

  load_user || return 1
  load_current_assignments || return 1
  if [[ "$USER_ROLE_ID" != "$BASELINE_ROLE_ID" ]]; then
    printf 'Restore verification failed: role %s != baseline %s.\n' "$USER_ROLE_ID" "$BASELINE_ROLE_ID" >&2
    return 1
  fi
  if [[ "${MANAGER_ID:-}" != "${BASELINE_MANAGER_ID:-}" ]]; then
    printf 'Restore verification failed: ManagerId mismatch.\n' >&2
    return 1
  fi
  if [[ "$PROFILE_ID" != "$BASELINE_PROFILE_ID" ]]; then
    printf 'Restore verification failed: profile mismatch.\n' >&2
    return 1
  fi
  if [[ "$CURRENT_MANAGED_NAMES" != "$BASELINE_MANAGED_NAMES" ]]; then
    printf 'Restore verification failed: managed PSGs %s != baseline %s.\n' "${CURRENT_MANAGED_NAMES:-<none>}" "${BASELINE_MANAGED_NAMES:-<none>}" >&2
    return 1
  fi
  if [[ -n "$BASELINE_SERVICE_NAMES" ]] && ! has_name "$CURRENT_ALL_NAMES" "$SERVICE_PSG"; then
    printf 'Restore verification failed: baseline had %s, current does not.\n' "$SERVICE_PSG" >&2
    return 1
  fi

  printf 'Restored baseline: role=%s (%s), ManagerId=%s, PSGs=%s.\n' \
    "$BASELINE_ROLE_NAME" "$BASELINE_ROLE_ID" "${BASELINE_MANAGER_ID:-null}" "${BASELINE_MANAGED_NAMES:-<none>}"
  return 0
}

main() {
  local args=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run)
        DRY_RUN=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  if [[ ${#args[@]} -lt 1 ]]; then
    usage
    exit 1
  fi
  ACTION="${args[0]}"

  case "$ACTION" in
    rep|manager|finance|vp)
      if [[ ${#args[@]} -ne 1 ]]; then
        usage
        exit 1
      fi
      PERSONA="$ACTION"
      case "$PERSONA" in
        rep)     ROLE_API="Sales_Rep";            PSG_API="PSG_Rep" ;;
        manager) ROLE_API="Sales_Manager_Airport"; PSG_API="PSG_Manager" ;;
        finance) ROLE_API="Finance_Manager";       PSG_API="PSG_Finance" ;;
        vp)      ROLE_API="VP_Sales";              PSG_API="PSG_Manager" ;;
      esac
      require_tools
      preflight_switch || die "Pre-switch validation failed."
      if [[ $DRY_RUN -eq 1 ]]; then
        print_switch_plan
        [[ $BLOCKED -eq 1 ]] && exit 1
        exit 0
      fi
      capture_baseline || die "Baseline capture failed."
      perform_switch || exit 1
      ;;
    capture-baseline)
      if [[ ${#args[@]} -ne 1 ]]; then
        usage
        exit 1
      fi
      require_tools
      preflight_common || die "Preflight failed."
      if [[ $DRY_RUN -eq 1 ]]; then
        info "Would capture baseline at $BASELINE_FILE if absent."
        info "DRY RUN: no Salesforce DML performed."
        exit 0
      fi
      capture_baseline || die "Baseline capture failed."
      ;;
    restore)
      if [[ ${#args[@]} -ne 1 ]]; then
        usage
        exit 1
      fi
      require_tools
      preflight_restore || die "Restore preflight failed."
      if [[ $DRY_RUN -eq 1 ]]; then
        print_restore_plan
        [[ $BLOCKED -eq 1 ]] && exit 1
        exit 0
      fi
      IN_RESTORE=1
      if ! restore_internal; then
        IN_RESTORE=0
        die "Restore incomplete. Do not retry persona switches; reconcile with the manual commands in the runbook."
      fi
      IN_RESTORE=0
      log_history "restore" "$BASELINE_ROLE_NAME" "$BASELINE_MANAGED_NAMES"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
