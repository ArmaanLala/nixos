# Webster - misc web services VM
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
    # copyparty the service is gone; its data isn't — keep the share mounted.
    copyparty = "copyparty";
    manga = "manga";
  };

  networking.hostName = "webster";
  openWebui.ollamaUrl = "http://beard:11434";

  staticSites = {
    alpd.port = 8417;
    givememoney.port = 8418;
    # trumpet-snipes is declared in its own module (it has a JSON updater).
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

  # Vaultwarden does not work as the native NixOS service here, so it runs from
  # the upstream image (podman, via oci-containers). Straight translation of the
  # old iris.yaml compose. TLS terminates at Cloudflare; the tunnel runs on
  # another VM and reaches this over the LAN on 11001.
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
