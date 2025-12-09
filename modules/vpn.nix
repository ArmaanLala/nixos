# Base VPN namespace for download clients
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
  };
}
