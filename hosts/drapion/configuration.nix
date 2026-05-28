# Drapion - Desktop workstation with AMD GPU
# Hardware: Ryzen 7 7800X3D, AMD GPU, 1.8TB NVMe (btrfs)
{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/dev.nix
    ../../modules/gaming.nix
    ../../modules/nfs.nix
  ];

  nfsMounts = {
    "/mnt/games" = "10.0.0.160:/mnt/wdblue/games";
    "/mnt/immich" = "10.0.0.160:/mnt/wdblue/immich";
    "/mnt/media" = "10.0.0.160:/mnt/wdblue/arr";
    "/mnt/manga" = "10.0.0.160:/mnt/wdblue/manga";
    "/mnt/nightbeef" = "10.0.0.160:/mnt/wdblue/nightbeef";
  };

  services.udisks2.enable = true;
  networking.hostName = "drapion";

  # Drapion uses systemd-boot (default from common.nix) with btrfs via disko
  # No need to override bootloader settings

  # AMD GPU
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.amdgpu.opencl.enable = true;

  # Ollama with ROCm acceleration for AMD GPU (package selects ROCm backend)
  services.ollama = {
    package = pkgs.ollama-rocm;
    enable = true;
    host = "[::]";
    environmentVariables.ROCR_VISIBLE_DEVICES = "0";
  };
  systemd.services.ollama.serviceConfig.User = lib.mkForce "armaan";

  networking.firewall.allowedTCPPorts = [
    11434
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      rocmPackages.rocm-runtime
      rocmPackages.rocblas
    ];
  };

  # Bluetooth
  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # Drapion-specific packages
  environment.systemPackages = with pkgs; [
    claude-code
    calibre
    firefox
    quickemu
    godot
    arduino-ide
    koboldcpp
    hashcat
  ];

  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [ "armaan" ];

  virtualisation.libvirtd.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;

  services.gnome.gnome-keyring.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
