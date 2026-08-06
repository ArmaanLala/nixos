# QEMU/KVM guest integration. Safe for any VM, regardless of how its disks are
# laid out — import this on every virtual host.
{ modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  services.qemuGuest.enable = true;
  boot.growPartition = true;
  fileSystems."/".autoResize = true;
}
