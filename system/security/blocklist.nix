{ config, blocklist-hosts, pkgs, ... }:

let blocklist = builtins.readFile "${blocklist-hosts}/alternates/fakenews-gambling/hosts";
in
{
  networking.extraHosts = ''
    "${blocklist}"
  '';
}
