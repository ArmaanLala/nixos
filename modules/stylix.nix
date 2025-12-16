# Stylix - unified theming across all applications
{ pkgs, ... }:
{
  stylix = {
    enable = true;
    polarity = "dark";
    # image = /home/armaan/.config/wallpapers/a_painting_of_a_man_with_a_dripping_face.jpg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/framer.yaml";
  };
}
