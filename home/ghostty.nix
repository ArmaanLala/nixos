{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # Ghostty configuration
  # Note: Home-manager doesn't have a native ghostty module yet,
  # so we'll manage the config file directly
  xdg.configFile."ghostty/config".text = ''
    # Appearance
    background-opacity = 1
    background-blur = 20
    theme = Carbonfox

    # Font
    font-family = JetBrainsMono
    font-size = 16

    # Clipboard
    clipboard-read = allow
    clipboard-write = allow
    copy-on-select = false

    # Keybindings
    keybind = shift+enter=text:\x1b\r
  '' + lib.optionalString isDarwin ''
    # macOS-specific settings
    macos-option-as-alt = true
  '' + lib.optionalString (!isDarwin) ''
    # Linux-specific settings
    gtk-titlebar = false
  '';
}
