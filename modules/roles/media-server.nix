# Media server configuration (*arr stack)
{ lib, ... }:
let
  # These write into the NFS media tree, so they share the armaan identity
  # rather than each running as its own service user.
  mediaWriters = [
    "radarr"
    "sonarr"
    "bazarr"
  ];

  # Indexer proxy — touches no media, so it keeps its own user.
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
