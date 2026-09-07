{ lib, ... }:
let
  mediaWriters = [
    "radarr"
    "sonarr"
    "bazarr"
  ];

  indexers = [ "prowlarr" ];
in
{
  services =
    lib.genAttrs mediaWriters (_: {
      enable = true;
      openFirewall = true;
      user = "armaan";
      group = "armaan";
    })
    // lib.genAttrs indexers (_: {
      enable = true;
      openFirewall = true;
    });
}
