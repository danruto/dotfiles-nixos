{ lib, pkgs, ... }:

let
  # gpg-agent only caches passphrases in memory, so an encrypted SSH key is
  # re-prompted after any cache flush or agent restart. The dsok-pb passphrase
  # is kept in ~/.ssh/dsok-pb.pass (0600, created by hand, not managed here);
  # this presets it into the agent at login so background callers (herdr's SSH
  # machines, agent shells with no tty) never hit a pinentry they cannot answer.
  presetSshPassphrase = pkgs.writeShellScript "gpg-preset-ssh-passphrase" ''
    set -eu
    export PATH=${lib.makeBinPath [ pkgs.gnupg pkgs.gawk ]}:$PATH

    pass_file="$HOME/.ssh/dsok-pb.pass"
    [ -r "$pass_file" ] || exit 0
    pass="$(cat "$pass_file")"
    [ -n "$pass" ] || exit 0

    gpg-connect-agent 'KEYINFO --ssh-list' /bye 2>/dev/null |
      awk '/^S KEYINFO/ { print $3 }' |
      while read -r grip; do
        printf '%s' "$pass" | gpg-preset-passphrase --preset "$grip" || true
      done
  '';
in
{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
    settings = {
      # Required by the preset service below.
      allow-preset-passphrase = "";
      # Keep the in-memory cache alive so the key survives a full day's work
      # and one prompt per login is the worst case.
      default-cache-ttl = 86400;
      max-cache-ttl = 604800;
      default-cache-ttl-ssh = 86400;
      max-cache-ttl-ssh = 604800;
    };
  };

  # secret-tool and other libsecret clients.
  environment.systemPackages = [ pkgs.libsecret ];

  systemd.user.services.gpg-preset-ssh-passphrase = {
    description = "Preset the SSH key passphrase into gpg-agent from ~/.ssh/dsok-pb.pass";
    after = [ "gpg-agent.service" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = presetSshPassphrase;
    };
  };
}
