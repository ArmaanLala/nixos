# webserv - web server host
{ pkgs, copyparty, ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/vm.nix
    ../../modules/nfs.nix
    ../../modules/podman.nix
  ];

  nixpkgs.overlays = [ copyparty.overlays.default ];

  nfsMounts = {
    "/mnt/copyparty" = "10.0.0.160:/mnt/wdblue/copyparty";
  };

  networking.hostName = "webserv";

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;
    environment = {
      OLLAMA_BASE_URL = "http://beef:11434";
    };
  };

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
    8080
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
      volumes = [ "/var/lib/suwayomi:/home/suwayomi/.local/share/Tachidesk" ];
      ports = [ "4567:4567" ];
    };
    flaresolverr = {
      image = "ghcr.io/thephaseless/byparr:latest";
      environment.TZ = "Etc/UTC";
    };
  };

  system.stateVersion = "25.05";
}
