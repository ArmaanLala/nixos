{ ... }:

{
  # nixos-26.05 ships Immich 2.7.5, now EOL and flagged for CVE-2026-59258 /
  # CVE-2026-82272. Immich 3.x needs the module from 26.11+, so this is a
  # deliberate hold, not an oversight -- immich here is LAN-only (openFirewall,
  # not on the Cloudflare tunnel). TODO: bump to 3.x when this repo moves to
  # 26.11, or pull both package and module from unstable.
  nixpkgs.config.permittedInsecurePackages = [ "immich-2.7.5" ];

  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = true;
    host = "0.0.0.0";
    mediaLocation = "/mnt/immich/media";
  };

  # mediaLocation is on an NFS automount. Delay immich, not tmpfiles-setup —
  # ordering tmpfiles after the mount cycles (tmpfiles → sysinit → basic →
  # NetworkManager-wait-online → mnt-immich.mount → tmpfiles) and systemd breaks
  # the cycle by dropping a job at random.
  systemd.services.immich-server = {
    after = [ "mnt-immich.mount" ];
    requires = [ "mnt-immich.mount" ];
  };
}
