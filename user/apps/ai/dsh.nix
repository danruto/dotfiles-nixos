{ lib, writeShellScriptBin, nodejs, pnpm, python3 }:

writeShellScriptBin "dsh" ''
  # DeepSeek Harness ships as an npm meta-package (@deepseek-ai/dsh) that pulls
  # in ~60 published plugin packages; the GitHub repo is a pnpm workspace with
  # a patches/ dir and native landlock code, so there is nothing sane to build
  # from source. Run the published CLI via npx instead, pinned to a version.
  # node-pty compiles through node-gyp on first install and needs python3 on
  # PATH (gcc/gnumake come from user/lang/cc), and `dsh plugin` forwards to
  # pnpm in the profile directory.
  export PATH="${lib.makeBinPath [ nodejs pnpm python3 ]}:$PATH"

  # dsh always boots a patch-file watcher backed by @deepseek-ai/cordis-plugin-hmr
  # (see runProfile in @deepseek-ai/dsh's profile-boot-*.js), which requires the
  # node --expose-internals flag or it throws on startup. Running it via plain
  # `npx ... dsh` executes bin.js through its `#!/usr/bin/env node` shebang,
  # which can't carry extra node flags, so resolve the installed entry point
  # first and invoke node on it directly with the flag.
  bin="$(npx --yes --package=@deepseek-ai/dsh@0.1.2-rc.1 -c 'realpath "$(command -v dsh)"')"
  exec node --expose-internals "$bin" "$@"
''
