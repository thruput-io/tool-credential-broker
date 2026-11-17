#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/reporters/lib/common.sh
source "${ROOT_DIR:?semgrep.sh: name the ROOT_DIR}/scripts/reporters/lib/common.sh"

report=${1:?semgrep.sh: name the report to write}
mapfile -t files < <(shell_files)
semgrep --error --config "https://thruput.se/semgrep/bash.yaml" --json-output="$report" "${files[@]}"
