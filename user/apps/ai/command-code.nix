{ lib, stdenv, buildNpmPackage, fetchurl, autoPatchelfHook, libgcc }:

# Upstream publishes no lockfile and its devDependencies point at unpublished
# workspace packages, so npm ci can't use the tarball as-is. The committed
# lockfile is generated from the tarball's runtime deps only.
# To bump: ./bump-command-code.sh [version]
buildNpmPackage (finalAttrs: {
  pname = "command-code";
  version = "1.88.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/command-code/-/command-code-${finalAttrs.version}.tgz";
    hash = "sha512-B/+JVQecxHlkouzsVnFsRlxZ3e8VY35Grr934T1fx+c8aq4Em9kxI79B1gQ195xW50f3Svq8qc8j0QThSpNjWw==";
  };

  npmDepsHash = "sha256-qLoVgrKdDN3qfhRC0YqGlaMH4vjuGfKdZ5YjKp2THZ0=";

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
