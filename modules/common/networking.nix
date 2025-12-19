# Networking configuration: NetworkManager, Tailscale, firewall, Avahi
{ lib, ... }:

{
  services.tailscale.enable = true;
  networking.networkmanager.enable = true;
  networking.firewall.enable = lib.mkDefault true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };
}
