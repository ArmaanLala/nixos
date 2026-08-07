# NOT self-contained: `vpnNamespaces` comes from vpn-confinement, which flake.nix
# adds to atlas only. A second host importing this must get that module added in
# flake.nix too, or evaluation fails with "option does not exist".
{ ... }:

{
  vpnNamespaces.wg = {
    enable = true;
    # Quoted STRING, not a path literal: as a string it is read at runtime so the
    # secret stays out of /nix/store; a bare path fails pure evaluation.
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
