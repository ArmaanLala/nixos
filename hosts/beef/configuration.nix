# Beef - Desktop workstation with AMD GPU and Ollama
{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
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

  # Beef-specific packages
  environment.systemPackages = with pkgs; [
    firefox
    quickemu
    hashcat
    john
    amdgpu_top
    protonup-qt
  ];

  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [ "armaan" ];

  virtualisation.libvirtd.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;

  services.gnome.gnome-keyring.enable = false;

  system.stateVersion = "25.11";
}
