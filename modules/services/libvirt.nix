# libvirt/QEMU virtualisation host with virt-manager.
{ ... }:

{
  programs.virt-manager.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  users.groups.libvirtd.members = [ "armaan" ];
}
