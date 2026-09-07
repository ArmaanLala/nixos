{ modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  services.qemuGuest.enable = true;
  boot.growPartition = true;
  fileSystems."/".autoResize = true;
}
