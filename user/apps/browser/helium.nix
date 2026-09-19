{ helium, pkgs, ... }:

let
  heliumBase = helium.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # VA-API hardware video decode for HEVC playback. Chromium only honours the
  # last --enable-features flag, so the upstream wrapper's
  # WaylandWindowDecorations must be repeated here.
  heliumVaapi = pkgs.symlinkJoin {
    name = "helium-vaapi";
    paths = [ heliumBase ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Chromium's libqt6_shim.so segfaults when the session's Qt6CT platform
      # theme/plugin vars leak in (QT_QPA_PLATFORMTHEME=qt5ct -> libqt6ct).
      # Clear all three so helium starts under the DMS/niri session.
      #
      # Launchers spawned from the DMS session have no DISPLAY
      # and the upstream --ozone-platform-hint=auto cannot detect Wayland there
      # because XDG_SESSION_TYPE is unset, so helium falls back to X11 and dies
      # with "Missing X server or $DISPLAY". Pin the ozone platform at runtime
      # when a Wayland socket is present; leave X11 sessions untouched.
      wrapProgram $out/bin/helium \
        --unset QT_PLUGIN_PATH \
        --unset QT_QPA_PLATFORMTHEME \
        --unset QT_STYLE_OVERRIDE \
        --add-flags "--enable-features=WaylandWindowDecorations,VaapiVideoDecodeLinuxGL,PlatformHEVCDecoderSupport" \
        --run 'if [ -n "''${WAYLAND_DISPLAY:-}" ]; then set -- "$@" --ozone-platform=wayland; fi'
    '';
  };
in
{
  environment.systemPackages = [ heliumVaapi ];
}
