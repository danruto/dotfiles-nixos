{ ... }:
{
  # font-family = "Departure Mono"
  # font-family = "Iosevka Comfy"
  home.file.".config/ghostty/config".text = ''
    font-family = "DejaVu Sans Mono"
    font-size = 12

    macos-option-as-alt = left
    keybind = alt+left=unbind
    keybind = alt+right=unbind

    window-decoration = "none"
  '';
}
