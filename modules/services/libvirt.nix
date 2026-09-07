{ config, ... }:

{
  programs.virt-manager.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  users.groups.libvirtd.members = [ "armaan" ];

  systemd.services.libvirtd.postStart =
    let
      virsh = "${config.virtualisation.libvirtd.package}/bin/virsh";
    in
    ''
      ${virsh} net-autostart default
      ${virsh} net-start default || true
    '';
}
