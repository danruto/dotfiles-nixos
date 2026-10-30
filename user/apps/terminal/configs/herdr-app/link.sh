set -eu

source_root=$1
target_root=$2
shift 2

for asset in "$@"; do
  if [ ! -e "$source_root/$asset" ]; then
    printf 'Missing Herdr asset: %s\n' "$source_root/$asset" >&2
    exit 1
  fi
done

backup=
for asset in "$@"; do
  source="$source_root/$asset"
  target="$target_root/$asset"
  if [ -L "$target" ] && [ "$target" -ef "$source" ]; then
    continue
  fi
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -z "$backup" ]; then
      mkdir -p "${target_root}-backups"
      backup=$(mktemp -d "${target_root}-backups/activation-XXXXXX")
      printf 'Backing up existing Herdr files to %s\n' "$backup"
    fi
    mkdir -p "$backup/$(dirname "$asset")"
    mv "$target" "$backup/$asset"
  fi
  ln -s "$source" "$target"
done
