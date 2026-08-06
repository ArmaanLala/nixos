# VPN namespace and the download client confined to it.
#
# NOT self-contained: `vpnNamespaces` is defined by vpn-confinement, which
# flake.nix adds to atlas only. Importing this from a second host fails with
# "option does not exist" — add vpn-confinement.nixosModules.default to that
# host's module list in flake.nix too.
{ ... }:

{
  vpnNamespaces.wg = {
    enable = true;
    # Deliberately a quoted STRING, not a path literal. As a string it is
    # interpolated into a runtime shell script, so the secret never enters
    # /nix/store. As a bare path it fails evaluation on every host with
    # "access to absolute path ... is forbidden in pure evaluation mode".
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
