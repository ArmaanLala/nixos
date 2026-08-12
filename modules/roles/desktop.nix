# Desktop environment configuration (Niri/Hyprland, audio, printing, fonts)
{
  pkgs,
  lib,
  ...
}:

{
  # Scratch module -- see test.nix.
  imports = [ ./test.nix ];

  # NOT for XWayland (that's programs.hyprland.xwayland / xwayland-satellite).
  # Only here to satisfy SDDM's assertion that one of services.xserver /
  # sddm.wayland is set; drop it only alongside sddm.wayland = true.
  services.xserver.enable = true;

  services.fwupd.enable = true;

  # publish.enable/addresses are already set in common.nix; desktops add this.
  services.avahi.publish.userServices = true;

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

  services.printing.enable = true;

  # Pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Fonts
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

    nautilus
    loupe
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
    pavucontrol
  ];

  # Writes /etc/xdg/mimeapps.list. Without an entry, xdg-open picks whichever
  # .desktop claims the type first -- which is how PNGs ended up opening in GIMP.
  xdg.mime.defaultApplications = {
    "image/png" = "org.gnome.Loupe.desktop";
    "image/jpeg" = "org.gnome.Loupe.desktop";
    "image/gif" = "org.gnome.Loupe.desktop";
    "image/webp" = "org.gnome.Loupe.desktop";
    "image/bmp" = "org.gnome.Loupe.desktop";
    "image/tiff" = "org.gnome.Loupe.desktop";
    "image/avif" = "org.gnome.Loupe.desktop";
    "image/svg+xml" = "org.gnome.Loupe.desktop";
    "application/pdf" = "firefox.desktop";
    "inode/directory" = "org.gnome.Nautilus.desktop";
  };

  programs.localsend.openFirewall = true;

  security.polkit.enable = true;
}
