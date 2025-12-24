# webserv - web server host
{ pkgs, copyparty, ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/roles/vm-server.nix
    ../../modules/nfs.nix
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

  # Open firewall for LAN access
  networking.firewall.allowedTCPPorts = [
    8080
    3923
  ];

  system.stateVersion = "25.05";
}
