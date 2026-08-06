# Gaming configuration - Steam, Proton, Wine, emulation and performance tools
{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
  ];

  # User-scoped, matching where these lived before they moved out of
  # desktop.nix and hosts/drapion.
  users.users.armaan.packages = with pkgs; [
    # Wine / Proton
    wineWow64Packages.waylandFull
    winetricks
    protonup-qt
    steamtinkerlaunch

    # Launchers and mod managers
    itch
    r2modman

    # Emulation
    mgba
    melonds
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };
}
