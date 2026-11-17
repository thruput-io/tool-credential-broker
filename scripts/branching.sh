#!/usr/bin/env bash
set -euo pipefail

: "${ROOT_DIR:?branching.sh: name the ROOT_DIR}"

find "$ROOT_DIR/src" "$ROOT_DIR/scripts" -name '*.bats' -print0 \
  | xargs -0 awk '
  /^[[:space:]]*(if|elif|case)[[:space:]]/          { print FILENAME ": branches" }
  /\$\{[A-Za-z_][A-Za-z0-9_]*:[-=+?]/               { print FILENAME ": defaults a variable" }
' | sort -u
