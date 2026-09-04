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
  version = "1.45.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/command-code/-/command-code-${finalAttrs.version}.tgz";
    hash = "sha512-tsRH0ygyAWKAm4uQ3HqO5HCVmqxytWE+Z1qDffK6bBKCdl6/CQFjF6BmIh2QwTpvgZPYlE2alVFYuxzGKzOBhw==";
  };

  npmDepsHash = "sha256-h563/dEB1HWSESIw8Uo+dSwcjrTAG2+yF+OZdsHQmz0=";

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
