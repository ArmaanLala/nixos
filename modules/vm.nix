# VM-specific configuration (QEMU/KVM guests)
# Combines guest config and optional generic hardware
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  options.vm = {
    useGenericHardware = lib.mkEnableOption "generic VM hardware config (disk labels)" // {
      default = true;
    };
  };

  config = lib.mkMerge [
    # QEMU guest config (always applied for VMs)
    {
      services.qemuGuest.enable = true;
      boot.growPartition = true;
      fileSystems."/".autoResize = true;
    }

    # Generic hardware (label-based disks) - optional
    (lib.mkIf config.vm.useGenericHardware {
      boot.initrd.availableKernelModules = [
        "uhci_hcd"
        "ehci_pci"
        "ahci"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      boot.kernelModules = [ "kvm-amd" ];

      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [
        { device = "/dev/disk/by-label/swap"; }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    })
  ];
}
