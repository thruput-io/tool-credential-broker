#!/usr/bin/env bash
set -euo pipefail

: "${ROOT_DIR:?readme.sh: name the ROOT_DIR}"
mode=$2

mkdir -p "$ROOT_DIR/build"
listing=$(mktemp)
trap 'rm -f "$listing"' EXIT

find "$ROOT_DIR" \
  \( -path "$ROOT_DIR/.git" -o -path "$ROOT_DIR/build" -o -path "$ROOT_DIR/.idea" -o -path "$ROOT_DIR/.claude" \
     -o -name vendor -o -name testdata \) -prune -o -type d -print \
  | sed "s|^$ROOT_DIR||; s|^/||" \
  | grep -v '^$' \
  | sort \
  | awk -F/ '{
      indent = ""
      for (depth = 1; depth < NF; depth++) indent = indent "  "
      print indent $NF "/"
    }' > "$listing"

awk -v listing="$listing" '
  /^<!-- layout -->$/ {
    print
    print "```"
    while ((getline line < listing) > 0) print line
    print "```"
    skip = 1
    next
  }
  /^<!-- end layout -->$/ { skip = 0 }
  !skip { print }
' "$ROOT_DIR/README.md" > "$ROOT_DIR/build/readme.generated"

if [ "$mode" = --write ]; then
  mv "$ROOT_DIR/build/readme.generated" "$ROOT_DIR/README.md"
  echo "README.md written from the tree"
else
  diff -u "$ROOT_DIR/README.md" "$ROOT_DIR/build/readme.generated" > /dev/null && result=same || result=drifted
  rm -f "$ROOT_DIR/build/readme.generated"
  if [ "$result" = drifted ]; then
    echo "readme.sh: README.md does not say what the tree holds. Run: make readme" >&2
    exit 1
  fi
  echo "ok: README.md says what the tree holds"
fi
