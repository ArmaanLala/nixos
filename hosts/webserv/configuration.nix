# webserv - web server host
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/vm-config.nix
    ../../modules/vm-hardware-config.nix
  ];

  networking.hostName = "webserv";
  services.open-webui.enable = true;

  system.stateVersion = "25.05";
}
