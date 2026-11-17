#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: build.sh DIRECTORY" >&2
  exit 1
fi

mkdir -p "$1"
into=$(realpath "$1")
dir=$(dirname "$0")

unformatted=$(find "$dir" -name '*.go' -not -path "$dir/vendor/*" -exec gofmt -l {} +)
if [ -n "$unformatted" ]; then
  echo "build.sh: these are not gofmt-clean: $unformatted" >&2
  exit 1
fi

go -C "$dir" vet -mod=vendor ./...
go -C "$dir" test -mod=vendor ./...

go -C "$dir" build -mod=vendor -buildvcs=false -o "$into/parse" ./cmd/parse
go -C "$dir" build -mod=vendor -buildvcs=false -o "$into/format" ./cmd/format
