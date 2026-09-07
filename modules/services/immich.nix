{ ... }:

{
  nixpkgs.config.permittedInsecurePackages = [ "immich-2.7.5" ];

  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = true;
    host = "0.0.0.0";
    mediaLocation = "/mnt/immich/media";
  };

  systemd.services.immich-server = {
    after = [ "mnt-immich.mount" ];
    requires = [ "mnt-immich.mount" ];
  };
}
