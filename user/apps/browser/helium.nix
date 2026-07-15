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
      wrapProgram $out/bin/helium \
        --add-flags "--enable-features=WaylandWindowDecorations,VaapiVideoDecodeLinuxGL,PlatformHEVCDecoderSupport"
    '';
  };
in
{
  environment.systemPackages = [ heliumVaapi ];
}
