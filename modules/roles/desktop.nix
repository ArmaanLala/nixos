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
  # Idle handling *at the greeter*. hypridle only exists inside a logged-in
  # compositor; tuigreet is a TUI on tty1, so the blank timer comes from the
  # kernel instead. The kernel default is 0 (never blank). Only keyboard input
  # resets it -- console *output* doesn't -- so tuigreet's --time clock
  # redrawing once a second doesn't hold the screen on. fbcon passes the blank
  # down to the DRM driver, which drops the CRTC, so the monitor generally
  # sleeps rather than just going black. Applies to VTs only: a compositor
  # holding DRM master never sees it.
  boot.kernelParams = [ "consoleblank=300" ];

  # Explicitly *not* suspend, which is the easy one to miss: IdleAction fires
  # when every idle-capable session is idle, and greeter sessions and idle SSH
  # logins both count -- enough to suspend the box out from under an ssh user
  # with no desktop involved. Nothing here auto-suspends; hypridle's timers
  # blank the displays and lock the session, and suspending stays a deliberate
  # act (power menu, sleep key, `systemctl suspend`).
  #
  # logind only re-reads this on reload, which `nixos-rebuild switch` does not
  # do -- `systemctl reload systemd-logind` after a change (reload, not
  # restart: a restart takes the graphical session with it).
  services.logind.settings.Login.IdleAction = "ignore";

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

  # Module, not package: programs.hyprlock.enable also registers
  # security.pam.services.hyprlock (without which it cannot authenticate) and
  # pulls in services.hypridle + its systemd user unit. Bound to SUPER SHIFT L.
  programs.hyprlock.enable = true;

  # No NixOS module for swayosd, so wire it by hand. The backend is a Type=dbus
  # unit owning org.erikreider.swayosd on the SYSTEM bus, hence:
  #   services.dbus.packages     -- bus policy; without it the unit dies with
  #                                 "Request to own name refused by policy"
  #   environment.systemPackages -- polkit reads the system profile only, never
  #                                 per-user ones (also puts swayosd-client on
  #                                 PATH for the media keys)
  # graphical.target, not multi-user.target: the unit is PartOf graphical.target,
  # which is itself After multi-user.target -- that transaction is cyclic.
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

    # claude-code from the flake's own output, not nixpkgs and not its overlay:
    # the overlay is `final.callPackage`, which rebuilds against our nixpkgs and
    # misses the Cachix cache the no-`follows` input exists for. Matches the
    # pwndbg pattern in dev.nix. System-wide so root gets it too.
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
    "application/pdf" = "org.pwmt.zathura.desktop";
    "inode/directory" = "org.kde.dolphin.desktop";
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
