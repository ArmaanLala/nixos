# Drapion - Desktop workstation with AMD GPU
# Hardware: Ryzen 7 7800X3D, AMD GPU, 1.8TB NVMe (btrfs)
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
    games = "games";
    immich = "immich";
    media = "arr";
    manga = "manga";
    nightbeef = "nightbeef";
  };

  networking.hostName = "drapion";
  services.udisks2.enable = true;

  # Drapion uses systemd-boot (default from common.nix). The btrfs root is a
  # stock nixos-generate-config hardware file with a by-uuid device — there is
  # no disko in this repo.

  # AMD GPU (ROCm bits live in services/ollama.nix)
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.amdgpu.opencl.enable = true;

  # Bluetooth
  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # Drapion-specific packages
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

  # QMK/VIA/Vial udev rules for keyboard firmware
  services.udev.packages = with pkgs; [
    qmk
    qmk-udev-rules
    qmk_hid
    via
    vial
  ];

  system.stateVersion = "25.11";
}
