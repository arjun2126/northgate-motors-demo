#!/usr/bin/env bash
# Refuses mutations. A fresh snapshot is mandatory even for the exact-ID reset plan.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
if [[ $# != 2 || "$1" != "--snapshot" ]]; then
    printf '%s\n' 'Usage: bash scripts/reset.sh --snapshot <fresh-snapshot.json>' >&2
    printf '%s\n' 'No delete, purge, or reload is authorized by this script.' >&2
    exit 2
fi
exec python3 "$ROOT/data/scripts/phase5.py" reset-plan --snapshot "$2"
