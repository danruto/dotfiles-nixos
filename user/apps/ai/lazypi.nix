{ lib, writeShellScriptBin, nodejs }:

writeShellScriptBin "lazypi" ''
  # LazyPi itself is a one-shot npx installer; this wrapper keeps it on PATH
  # and ensures the node/npm toolchain it shells out to is available.
  export PATH="${lib.makeBinPath [ nodejs ]}:$PATH"
  exec npx @robzolkos/lazypi "$@"
''
