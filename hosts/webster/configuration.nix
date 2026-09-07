{ inputs, ... }:

{
  imports = [
    ../../modules/core/common.nix
    ../../modules/hardware/nfs.nix
    ../../modules/hardware/vm-guest.nix
    ../../modules/hardware/vm-disks.nix
    ../../modules/services/microbin.nix
    ../../modules/services/nextcloud.nix
    ../../modules/services/open-webui.nix
    ../../modules/services/podman.nix
    ../../modules/services/static-sites.nix
    ../../modules/services/suwayomi.nix
    ../../modules/services/trumpet-snipes.nix
  ];

  nfs.shares = {
    copyparty = "copyparty";
    manga = "manga";
  };

  networking.hostName = "webster";
  openWebui.ollamaUrl = "http://bread:11434";

  staticSites = {
    alpd.port = 8417;
    givememoney.port = 8418;
    seth = {
      port = 8101;
      source = inputs.site-seth + "/website";
    };
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

  virtualisation.oci-containers.containers.vaultwarden = {
    image = "vaultwarden/server:latest";
    environment = {
      DOMAIN = "https://vault.armaanlala.tech";
      SIGNUPS_ALLOWED = "true";
    };
    volumes = [ "/var/lib/vaultwarden:/data" ];
    ports = [ "11001:80" ];
  };

  networking.firewall.allowedTCPPorts = [ 11001 ];

  system.stateVersion = "25.05";
}
