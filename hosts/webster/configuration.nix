# Webster - misc web services VM
{ ... }:

{
  imports = [
    ../../modules/core/common.nix
    ../../modules/hardware/nfs.nix
    ../../modules/hardware/vm-guest.nix
    ../../modules/hardware/vm-disks.nix
    ../../modules/services/open-webui.nix
    ../../modules/services/podman.nix
    ../../modules/services/static-sites.nix
    ../../modules/services/suwayomi.nix
  ];

  nfs.shares = {
    # copyparty the service is gone; its data isn't — keep the share mounted.
    copyparty = "copyparty";
    manga = "manga";
  };

  networking.hostName = "webster";
  openWebui.ollamaUrl = "http://drapion:11434";

  staticSites = {
    alpd.port = 8417;
    givememoney.port = 8418;
  };

  services.vikunja = {
    enable = true;
    frontendScheme = "http";
    frontendHostname = "localhost";
  };

  services.actual = {
    enable = true;
    openFirewall = true;
  };

  # TLS terminates at Cloudflare and the tunnel runs on another VM, so this
  # binds the LAN, not loopback.
  services.vaultwarden = {
    enable = true;
    # WebAuthn origin — must match the Cloudflare hostname exactly.
    domain = "vault.armaanlala.tech";
    backupDir = "/var/local/vaultwarden/backup";
    # ADMIN_TOKEN etc., created by hand on the host — see docs/secrets.md.
    environmentFile = "/var/lib/vaultwarden/vaultwarden.env";
    config = {
      SIGNUPS_ALLOWED = false;
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
    };
  };

  networking.firewall.allowedTCPPorts = [ 8222 ];

  system.stateVersion = "25.05";
}
