# VM-specific configuration (QEMU/KVM guests)
{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  services.qemuGuest.enable = true;

  # Automatically resize the root filesystem
  fileSystems."/".autoResize = true;
}
