{ lib, pkgs, ... }:
let
  # Upstream's flake builds on aarch64-linux but ships node-pty without its
  # native binary, so the daemon crashes on start. The npm tarball carries
  # linux-arm64 prebuilds, so run it through npx like lazypi. Bump: edit version.
  paseo = pkgs.writeShellScriptBin "paseo" ''
    export PATH="${lib.makeBinPath [ pkgs.nodejs ]}:$PATH"
    exec npx -y @getpaseo/cli@0.7.2 "$@"
  '';
in
{
  home.packages = [ paseo ];

  # Paseo Desktop on the Mac reaches this via Settings → Add host → Remote SSH
  # (ssh://nearmap@orb) and tunnels to the daemon's default 127.0.0.1:6767, so
  # nothing is exposed on the network and no relay or password is needed.
  systemd.user.services.paseo = {
    Unit.Description = "paseo daemon";
    Service = {
      # Agents inherit the daemon's environment, so start it from a login fish
      # shell to get the same PATH (cargo, go, nix profiles) as the terminal.
      ExecStart = "${pkgs.fish}/bin/fish -lc 'exec ${paseo}/bin/paseo daemon start --foreground --no-relay'";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
