# LAN-only: nginx serves it over plain HTTP on port 80, no Cloudflare tunnel.
# Unlike paperless, the admin password below is only read once, during
# nextcloud-setup's initial install — changing it in the web UI afterwards sticks.
{ pkgs, ... }:

{
  environment.etc."nextcloud-admin-pass".text = "admin";

  services.nextcloud = {
    enable = true;
    # There is no `pkgs.nextcloud`; the version is pinned by hand and may only be
    # bumped one major at a time. stateVersion 25.05 would default this to
    # nextcloud31, which warns on every eval that it is a release behind — this
    # is a fresh install, so start on the current one.
    package = pkgs.nextcloud32;
    hostName = "webster";

    config = {
      adminpassFile = "/etc/nextcloud-admin-pass";
      dbtype = "pgsql";
    };
    # Provisions the local postgres instance and the nextcloud role in it.
    database.createLocally = true;

    settings = {
      # Without these three, Nextcloud's own admin overview page reports warnings.
      default_phone_region = "US";
      log_type = "systemd";
      # Hour (UTC) for the nightly background jobs — 05:00 America/Los_Angeles.
      maintenance_window_start = 13;
      # hostName is trusted implicitly; this is for reaching it by IP.
      trusted_domains = [ "10.0.0.111" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
