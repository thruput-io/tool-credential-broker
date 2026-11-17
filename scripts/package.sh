#!/usr/bin/env bash
set -euo pipefail

into=${1:?package.sh: name the directory to deliver the packages into}

: "${ROOT_DIR:?package.sh: name the ROOT_DIR}"

for fmt in ${PACKAGE_FORMATS:?package.sh: name the PACKAGE_FORMATS to build}; do
  case "$fmt" in
    deb)
      bash "$ROOT_DIR/scripts/deliver-deb.sh" "$into/deb"
      ;;
    brew)
      bash "$ROOT_DIR/scripts/deliver-brew.sh" "$into/brew"
      ;;
    *)
      echo "package.sh: no packaging for format '$fmt'" >&2
      exit 1
      ;;
  esac
done
