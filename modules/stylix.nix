# Stylix - unified theming across all applications
{ pkgs, ... }:

{
  stylix = {
    enable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/framer.yaml";
  };
}
