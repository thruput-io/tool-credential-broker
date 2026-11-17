# shellcheck shell=bash
set -euo pipefail

: "${ROOT_DIR:?reporters: name the ROOT_DIR}"

tracked() {
  git -C "$ROOT_DIR" ls-files --cached --others --exclude-standard -- "$@" | awk -v root="$ROOT_DIR" '!/\/vendor\// { print root "/" $0 }'
}

first_line() {
  tracked | tr '\n' '\0' | xargs -0 awk -v re="$1" "FNR == 1 && \$0 ~ re { print FILENAME } { nextfile }"
}

shell_files() {
  { tracked '*.sh' '*.bash' '*.bats'; first_line '^#!.*(sh|bats)$'; } | sort -u
}
