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
