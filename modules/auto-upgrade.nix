# Automatic system upgrades for servers
{
  config,
  lib,
  pkgs,
  ...
}:

{
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos#${config.networking.hostName}";

    # Weekly on Saturday at 3 AM
    dates = "Sat *-*-* 03:00:00";

    # Don't auto-reboot - let admin decide
    allowReboot = false;

    # Useful flags
    flags = [
      "-L" # Print build logs
    ];
  };

  # Pull latest config before upgrading
  systemd.services.nixos-upgrade.preStart = ''
    cd /etc/nixos
    ${pkgs.git}/bin/git pull --ff-only || true
  '';

  # Garbage collection - clean up old generations
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Keep the store optimized
  nix.settings.auto-optimise-store = true;
}
