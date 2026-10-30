set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
source="$fixture/checkout with spaces"
target="$fixture/home/.config/herdr-app"
mkdir -p "$source/mods/custom" "$source/layouts" "$target/mods/custom" "$target/layouts/.state"
printf new > "$source/mods/custom/main.js"
printf new > "$source/layouts/custom.json"
printf new > "$source/layouts/preview.svg"
printf old > "$target/mods/custom/main.js"
printf old > "$target/layouts/custom.json"
printf local > "$target/shared.json"
printf local > "$target/layouts/.state/custom.json"
printf shipped > "$target/mods/shipped.js"
ln -s missing "$target/layouts/preview.svg"

if bash "$root/link.sh" "$source" "$target" mods/custom layouts/missing.json 2>/dev/null; then
  printf 'FAIL: missing source accepted\n' >&2
  exit 1
fi
test "$(< "$target/mods/custom/main.js")" = old
test ! -e "${target}-backups"

bash "$root/link.sh" "$source" "$target" mods/custom layouts/custom.json layouts/preview.svg
for asset in mods/custom layouts/custom.json layouts/preview.svg; do
  test -L "$target/$asset"
  test "$target/$asset" -ef "$source/$asset"
done
backups=("${target}-backups"/activation-*)
test "${#backups[@]}" = 1
backup=${backups[0]}
test "$(< "$backup/mods/custom/main.js")" = old
test "$(< "$backup/layouts/custom.json")" = old
test "$(readlink "$backup/layouts/preview.svg")" = missing
printf edited > "$target/mods/custom/main.js"
test "$(< "$source/mods/custom/main.js")" = edited

rm "$target/mods/custom"
ln -s ../../../../checkout\ with\ spaces/mods/custom "$target/mods/custom"
bash "$root/link.sh" "$source" "$target" mods/custom layouts/custom.json layouts/preview.svg
test "$(readlink "$target/mods/custom")" = '../../../../checkout with spaces/mods/custom'
backups=("${target}-backups"/activation-*)
test "${#backups[@]}" = 1
test "$(< "$target/shared.json")" = local
test "$(< "$target/layouts/.state/custom.json")" = local
test "$(< "$target/mods/shipped.js")" = shipped
printf 'PASS: link preflight, directory/file/dangling-link backups, live edits, relative-link adoption, idempotency and local-state preservation\n'
