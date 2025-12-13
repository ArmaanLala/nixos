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
  services.open-webui.enable = true;

  services.open-webui = {
    enable = true;
    host = "0.0.0.0"; # Bind to all interfaces
    port = 8080;
    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434"; # Point to local Ollama
    };
  };

  # Open firewall for LAN access
  networking.firewall.allowedTCPPorts = [ 8080 ];

  system.stateVersion = "25.05";
}
