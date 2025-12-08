# VM-specific configuration (QEMU/KVM guests)
{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  services.qemuGuest.enable = true;

  # Automatically grow partition and resize the root filesystem
  boot.growPartition = true;
  fileSystems."/".autoResize = true;
}
