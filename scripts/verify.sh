#!/usr/bin/env bash
# Northgate Motors — Phase 5 release-gate DQ verifier (P5-08).
# Runs strict original-criteria gates, including legacy and real ledger evidence.
# Read-only: no Salesforce DML. Exit 0 on all PASS, nonzero on any FAIL.
#
# Usage:
#   SF_TARGET_ORG=ng-demo bash scripts/verify.sh
set -uo pipefail

ORG="${SF_TARGET_ORG:-ng-demo}"
[[ "$ORG" == "ng-demo" ]] || { printf '%s\n' 'ng-demo only' >&2; exit 2; }
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"
exec python3 data/scripts/phase5.py verify "$@"
