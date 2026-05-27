{ ... }:

{
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;
    environment = {
      OLLAMA_BASE_URL = "http://drapion:11434";
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
