# Media server configuration (*arr stack)
{ ... }:

{
  services.radarr.enable = true;
  services.radarr.openFirewall = true;
  services.radarr.user = "armaan";
  services.radarr.group = "armaan";

  services.sonarr.enable = true;
  services.sonarr.openFirewall = true;
  services.sonarr.user = "armaan";
  services.sonarr.group = "armaan";

  services.prowlarr.enable = true;
  services.prowlarr.openFirewall = true;

  services.bazarr.enable = true;
  services.bazarr.openFirewall = true;

}
