# Drapion - Desktop workstation with AMD GPU (replacing beef)
# Hardware: Ryzen 7 7800X3D, AMD GPU, 1.8TB NVMe (btrfs)
{ pkgs, ... }:

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
    "/mnt/buzz" = "10.0.0.160:/mnt/wdblue/buzzer";
    "/mnt/games" = "10.0.0.160:/mnt/wdblue/games";
    "/mnt/immich" = "10.0.0.160:/mnt/wdblue/immich";
    "/mnt/media" = "10.0.0.160:/mnt/wdblue/arr";
    "/mnt/manga" = "10.0.0.160:/mnt/wdblue/manga";
  };

  services.udisks2.enable = true;
  networking.hostName = "drapion";

  # Drapion uses systemd-boot (default from common.nix) with btrfs via disko
  # No need to override bootloader settings

  # AMD GPU
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.amdgpu.opencl.enable = true;

  # Ollama with ROCm acceleration for AMD GPU
  services.ollama = {
    acceleration = "rocm";
    package = pkgs.ollama-rocm;
    enable = true;
    host = "[::]";
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      rocmPackages.rocm-runtime
      rocmPackages.rocblas
    ];
  };

  # Drapion-specific packages
  environment.systemPackages = with pkgs; [
    firefox
    quickemu
    hashcat
    john
    udiskie
    amdgpu_top
    protonup-qt
    kcc
  ];

  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [ "armaan" ];

  virtualisation.libvirtd.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;

  services.gnome.gnome-keyring.enable = false;

  system.stateVersion = "25.11";
}
