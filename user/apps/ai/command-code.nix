{ lib, stdenv, buildNpmPackage, fetchurl, autoPatchelfHook, libgcc }:

# Upstream publishes no lockfile and its devDependencies point at unpublished
# workspace packages, so npm ci can't use the tarball as-is. The committed
# lockfile was generated from the tarball's runtime deps only:
#   npm pack command-code@<ver> && tar xzf command-code-<ver>.tgz && cd package
#   sed -i '/"devDependencies": {/,/^  }/d' package.json
#   npm install --package-lock-only --ignore-scripts
# Bumping means a new version, src hash, regenerated lockfile and npmDepsHash.
buildNpmPackage (finalAttrs: {
  pname = "command-code";
  version = "1.38.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/command-code/-/command-code-${finalAttrs.version}.tgz";
    hash = "sha512-Ijsy8V4t8/GX+txrUdp36iYiKIVHHqXHA1FXUuuvZKf/NJhP5EpOPHDwEW8fku17ZIGF9WklX2vN52evIkcYog==";
  };

  npmDepsHash = "sha256-tzhYemQ3fZ/IddjIYHmOfk5T8jeT+KCRmwN7QbO7uek=";

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
