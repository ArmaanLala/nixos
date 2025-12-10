# Desktop environment configuration (KDE Plasma, Niri, audio, printing)
{ pkgs, ... }:

{
  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  programs.niri.enable = true;

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Install firefox
  programs.firefox.enable = true;

  # Desktop-specific user packages
  users.users.armaan.packages = with pkgs; [
    kdePackages.kate
    ghostty
    alacritty
    btop
    claude-code
    github-cli
    steam
    vesktop
    obs-studio
    kicad
    freecad

    # Niri dependencies
    waybar
    walker
    wofi
    swaylock
    nautilus
    playerctl
    brightnessctl
    swaybg
    xwayland-satellite
  ];
}
