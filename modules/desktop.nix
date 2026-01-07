# Desktop environment configuration (Niri/Hyprland, audio, printing, fonts)
{
  pkgs,
  lib,
  colmena,
  ...
}:

{
  # Enable the X11 windowing system (for XWayland support)
  services.xserver.enable = true;

  # Display manager
  services.displayManager.sddm.enable = true;

  # Wayland compositors
  programs.niri.enable = true;
  programs.hyprland.enable = lib.mkDefault false;

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

  # Fonts (from lala-desktop)
  fonts.packages = with pkgs; [
    dejavu_fonts
    liberation_ttf
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    fira-code
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-color-emoji
    font-awesome
    ubuntu-classic
    hack-font
    roboto
    roboto-mono
    ibm-plex
    open-sans
    nerd-fonts.ubuntu
  ];

  # System-level desktop integration components
  environment.systemPackages = with pkgs; [
    polkit_gnome
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xwayland-satellite
    bottles
  ];

  # Desktop-specific user packages
  # (System integration tools like polkit_gnome and xdg-desktop-portals are in environment.systemPackages)
  users.users.armaan.packages = with pkgs; [
    # Terminal emulators
    ghostty
    alacritty
    colmena.packages.x86_64-linux.colmena

    # Gaming
    wineWowPackages.waylandFull
    itch

    localsend
    caligula

    # System monitoring
    btop

    # Desktop applications
    claude-code
    vesktop
    obs-studio
    kicad
    freecad
    vlc
    ffmpeg
    rustdesk
    rustdesk-server

    # File manager
    nautilus

    # Wayland compositor tools & utilities
    waybar
    quickshell
    walker
    wofi
    fuzzel
    swaylock
    mako
    dunst
    playerctl
    brightnessctl
    swaybg
    wl-clipboard
    udiskie

    # Audio control
    pavucontrol

    #emulation
    mgba
    melonDS
  ];

  # Polkit agent for authentication dialogs
  security.polkit.enable = true;
}
