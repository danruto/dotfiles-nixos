{ ... }:
{
  # DMS provides its own polkit agent; disable niri-flake's default to avoid conflicts.
  systemd.user.services.niri-flake-polkit.enable = false;
}
