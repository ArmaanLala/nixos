{ config, lib, ... }:

{
  options.openWebui.ollamaUrl = lib.mkOption {
    type = lib.types.str;
    default = "http://localhost:11434";
    description = "URL of the Ollama instance to connect to";
  };

  config = {
    services.open-webui = {
      enable = true;
      host = "0.0.0.0";
      port = 8080;
      environment = {
        OLLAMA_BASE_URL = config.openWebui.ollamaUrl;
      };
    };

    networking.firewall.allowedTCPPorts = [ 8080 ];
  };
}
