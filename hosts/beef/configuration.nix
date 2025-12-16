# Beef - Desktop workstation with AMD GPU and Ollama
{ pkgs, zen-browser, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/developer.nix
    ../../modules/steam.nix
    ../../modules/stylix.nix
    ../../modules/nfs.nix
  ];

  nfsMounts = {
    "/mnt/buzz" = "10.0.0.160:/mnt/wdblue/buzzer";
    "/mnt/tforce" = "10.0.0.250:/mnt/tforce";
    "/mnt/immich" = "10.0.0.160:/mnt/wdblue/immich";
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

  services.tailscale.enable = true;

  # Ollama with ROCm acceleration for AMD GPU
  services.ollama = {
    acceleration = "rocm";
    enable = true;
    host = "[::]";
  };

  # Beef-specific packages
  environment.systemPackages = with pkgs; [
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    hashcat
    john
    amdgpu_top
  ];

  # In your NixOS or home-manager config
  services.gnome.gnome-keyring.enable = false;

  system.stateVersion = "25.11";
}
