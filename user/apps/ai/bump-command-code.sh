#!/usr/bin/env bash
# Bump command-code.nix to the latest (or given) npm version.
# Usage: ./bump-command-code.sh [version]
set -euo pipefail
dir=$(cd "$(dirname "$0")" && pwd)
nix=$dir/command-code.nix
ver=${1:-$(npm view command-code version)}
[ "$ver" = "$(sed -n 's/.*version = "\(.*\)";/\1/p' "$nix")" ] && { echo "already $ver"; exit 0; }

src=$(npm view "command-code@$ver" dist.integrity)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
npm pack "command-code@$ver" >/dev/null 2>&1
tar xzf "command-code-$ver.tgz" && cd package
sed -i '/"devDependencies": {/,/^  }/d' package.json
npm install --package-lock-only --ignore-scripts >/dev/null 2>&1
cp package-lock.json "$dir/command-code-package-lock.json"
deps=$(nix run nixpkgs#prefetch-npm-deps -- package-lock.json 2>/dev/null)

sed -i \
  -e "s|version = \".*\";|version = \"$ver\";|" \
  -e "s|hash = \"sha512-.*\";|hash = \"$src\";|" \
  -e "s|npmDepsHash = \".*\";|npmDepsHash = \"$deps\";|" "$nix"
echo "bumped to $ver"
