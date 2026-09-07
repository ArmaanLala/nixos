{ pkgs, ... }:

{
  environment.etc."nextcloud-admin-pass".text = "admin";

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "webster";

    config = {
      adminpassFile = "/etc/nextcloud-admin-pass";
      dbtype = "pgsql";
    };
    database.createLocally = true;

    settings = {
      default_phone_region = "US";
      log_type = "systemd";
      maintenance_window_start = 13;
      trusted_domains = [ "10.0.0.111" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
