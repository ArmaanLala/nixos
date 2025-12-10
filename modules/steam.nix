# configuration.nix

{ pkgs, ... }:

{

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # hardware.opengl has beed changed to hardware.graphics

  # services.xserver.videoDrivers = ["nvidia"];
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.nvidia.modesetting.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  programs.steam.gamescopeSession.enable = true;
  environment.systemPackages = with pkgs; [
    mangohud
    protonup-ng
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  programs.gamemode.enable = true;

}
