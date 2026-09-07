{ ... }:
let
  btrfsBase = [
    "ssd"
    "discard=async"
    "space_cache=v2"
  ];
  btrfsOpts = btrfsBase ++ [ "relatime" ];
in
{
  disko.devices.disk.main = {
    device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S6B0NU0W945573Z";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size = "4G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };

        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "-f"
              "-L"
              "bread"
            ];

            subvolumes = {
              "/rootfs" = {
                mountpoint = "/";
                mountOptions = btrfsOpts;
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = btrfsOpts;
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = btrfsBase ++ [ "noatime" ];
              };

              "/swap" = {
                mountpoint = "/.swapvol";
                mountOptions = btrfsOpts;
                swap.swapfile.size = "4G";
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/partition-root" = {
    device = "/dev/disk/by-label/bread";
    fsType = "btrfs";
    options = [
      "subvol=/"
      "nofail"
    ]
    ++ btrfsOpts;
  };
}
