# VPN-confined sabnzbd
{ ... }:

{
  vpnNamespaces.wg.portMappings = [
    {
      from = 8081;
      to = 8081;
    }
  ];

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
