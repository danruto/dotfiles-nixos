{ lib, stdenv, buildNpmPackage, fetchurl, autoPatchelfHook, libgcc }:

# Upstream publishes no lockfile and its devDependencies point at unpublished
# workspace packages, so npm ci can't use the tarball as-is. The committed
# lockfile is generated from the tarball's runtime deps only.
# To bump: ./bump-command-code.sh [version]
buildNpmPackage (finalAttrs: {
  pname = "command-code";
  version = "1.88.5";

  src = fetchurl {
    url = "https://registry.npmjs.org/command-code/-/command-code-${finalAttrs.version}.tgz";
    hash = "sha512-399jzQF1j4g2qAuE45vy5BWaPzS/rqMZJIui2MHe0oIUaY1vu8mz45SE0gNIXIZ0BuqhfdlZ6zpnE43fhnlBYQ==";
  };

  npmDepsHash = "sha256-d/CgJKEADO8OQAx7GwttnlMhMgMFh9M714HhX7ihs5c=";

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
