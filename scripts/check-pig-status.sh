#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
sdk=$(pig reload --sdk-path)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

node --test "$root/scripts/test-pig-status-usage.mjs"

cd "$root/user/apps/ai/pig-status"
cp go.mod "$tmp/go.mod"
go mod edit -modfile="$tmp/go.mod" \
  -replace="github.com/MichaelKinsy/PiG/extensions/sdk=$sdk"
go test -modfile="$tmp/go.mod" -race ./...
go vet -modfile="$tmp/go.mod" ./...

mkdir -p "$tmp/package/bin"
go build -modfile="$tmp/go.mod" -o "$tmp/package/bin/pig-status" .
cp package.json "$tmp/package/package.json"
PIG_STATUS_PACKAGE="$tmp/package" node --test "$root/scripts/test-pig-status-discovery.mjs"
