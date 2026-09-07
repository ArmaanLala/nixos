{ ... }:

{
  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = "/etc/nixos/secrets/proton.conf";
    accessibleFrom = [ "10.0.0.0/24" ];
    openVPNPorts = [
      {
        port = 60434;
        protocol = "both";
      }
    ];
    portMappings = [
      {
        from = 8081;
        to = 8081;
      }
    ];
  };

  services.sabnzbd = {
    enable = true;
    user = "armaan";
    group = "armaan";
  };

  systemd.services.sabnzbd.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };
}
