# Drapion - workstation: Ryzen 7800X3D, RX 7900 XTX, 1.8TB NVMe (btrfs)
{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/common.nix
    ../../modules/hardware/nfs.nix
    ../../modules/roles/desktop.nix
    ../../modules/roles/dev.nix
    ../../modules/roles/gaming.nix
    ../../modules/services/libvirt.nix
    ../../modules/services/ollama.nix
  ];

  nfs.shares = {
    buzz = "phub";
    games = "games";
    immich = "immich";
    media = "arr";
    manga = "manga";
    nightbeef = "nightbeef";
  };

  networking.hostName = "drapion";
  services.udisks2.enable = true;

  # ROCm bits live in modules/services/ollama.nix
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.amdgpu.opencl.enable = true;

  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  environment.systemPackages = with pkgs; [
    calibre
    gimp3
    sbctl
    discord
    claude-code
    grimblast
    quickemu
    godot
    arduino-ide
    koboldcpp
    hashcat
  ];

  services.gnome.gnome-keyring.enable = false;

  services.openssh.settings.PasswordAuthentication = lib.mkForce true;

  # Keyboard firmware flashing needs these udev rules
  services.udev.packages = with pkgs; [
    qmk
    qmk-udev-rules
    qmk_hid
    via
    vial
  ];

  system.stateVersion = "25.11";
}
