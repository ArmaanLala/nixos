# Declarative disk layout for bread's Samsung 980 PRO.
#
# SCOPE: this file describes /dev/nvme0n1 ONLY. The second NVMe (nvme1n1, a
# Crucial P3 holding a Windows install + its recovery partition) is deliberately
# absent, so `disko --mode destroy` cannot reach it. Windows' bootloader does
# NOT live there though -- it is /EFI/Microsoft on the ESP below, which a
# reformat destroys. Back that directory up and restore it afterwards or Windows
# stops booting; hosts/bread/README-reinstall.md has the procedure.
{ ... }:
let
  # Every mountOptions list must be complete: disko passes it through verbatim
  # instead of merging in a default, so dropping space_cache=v2 from one of
  # these silently reverts that subvolume to the v1 cache.
  btrfsBase = [
    "ssd"
    "discard=async"
    "space_cache=v2"
  ];
  btrfsOpts = btrfsBase ++ [ "relatime" ];
in
{
  disko.devices.disk.main = {
    # by-id, not /dev/nvme0n1: the two NVMes enumerate in whatever order the
    # controller feels like, and this is the one being wiped.
    device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S6B0NU0W945573Z";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          # 4G, not the 127M this machine shipped with. That 127M was shared
          # with Windows (/EFI/Microsoft is 32M), leaving ~94M for us, and a
          # single 6.18.49 kernel+initrd pair is ~41M -- so three generations
          # did not fit and the bootloader install failed mid-copy on
          # 2026-09-05. 4G holds ~90 generations with Windows still on it, and
          # costs 0.2% of a 2TB disk; there is no reason to be tight here.
          #
          # Side effect worth knowing: mkfs.vfat picks FAT32 at this size, where
          # the old 127M ESP was FAT16. Both are fine for UEFI.
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
            # -f overwrites any existing signature on a re-run; -L gives
            # /partition-root below a stable device to mount, since the UUID is
            # not known until mkfs has actually run.
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
                # noatime, not relatime: nothing in the store reads atimes, so
                # the extra writes are pure cost on an SSD.
                mountOptions = btrfsBase ++ [ "noatime" ];
              };

              # The swapfile needs a nodatacow subvolume of its own -- btrfs
              # refuses to swapon a file on a normal one. disko creates
              # /.swapvol/swapfile and registers it in swapDevices.
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

  # The btrfs top level (subvolid=5), so `btrfs subvolume list/delete` can see
  # every subvolume without juggling temporary mounts. Not managed by disko: it
  # has no concept of mounting the root of the filesystem itself, which is why
  # this is a plain fileSystems entry and why the -L label above exists.
  fileSystems."/partition-root" = {
    device = "/dev/disk/by-label/bread";
    fsType = "btrfs";
    # nofail because this is a convenience mount, not something boot needs. The
    # label only exists after disko has run, so without it a machine that has
    # not been reformatted yet hangs in the mount unit instead of booting.
    options = [
      "subvol=/"
      "nofail"
    ]
    ++ btrfsOpts;
  };
}
