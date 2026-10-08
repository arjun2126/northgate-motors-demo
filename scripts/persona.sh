#!/usr/bin/env bash
# Switch ngpersona between Sales Manager and Finance Officer personas.
# Usage: scripts/persona.sh <manager|finance>
set -euo pipefail

PERSONA="${1:-}"
ORG="${SF_TARGET_ORG:-ng-dev}"
USER_NAME="ngpersona@northgate.demo"

case "$PERSONA" in
  manager)
    ROLE_API="Sales_Manager_Airport"
    PSG_API="PSG_Manager"
    ;;
  finance)
    ROLE_API="Finance_Manager"
    PSG_API="PSG_Finance"
    ;;
  *)
    echo "Usage: $0 <manager|finance>"
    exit 1
    ;;
esac

echo "Switching $USER_NAME to $PERSONA (role=$ROLE_API, psg=$PSG_API) on org $ORG"

ROLE_ID=$(sf data query --target-org "$ORG" --query "SELECT Id FROM UserRole WHERE DeveloperName = '$ROLE_API'" --result-format csv | tail -1)
USER_ID=$(sf data query --target-org "$ORG" --query "SELECT Id FROM User WHERE Username = '$USER_NAME'" --result-format csv | tail -1)
PSG_ID=$(sf data query --target-org "$ORG" --query "SELECT Id FROM PermissionSetGroup WHERE DeveloperName = '$PSG_API'" --result-format csv | tail -1)

if [[ -z "$ROLE_ID" || "$ROLE_ID" == "Id" ]]; then echo "Role $ROLE_API not found"; exit 1; fi
if [[ -z "$USER_ID" || "$USER_ID" == "Id" ]]; then echo "User $USER_NAME not found"; exit 1; fi
if [[ -z "$PSG_ID" || "$PSG_ID" == "Id" ]]; then echo "Permission set group $PSG_API not found"; exit 1; fi

# Update role
sf data update record --target-org "$ORG" -s User -i "$USER_ID" -v "UserRoleId=$ROLE_ID"

# Remove existing manager/finance PSG assignments
sf data query --target-org "$ORG" --query "SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = '$USER_ID' AND PermissionSetGroup.DeveloperName IN ('PSG_Manager','PSG_Finance')" --result-format csv | tail -n +2 | while read -r ASSIGN_ID; do
  [[ -n "$ASSIGN_ID" ]] || continue
  sf data delete record --target-org "$ORG" -s PermissionSetAssignment -i "$ASSIGN_ID"
done

# Assign target PSG
sf data create record --target-org "$ORG" -s PermissionSetAssignment -v "AssigneeId=$USER_ID PermissionSetGroupId=$PSG_ID"

echo "Active persona: $PERSONA (role $ROLE_API, PSG $PSG_API)"
