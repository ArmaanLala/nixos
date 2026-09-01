# Desktop environment configuration (Niri/Hyprland, audio, printing, fonts)
{
  config,
  pkgs,
  lib,
  claude-code,
  ...
}:

let
  # The same tree SDDM used to read its session list from: one derivation
  # symlinking every services.displayManager.sessionPackages entry (currently
  # hyprland-uwsm, niri, steam-gamescope). tuigreet otherwise only looks in
  # /usr/share/{wayland-sessions,xsessions}, which don't exist on NixOS.
  sessions = config.services.displayManager.sessionData.desktops;
in
{
  # Scratch module -- see test.nix. idle.nix owns the blank/lock/suspend
  # timers and the desktop.autoSuspend switch drapion flips off.
  imports = [
    ./idle.nix
    ./test.nix
  ];

  # No services.xserver.enable: greetd runs on the TTY, so nothing needs an X
  # server any more. XWayland is unaffected -- that's programs.hyprland.xwayland
  # / xwayland-satellite.
  #
  # But services.libinput.enable *defaults* to services.xserver.enable, and its
  # udev entry (pkgs.libinput's device quirks/hwdb) is what the Wayland
  # compositors read too. Pin it on so dropping xserver isn't a silent input
  # regression on the thinkpad's touchpad.
  services.libinput.enable = true;

  services.fwupd.enable = true;

  # publish.enable/addresses are already set in common.nix; desktops add this.
  services.avahi.publish.userServices = true;

  services.greetd = {
    enable = true;
    # Gives the unit StandardInput/TTYPath=/dev/tty1 + TTYVHangup, without which
    # systemd's boot messages scribble over the TUI. Also creates
    # /var/cache/tuigreet (owned by greeter), which --remember* needs to persist.
    useTextGreeter = true;
    settings.default_session.command = lib.concatStringsSep " " [
      # top-level `tuigreet`, not `greetd.tuigreet` -- the latter is a rename
      # alias in 25.11 and warns on every eval.
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

  # System-level desktop integration components
  environment.systemPackages = with pkgs; [
    polkit_gnome
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xwayland-satellite

    # no hypridle: services.hypridle (pulled in by programs.hyprlock.enable in
    # test.nix) already installs the package and its systemd user unit.
    # bottles # temporarily disabled - patool tests failing on python 3.14
    opencode
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
    # The flake's own output, not its overlay: the overlay is
    # `final.callPackage`, which rebuilds against our nixpkgs and misses the
    # Cachix cache the no-`follows` input exists for. Matches the pwndbg
    # pattern in dev.nix.
    claude-code.packages.x86_64-linux.default

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

  # openFirewall (port 53317, TCP+UDP) only takes effect when the module itself
  # is enabled — the module also installs the package, so don't add it to
  # users.users.armaan.packages as well.
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  security.polkit.enable = true;
}
