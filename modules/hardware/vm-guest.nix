# QEMU/KVM guest integration — safe on any VM; import on every virtual host.
{ modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  services.qemuGuest.enable = true;
  boot.growPartition = true;
  fileSystems."/".autoResize = true;
}
