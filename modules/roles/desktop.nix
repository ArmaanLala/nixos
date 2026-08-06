# Desktop environment configuration (Niri/Hyprland, audio, printing, fonts)
{
  pkgs,
  lib,
  ...
}:

{
  # NOT for XWayland — that comes from programs.hyprland.xwayland.enable below
  # and xwayland-satellite (niri). This is here purely to satisfy SDDM's
  # assertion that one of services.xserver / sddm.wayland is enabled; we run the
  # X11 greeter. Removing it means setting services.displayManager.sddm.wayland
  # in the same commit.
  services.xserver.enable = true;

  # publish.enable/addresses are already set in common.nix; desktops add this.
  services.avahi.publish.userServices = true;

  # Display manager
  services.displayManager.sddm = {
    enable = true;
  };
  # Wayland compositors
  programs.niri.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

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
    # bottles # temporarily disabled - patool tests failing on python 3.14
    opencode
  ];

  # Desktop-specific user packages
  users.users.armaan.packages = with pkgs; [
    firefox

    # Terminal emulators
    ghostty
    alacritty

    localsend
    caligula

    # System monitoring
    btop
    amdgpu_top
    nvtopPackages.amd

    # Graphics diagnostics
    mesa-demos
    vulkan-tools

    # Desktop applications
    claude-code

    obs-studio
    kicad
    # freecad # temporarily disabled - rebuilds vtk/pdal/gdal from source, slow
    orca-slicer
    vlc
    ffmpeg

    # File manager
    nautilus

    # Cursor theme
    phinger-cursors

    # Wayland compositor tools & utilities
    waybar
    quickshell
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
  ];

  programs.localsend.openFirewall = true;

  # Polkit agent for authentication dialogs
  security.polkit.enable = true;
}
