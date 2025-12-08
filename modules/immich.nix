# Immich photo management
{ ... }:

{
  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = true;
    host = "0.0.0.0";
    mediaLocation = "/mnt/immich/media";
  };

  # Ensure media directory exists with correct permissions
  # TODO(human): Verify immich user/group ownership
  systemd.tmpfiles.rules = [
    "d /mnt/immich/media 0755 immich immich -"
  ];
}
