#!/usr/bin/env bash
# Yazi-style chooser shim for elio. Elio has no native --chooser-file mode,
# so we intercept the `o` action by shadowing xdg-open / gio on PATH:
# the shim writes the selected path to a temp file and signals elio to quit.
#
# $1 = helix command to run on the picked path (e.g. "open")
# $2 = starting path (typically %{buffer_name})

set -u

out_file=$(mktemp -t elio-picker.XXXXXX)
shadow_dir=$(mktemp -d -t elio-picker-bin.XXXXXX)
trap 'rm -rf "$shadow_dir" "$out_file"' EXIT

# Resolve the real gio up front so the shim can pass non-`open` calls
# (notably `gio trash`, which elio uses for `d`) through untouched.
real_gio=$(command -v gio || true)

cat > "$shadow_dir/xdg-open" <<SHIM
#!/usr/bin/env bash
printf '%s\n' "\$1" > "$out_file"
kill -TERM "\$PPID" 2>/dev/null
exit 0
SHIM

cat > "$shadow_dir/gio" <<SHIM
#!/usr/bin/env bash
if [[ "\${1:-}" == "open" ]]; then
    printf '%s\n' "\$2" > "$out_file"
    kill -TERM "\$PPID" 2>/dev/null
    exit 0
fi
exec ${real_gio:-/usr/bin/gio} "\$@"
SHIM

chmod +x "$shadow_dir/xdg-open" "$shadow_dir/gio"

start_path="${2:-.}"
if [[ -f "$start_path" ]]; then
    start_path=$(dirname "$start_path")
fi

# Elio 1.3.0's CLI is `elio [OPTIONS]` — no positional path arg yet.
# Defaults to $PWD, so cd in.
cd "$start_path" || cd "$HOME"
PATH="$shadow_dir:$PATH" elio

if [[ -s "$out_file" ]]; then
    picked=$(printf '%q ' "$(cat "$out_file")")
    zellij action toggle-floating-panes
    zellij action write 27 # <Escape>
    zellij action write-chars ":$1 $picked"
    zellij action write 13 # <Enter>
else
    zellij action toggle-floating-panes
fi
