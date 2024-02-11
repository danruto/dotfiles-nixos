{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vial
  ];

  # Should have been installed from the above but it wasn't?
  # services.udev.extraRules = ''
  #   KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  # '';

  # services.udev.packages = with pkgs; [
  #   vial
  # ];
}
