{ config, lib, pkgs, ... }:
let
  appConfigs = "${config.home.homeDirectory}/dotfiles-nixos/user/apps/terminal/configs/herdr-app";
  mods = builtins.attrNames (lib.filterAttrs (_: type: type == "directory")
    (builtins.readDir ./configs/herdr-app/mods));
  layouts = builtins.attrNames (lib.filterAttrs
    (name: type: type == "regular" && (lib.hasSuffix ".json" name || lib.hasSuffix ".svg" name))
    (builtins.readDir ./configs/herdr-app/layouts));
  assets = map (name: "mods/${name}") mods ++ map (name: "layouts/${name}") layouts;
in
{
  home.packages = [ pkgs.nodejs pkgs.python3
    (pkgs.writeShellScriptBin "herdr-jira" ''
      export HERDR_JIRA_ACLI=${pkgs.acli}/bin/acli
      exec ${pkgs.nodejs}/bin/node "${appConfigs}/mods/jira-tickets/helper.mjs" "$@"
    '')
  ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.xdg-utils ];

  # Direct links accept an already-linked checkout and keep atomic app writes
  # outside the store. Shipped files, layout state and caches stay local.
  home.activation.herdrAppLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.bash}/bin/bash ${./configs/herdr-app/link.sh} \
      ${lib.escapeShellArg appConfigs} \
      ${lib.escapeShellArg "${config.home.homeDirectory}/.config/herdr-app"} \
      ${lib.escapeShellArgs assets}
  '';
}
