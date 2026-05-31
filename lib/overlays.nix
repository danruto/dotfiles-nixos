# Overlay lists, shared between the threaded pkgs instances (lib/mkPkgs.nix)
# and the system-level nixpkgs.overlays module (lib/mkSystem.nix).
{ inputs }:
let
  # Workaround for bug #437058 — skip i3ipc's pytest in the Nix build.
  i3ipcOverlay = (final: prev: {
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (python-final: python-prev: {
        i3ipc = python-prev.i3ipc.overridePythonAttrs (oldAttrs: {
          doCheck = false;
          checkPhase = ''
            echo "Skipping pytest in Nix build"
          '';
          installCheckPhase = ''
            echo "Skipping install checks in Nix build"
          '';
        });
      })
    ];
  });

  zjsbOverlay = (final: prev: {
    zjsb = inputs.zjsb.packages.${prev.stdenv.hostPlatform.system}.default;
  });

  darwinOverlay = (final: prev: {
    direnv = prev.direnv.overrideAttrs (oldAttrs: {
      env = (oldAttrs.env or { }) // {
        CGO_ENABLED = 1;
      };
      doCheck = false;
      doInstallCheck = false;
    });

    # macOS strips the linker-signed adhoc signature off fish's binary,
    # leaving a tainted page that the kernel rejects with SIGKILL on launch.
    # Re-sign as the final build step so the embedded hashes match the file.
    fish = prev.fish.overrideAttrs (oldAttrs: {
      postFixup = (oldAttrs.postFixup or "") + ''
        ${prev.darwin.sigtool}/bin/codesign --force --sign - $out/bin/fish
      '';
    });
  });

  common = [
    inputs.rust-overlay.overlays.default
    inputs.nur.overlays.default
    i3ipcOverlay
  ];
in
{
  inherit common;
  # The unstable channel additionally exposes the zjsb package.
  unstable = common ++ [ zjsbOverlay ];
  # Darwin system nixpkgs needs the direnv/fish fixups.
  darwin = common ++ [ darwinOverlay ];
}
