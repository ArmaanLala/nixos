# Desktop environment configuration (Niri/Hyprland, audio, printing, fonts)
{
  config,
  pkgs,
  lib,
  claude-code,
  ...
}:

let
  # Session list for tuigreet: one derivation symlinking every
  # displayManager.sessionPackages entry (NixOS has no /usr/share/*-sessions).
  sessions = config.services.displayManager.sessionData.desktops;
in
{
  # Blank the greeter's VT after 300s: hypridle only runs inside a compositor,
  # so on tty1 the kernel console blanker handles it (default is never).
  boot.kernelParams = [ "consoleblank=300" ];

  # Never auto-suspend: IdleAction counts greeter and idle-SSH sessions, so the
  # default would suspend the box out from under a headless ssh user. hypridle
  # still blanks/locks; suspend stays a deliberate act. logind only re-reads
  # this on `systemctl reload systemd-logind` (reload, not restart).
  services.logind.settings.Login.IdleAction = "ignore";

  # libinput defaults to services.xserver.enable (now off); its udev quirks/hwdb
  # feed the Wayland compositors too, so pin it on.
  services.libinput.enable = true;

  services.fwupd.enable = true;

  # publish.enable/addresses come from common.nix; desktops add this.
  services.avahi.publish.userServices = true;

  services.greetd = {
    enable = true;
    # Gives the unit TTYPath=/dev/tty1 + TTYVHangup (else boot messages scribble
    # over the TUI) and creates /var/cache/tuigreet for --remember*.
    useTextGreeter = true;
    settings.default_session.command = lib.concatStringsSep " " [
      # top-level `tuigreet`, not `greetd.tuigreet` (a 25.11 rename alias that warns)
      (lib.getExe pkgs.tuigreet)
      "--time"
      "--asterisks"
      "--remember" # prefill the last username that logged in
      "--remember-user-session" # ...and reselect that user's last session
      "--sessions ${sessions}/share/wayland-sessions:${sessions}/share/xsessions"
    ];
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

  # Module (not package): also registers pam.services.hyprlock and pulls in
  # services.hypridle. Bound to SUPER SHIFT L.
  programs.hyprlock.enable = true;

  # No NixOS module for swayosd. Backend is a system-bus dbus unit, so it needs
  # services.dbus.packages (bus policy) and environment.systemPackages (polkit
  # reads the system profile only). wantedBy graphical.target, not
  # multi-user.target (PartOf graphical.target makes that transaction cyclic).
  systemd.packages = [ pkgs.swayosd ];
  services.dbus.packages = [ pkgs.swayosd ];
  systemd.services.swayosd-libinput-backend.wantedBy = [ "graphical.target" ];

  # System-level desktop integration components
  environment.systemPackages = with pkgs; [
    polkit_gnome
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xwayland-satellite
    swayosd
    # bottles # temporarily disabled - patool tests failing on python 3.14
    opencode

    # From the flake's own output, not nixpkgs/overlay: the overlay rebuilds
    # against our nixpkgs and misses the Cachix cache. Matches pwndbg in dev.nix.
    claude-code.packages.x86_64-linux.default
  ];

  users.users.armaan.packages = with pkgs; [
    firefox

    # Terminal emulators
    ghostty
    alacritty

    caligula

    # System monitoring
    btop
    amdgpu_top
    nvtopPackages.amd

    # Graphics diagnostics
    mesa-demos
    vulkan-tools

    # Desktop applications
    obs-studio
    kicad
    # freecad # temporarily disabled - rebuilds vtk/pdal/gdal from source, slow
    orca-slicer
    vlc
    ffmpeg

    nautilus
    loupe
    phinger-cursors
    papirus-icon-theme

    # Wayland compositor tools & utilities
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

    # Screenshot / capture, bound in hyprland.conf
    slurp # grimblast bundles its own; wl-screenrec needs it on PATH
    satty # fed from grimblast (SUPER SHIFT S)
    wl-screenrec # VAAPI-accelerated capture (SUPER SHIFT R)
    hyprpicker # SUPER P

    # File managers
    yazi # TUI, async, image previews in ghostty via kitty graphics
    lf # TUI, more minimal than yazi
    kdePackages.dolphin # GUI, split panes + embedded terminal
    poppler-utils # yazi preview backend -- PDFs
    ffmpegthumbnailer # yazi preview backend -- video

    # PDF viewers
    zathura # vim keys, minimal; bundles the mupdf/ps/djvu plugins
    sioyek # built for papers: reference jumps, portals
    papers # GNOME/GTK4, good annotations

    # Hardware UIs (no GUI otherwise for these)
    bluetuith # hardware.bluetooth
    wiremix # TUI counterpart to pavucontrol
  ];

  # Writes /etc/xdg/mimeapps.list; without it xdg-open picks the first .desktop
  # claiming the type (which is how PNGs ended up in GIMP).
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

  # openFirewall (53317 TCP+UDP) also installs the package -- don't also add it
  # to users.users.armaan.packages.
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  security.polkit.enable = true;
}
