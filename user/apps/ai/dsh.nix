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
  exec npx --yes @deepseek-ai/dsh@0.1.0-rc.6 "$@"
''
