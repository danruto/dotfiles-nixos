#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$script_dir/../../.." && pwd)
sdk=$(pig reload --sdk-path)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

node --test "$script_dir/test-usage.mjs"

cd "$root/user/apps/ai/pig-status"
cp go.mod "$tmp/go.mod"
go mod edit -modfile="$tmp/go.mod" \
  -replace="github.com/MichaelKinsy/PiG/extensions/sdk=$sdk"
go test -modfile="$tmp/go.mod" -race ./...
go vet -modfile="$tmp/go.mod" ./...

mkdir -p "$tmp/package/bin"
go build -modfile="$tmp/go.mod" -o "$tmp/package/bin/pig-status" .
cp package.json "$tmp/package/package.json"
PIG_STATUS_PACKAGE="$tmp/package" node --test "$script_dir/test-discovery.mjs"
