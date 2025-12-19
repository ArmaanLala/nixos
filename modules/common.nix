# Common configuration shared across all hosts
# Wrapper module with toggles for optional features
{ lib, ... }:

{
  imports = [
    ./common/networking.nix
    ./common/users.nix
    ./common/shell.nix
    ./common/packages.nix
    ./common/nix-settings.nix
    ./hosts.nix
  ];

  options.common = {
    enableShell = lib.mkEnableOption "fish shell configuration" // {
      default = true;
    };
    enableUserPackages = lib.mkEnableOption "user CLI packages" // {
      default = true;
    };
  };

  config = {
    boot.loader.systemd-boot.enable = lib.mkDefault true;
    boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

    time.timeZone = lib.mkDefault "America/Los_Angeles";
    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };

    services.xserver.xkb.layout = "us";
  };
}
