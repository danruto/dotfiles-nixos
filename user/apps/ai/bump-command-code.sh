#!/usr/bin/env bash
# Bump command-code.nix to the latest (or given) npm version.
# Usage: ./bump-command-code.sh [version]
set -euo pipefail
npmget() { curl -sf "https://registry.npmjs.org/command-code/$1" | jq -er ".$2"; }
dir=$(cd "$(dirname "$0")" && pwd)
nix=$dir/command-code.nix
ver=${1:-$(npmget latest version)}
[ "$ver" = "$(sed -n 's/.*version = "\(.*\)";/\1/p' "$nix")" ] && { echo "already $ver"; exit 0; }

src=$(npmget "$ver" dist.integrity)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
curl -sf "$(npmget "$ver" dist.tarball)" | tar xz && cd package
sed -i '/"devDependencies": {/,/^  }/d' package.json
nix shell nixpkgs#nodejs -c npm install --package-lock-only --ignore-scripts >/dev/null 2>&1
cp package-lock.json "$dir/command-code-package-lock.json"
deps=$(nix run nixpkgs#prefetch-npm-deps -- package-lock.json 2>/dev/null)

sed -i \
  -e "s|version = \".*\";|version = \"$ver\";|" \
  -e "s|hash = \"sha512-.*\";|hash = \"$src\";|" \
  -e "s|npmDepsHash = \".*\";|npmDepsHash = \"$deps\";|" "$nix"
echo "bumped to $ver"
