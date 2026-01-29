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
    "/mnt/beelink" = "10.0.0.160:/mnt/wdblue/beelink";
    "/mnt/testpaper" = "10.0.0.160:/mnt/wdblue/testpaper";
  };

  services.udisks2.enable = true;
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

  environment.etc."paperless-admin-pass".text = "admin";
  services.paperless = {
    enable = true;
    passwordFile = "/etc/paperless-admin-pass";
    port = 28981;
    address = "10.0.0.183";
  };
  networking.firewall.allowedTCPPorts = [
    28981
    11434
  ];

  # AMD GPU
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.amdgpu.opencl.enable = true;

  # Ollama with ROCm acceleration for AMD GPU
  services.ollama = {
    acceleration = "rocm";
    package = pkgs.ollama-rocm;
    enable = true;
    host = "[::]";
    environmentVariables.ROCR_VISIBLE_DEVICES = "0";
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
    imv
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
