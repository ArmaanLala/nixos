{ ... }:

{
  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = true;
    host = "0.0.0.0";
    mediaLocation = "/mnt/immich/media";
  };

  # mediaLocation lives on an NFS automount. Do NOT put an ordering dependency on
  # systemd-tmpfiles-setup for this — it creates a cycle (tmpfiles-setup →
  # sysinit → basic → NetworkManager-wait-online → network-online →
  # mnt-immich.mount → tmpfiles-setup) that systemd breaks by dropping a job at
  # random. Delaying immich itself is the safe place to wait.
  systemd.services.immich-server = {
    after = [ "mnt-immich.mount" ];
    requires = [ "mnt-immich.mount" ];
  };
}
