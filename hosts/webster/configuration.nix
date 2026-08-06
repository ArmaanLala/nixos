# webster - web server host
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
    # copyparty the service is gone, but its data is not — the share stays
    # mounted so the files remain reachable.
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

  # Vaultwarden. TLS is terminated by Cloudflare and the tunnel daemon runs on a
  # separate VM, so this listens on the LAN rather than loopback.
  services.vaultwarden = {
    enable = true;
    # Sets DOMAIN = "https://vault.armaanlala.tech" — used for invite/reset links
    # and as the WebAuthn origin, so it must match the Cloudflare hostname exactly.
    domain = "vault.armaanlala.tech";
    backupDir = "/var/local/vaultwarden/backup";
    # ADMIN_TOKEN (and any SMTP secrets) live here rather than in the nix store.
    # Nothing provisions this file — it must be created by hand on the host.
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
