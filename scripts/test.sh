#!/usr/bin/env bash
# Northgate P7-17: print plan by default; --run performs only check-only/tests/read-only DQ.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/tests/p7_regression.py" "$@"
