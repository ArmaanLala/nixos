# Suwayomi manga server, plus the Flaresolverr instance it proxies through.
#
# Needs a container backend — import services/podman.nix alongside this. Also
# expects the `manga` NFS share, which holds the download library.
{ ... }:

{
  virtualisation.oci-containers.containers = {
    suwayomi = {
      image = "ghcr.io/suwayomi/suwayomi-server:preview";
      environment = {
        TZ = "Etc/UTC";
        FLARESOLVERR_ENABLED = "true";
        FLARESOLVERR_URL = "http://flaresolverr:8191";
      };
      volumes = [
        "/var/lib/suwayomi:/home/suwayomi/.local/share/Tachidesk"
        "/mnt/manga/suwayomi:/home/suwayomi/.local/share/Tachidesk/downloads"
      ];
      ports = [ "4567:4567" ];
    };
    flaresolverr = {
      image = "ghcr.io/thephaseless/byparr:latest";
      environment.TZ = "Etc/UTC";
    };
  };

  networking.firewall.allowedTCPPorts = [ 4567 ];
}
