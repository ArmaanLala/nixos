# Stylix - unified theming across all applications
{ pkgs, lib, ... }:
{
  stylix = {
    enable = true;

    polarity = "dark";

    base16Scheme = "${pkgs.base16-schemes}/share/themes/framer.yaml";
  };

  # Force dark mode for GTK/QT apps
}
