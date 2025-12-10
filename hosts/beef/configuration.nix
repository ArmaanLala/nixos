# Beef - Desktop workstation with AMD GPU and Ollama
{ pkgs, zen-browser, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
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
    theme = "${
      (pkgs.fetchFromGitHub {
        owner = "semimqmo";
        repo = "sekiro_grub_theme";
        rev = "1affe05f7257b72b69404cfc0a60e88aa19f54a6";
        hash = "sha256-wTr5S/17uwQXkWwElqBKIV1J3QUP6W2Qx2Nw0SaM7Qk=";
      })
    }/Sekiro";
  };
  boot.loader.timeout = 10;

  # Ollama with ROCm acceleration for AMD GPU
  services.ollama = {
    enable = true;
    acceleration = "rocm";
  };

  # Beef-specific packages
  environment.systemPackages = with pkgs; [
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  system.stateVersion = "25.11";
}
