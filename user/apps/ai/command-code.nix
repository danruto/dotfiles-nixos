{ lib, stdenv, buildNpmPackage, fetchurl, autoPatchelfHook, libgcc }:

# Upstream publishes no lockfile and its devDependencies point at unpublished
# workspace packages, so npm ci can't use the tarball as-is. The committed
# lockfile is generated from the tarball's runtime deps only.
# To bump: ./bump-command-code.sh [version]
buildNpmPackage (finalAttrs: {
  pname = "command-code";
  version = "1.77.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/command-code/-/command-code-${finalAttrs.version}.tgz";
    hash = "sha512-AnoZ7and+cO4JPzq+tMDo+moNInM2DH6B1lRDlkTEXb0IerYitbWvYWzXiu3odVcH36F7odBecq+hsU796h8gg==";
  };

  npmDepsHash = "sha256-scLM5w685yN2B49lga5huoSvO/isZoUSdiX4g6pGUAo=";

  postPatch = ''
    cp ${./command-code-package-lock.json} package-lock.json
    sed -i '/"devDependencies": {/,/^  }/d' package.json
  '';

  dontNpmBuild = true;
  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = lib.optional stdenv.hostPlatform.isLinux libgcc.lib; # @crosscopy/clipboard .node

  meta = {
    description = "Coding agent that continuously learns your coding taste";
    homepage = "https://commandcode.ai/docs";
    mainProgram = "cmd";
  };
})
