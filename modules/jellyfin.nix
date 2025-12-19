# Jellyfin media server
{ ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
}
