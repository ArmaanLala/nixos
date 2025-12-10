# Beef - Desktop workstation with AMD GPU and Ollama
{ pkgs, zen-browser, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/steam.nix
    ../../modules/nfs-buzz.nix
    ../../modules/nfs-tforce.nix
    ../../modules/nfs-immich.nix
  ];

  networking.hostName = "beef";

  # Override common.nix bootloader - beef uses GRUB with custom Sekiro theme
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };
  boot.loader.timeout = 10;

  fileSystems."/mnt/nyx" = {
    device = "/dev/disk/by-uuid/d9f321f6-b8f8-4fe4-adce-e49ed4834a52";
    fsType = "btrfs";
    options = [
      "defaults"
      "noatime"
      "exec"
    ];
  };

  # Ollama with ROCm acceleration for AMD GPU
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    host = "[::]";
  };

  # Beef-specific packages
  environment.systemPackages = with pkgs; [
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  system.stateVersion = "25.11";
}
