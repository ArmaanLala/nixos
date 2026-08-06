# Paperless-ngx document server.
#
# The admin password is the bootstrap credential only — it is applied on every
# activation, so changing it in the web UI is undone on the next rebuild. Change
# it here instead. There is no openFirewall option in the upstream module, hence
# the explicit port.
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
