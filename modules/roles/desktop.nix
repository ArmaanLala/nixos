{
  config,
  pkgs,
  lib,
  claude-code,
  ...
}:

let
  sessions = config.services.displayManager.sessionData.desktops;
in
{
  boot.kernelParams = [ "consoleblank=300" ];

  services.logind.settings.Login.IdleAction = "ignore";

  services.libinput.enable = true;

  services.fwupd.enable = true;

  services.avahi.publish.userServices = true;

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command = lib.concatStringsSep " " [
      (lib.getExe pkgs.tuigreet)
      "--time"
      "--asterisks"
      "--remember"
      "--remember-user-session"
      "--sessions ${sessions}/share/wayland-sessions:${sessions}/share/xsessions"
    ];
  };

  programs.niri.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

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

  programs.hyprlock.enable = true;

  systemd.packages = [ pkgs.swayosd ];
  services.dbus.packages = [ pkgs.swayosd ];
  systemd.services.swayosd-libinput-backend.wantedBy = [ "graphical.target" ];

  environment.systemPackages = with pkgs; [
    polkit_gnome
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xwayland-satellite
    swayosd
    opencode

    claude-code.packages.x86_64-linux.default
  ];

  users.users.armaan.packages = with pkgs; [
    firefox

    ghostty
    alacritty

    caligula

    btop
    amdgpu_top
    nvtopPackages.amd

    mesa-demos
    vulkan-tools

    obs-studio
    kicad
    orca-slicer
    vlc
    ffmpeg

    nautilus
    loupe
    phinger-cursors
    papirus-icon-theme

    waybar
    quickshell
    fuzzel
    swaylock
    dunst
    libnotify
    playerctl
    brightnessctl
    swaybg
    wl-clipboard
    udiskie
    pavucontrol

    slurp
    satty
    wl-screenrec
    hyprpicker

    yazi
    lf
    kdePackages.dolphin
    poppler-utils
    ffmpegthumbnailer

    zathura
    sioyek
    papers

    bluetuith
    wiremix
  ];

  xdg.mime.defaultApplications = {
    "image/png" = "org.gnome.Loupe.desktop";
    "image/jpeg" = "org.gnome.Loupe.desktop";
    "image/gif" = "org.gnome.Loupe.desktop";
    "image/webp" = "org.gnome.Loupe.desktop";
    "image/bmp" = "org.gnome.Loupe.desktop";
    "image/tiff" = "org.gnome.Loupe.desktop";
    "image/avif" = "org.gnome.Loupe.desktop";
    "image/svg+xml" = "org.gnome.Loupe.desktop";
    "application/pdf" = "org.pwmt.zathura.desktop";
    "inode/directory" = "org.kde.dolphin.desktop";
  };

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  security.polkit.enable = true;
}
