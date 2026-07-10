{ lib, writeShellScriptBin, nodejs, which }:

writeShellScriptBin "lazypi" ''
  # LazyPi itself is a one-shot npx installer; this wrapper keeps it on PATH
  # and ensures the node/npm toolchain it shells out to is available. lazypi
  # probes for `pi` via `which`, which minimal environments (home-manager
  # activation) don't have — without it the probe fails and lazypi falls back
  # to `npm install -g`, which EACCESes on the read-only nix store.
  export PATH="${lib.makeBinPath [ nodejs which ]}:$PATH"
  exec npx @robzolkos/lazypi "$@"
''
