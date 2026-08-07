# The admin password is re-applied on every activation, so changing it in the web
# UI is undone on the next rebuild — change it here. The upstream module has no
# openFirewall, hence the explicit port.
{ ... }:

{
  environment.etc."paperless-admin-pass".text = "admin";

  services.paperless = {
    enable = true;
    passwordFile = "/etc/paperless-admin-pass";
    port = 28981;
    address = "10.0.0.186";
  };

  networking.firewall.allowedTCPPorts = [ 28981 ];
}
