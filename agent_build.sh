#!/bin/bash
set -euo pipefail

ROOT_DIR=$(dirname "$(realpath "$0")")
export ROOT_DIR

built=$(mktemp -d)
trap 'rm -rf "$built"' EXIT

say() { printf '\n=== %s ===\n' "$1"; }

the_tree() { (git -C "$ROOT_DIR" ls-files --cached --others --exclude-standard | grep -v '/$'; env -C "$ROOT_DIR" find .git) | COPYFILE_DISABLE=1 tar -cf - -C "$ROOT_DIR" --no-recursion -T -; }

what_a_clean_machine_gets() { COPYFILE_DISABLE=1 tar -cf - -C "$ROOT_DIR" constants.env src/integration-test -C "$1" build/dist; }

say "build, as the build job does"
mkdir -p "$built/debian/build"
the_tree | docker run -i --rm -e BUILD_NUMBER debian:testing-slim sh -c '
    set -eu
    {
      mkdir -p /work
      tar -C /work -xf -
      apt-get update
      apt-get install -y --no-install-recommends make git ca-certificates
      git config --global --add safe.directory "*"
      make -C /work setup
      make -C /work build
    } >&2
    tar -cf - -C /work/build dist' | tar -xf - -C "$built/debian/build"

say "install on a clean debian, as the Debian stable job does"
what_a_clean_machine_gets "$built/debian" | docker run -i --rm -e ROOT_DIR=/work debian:testing-slim bash -c '
    set -eu
    mkdir -p /work
    tar -C /work -xf -
    source /work/constants.env
    BREW_TAP="$BREW_TAP" bash -ec "$DEBIAN_ADD_ARCHIVE"
    BREW_TAP="$BREW_TAP" INSTALL_COMMAND="$DEBIAN_INSTALL_COMMAND" REMOVE_PACKAGES="$DEBIAN_REMOVE_PACKAGES" AS_AGENT="$DEBIAN_AS_AGENT" bash /work/src/integration-test/test.sh'

if command -v macos-vm > /dev/null; then
  say "build on macOS, as the build macOS job does"
  macos-vm reset > /dev/null
  the_tree | macos-vm shell bash -lc "
    set -eu
    rm -rf \"\$HOME/gettoken\"
    mkdir \"\$HOME/gettoken\"
    tar -C \"\$HOME/gettoken\" -xf -
    brew install make
    gmake -C \"\$HOME/gettoken\" setup
    gmake -C \"\$HOME/gettoken\" build"
  mkdir -p "$built/macos/build"
  macos-vm shell bash -lc "COPYFILE_DISABLE=1 tar -cf - -C \"\$HOME/gettoken/build\" dist" | tar -xf - -C "$built/macos/build"

  say "install on a fresh macOS guest, as the macOS stable job does"
  macos-vm reset > /dev/null
  what_a_clean_machine_gets "$built/macos" | macos-vm shell bash -lc "
    set -eu
    rm -rf \"\$HOME/gettoken\"
    mkdir \"\$HOME/gettoken\"
    tar -C \"\$HOME/gettoken\" -xf -
    export ROOT_DIR=\"\$HOME/gettoken\"
    source \"\$HOME/gettoken/constants.env\"
    BREW_TAP=\"\$BREW_TAP\" bash -ec \"\$DARWIN_ADD_ARCHIVE\"
    BREW_TAP=\"\$BREW_TAP\" INSTALL_COMMAND=\"\$DARWIN_INSTALL_COMMAND\" REMOVE_PACKAGES=\"\$DARWIN_REMOVE_PACKAGES\" AS_AGENT=\"\$DARWIN_AS_AGENT\" bash \"\$HOME/gettoken/src/integration-test/test.sh\""
fi

say "everything the pipeline does before it releases, done here"
