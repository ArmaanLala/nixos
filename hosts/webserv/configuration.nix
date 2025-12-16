# webserv - web server host
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/auto-upgrade.nix
    ../../modules/vm-config.nix
    ../../modules/vm-hardware-config.nix
  ];

  networking.hostName = "webserv";

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;
    environment = {
      OLLAMA_BASE_URL = "http://beef:11434";
    };
  };

  # Open firewall for LAN access
  networking.firewall.allowedTCPPorts = [ 8080 ];

  system.stateVersion = "25.05";
}
