# webserv - web server host
{ pkgs, copyparty, ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/vm.nix
    ../../modules/nfs.nix
    ../../modules/podman.nix
    ../../modules/open-webui.nix
  ];

  nixpkgs.overlays = [ copyparty.overlays.default ];

  nfsMounts = {
    "/mnt/copyparty" = "truenas:/mnt/wdblue/copyparty";
    "/mnt/manga" = "truenas:/mnt/wdblue/manga";
  };

  networking.hostName = "webserv";
  openWebui.ollamaUrl = "http://drapion:11434";

  environment.systemPackages = [ pkgs.copyparty ];
  services.copyparty = {
    enable = true;
    settings = {
      i = "0.0.0.0";
      p = 3923;
    };
    volumes = {
      "/" = {
        path = "/mnt/copyparty";
        access = {
          rw = "*";
        };
        flags = {
          scan = 60;
          e2d = true;
        };
      };
    };
    openFilesLimit = 8192;
  };

  services.vikunja = {
    enable = true;
    frontendScheme = "http";
    frontendHostname = "localhost";
  };

  services.actual = {
    enable = true;
    openFirewall = true;
  };

  # Open firewall for LAN access
  networking.firewall.allowedTCPPorts = [
    3923
    4567
  ];

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

  system.stateVersion = "25.05";
}
