# Scratch module for trying things out. Everything in here is on probation --
# delete the lines you don't want and rebuild. Deleting the whole file (and its
# import in desktop.nix) reverts to the previous setup, including the MIME
# defaults at the bottom.
#
# Note: hyprland.conf binds SUPER SHIFT L / SUPER SHIFT S / SUPER P /
# SUPER SHIFT R and the media keys to hyprlock, satty, hyprpicker,
# wl-screenrec and swayosd-client -- all of which live here. Pruning those
# packages leaves the binds pointing at nothing, so clean up hyprland.conf in
# the same pass.
#
# Only desktop.nix imports this file, so nothing here reaches the non-desktop
# hosts (atlas / lenix / proton / webster).
{
  pkgs,
  lib,
  ...
}:

{
  users.users.armaan.packages = with pkgs; [
    # --- File managers ---
    yazi # TUI, async, image previews in ghostty via kitty graphics
    lf # TUI, more minimal than yazi
    kdePackages.dolphin # GUI, split panes + embedded terminal (pulls in Qt/KDE)

    # --- PDF viewers ---
    zathura # vim keys, minimal; this attr already bundles the mupdf/ps/djvu plugins
    sioyek # zathura-ish keys, built for papers: reference jumps, portals
    papers # GNOME/GTK4 successor to evince, good annotations

    # --- Preview backends for yazi ---
    # yazi shells out to these; without them PDFs and videos preview as blank.
    # ffmpeg, imagemagick, p7zip, file, jq, fd and ripgrep are already installed.
    poppler-utils # PDF page previews
    ffmpegthumbnailer # video thumbnails

    # --- TUI gaps in the current setup ---
    fzf # nothing else here provides fuzzy select; yazi/lf/git all hook into it
    bluetuith # bluetooth manager -- hardware.bluetooth is on with no UI for it
    wiremix # TUI pipewire mixer, the counterpart to the pavucontrol you have
    atuin # searchable shell history synced across the six hosts in this flake
    # delta moved to core/common.nix -- programs.git now sets it as the pager,
    # so it can't live in a module that's meant to be deletable.
    hunk # TUI diff viewer, aimed at reviewing large agent-generated changesets
    difftastic # structural diff: compares parse trees, ignores pure reindents
    glow # renders markdown in the terminal, e.g. this flake's README/docs
    gping # ping with a live graph, useful when the wifi is being weird

    # --- Nix-specific, aimed at this flake's workflow ---
    nix-output-monitor # turns rebuild output into a readable build tree
    nvd # diffs two generations: what actually changed on a switch
    nix-tree # walk the store closure to find what's eating disk
    comma # `, <program>` runs anything in nixpkgs without installing it

    # --- Screenshot / capture, bound in hyprland.conf ---
    slurp # region picker -- grimblast bundles its own, wl-screenrec needs it on PATH
    satty # screenshot annotation, fed from grimblast (SUPER SHIFT S)
    wl-screenrec # VAAPI-accelerated capture (SUPER SHIFT R)
    hyprpicker # colour picker (SUPER P)
    # swayosd is in environment.systemPackages below, not here -- see comment

    # --- Binary exploitation / RE ---
    rizin # radare2 successor, faster triage than opening Ghidra
    binwalk # firmware/blob extraction
    pwninit # patches binary to the challenge libc + writes a pwntools template
    checksec # RELRO/canary/NX/PIE at a glance
    one_gadget # one-shot execve gadgets in a given libc
    python3Packages.ropper # gadget search -- note: not a top-level attr
    termshark # TUI wireshark, reads the same captures as tcpdump
    ffuf # web content/parameter fuzzer

    # --- General CLI ---
    usbutils # lsusb -- counterpart to pciutils, for the QMK/arduino work
    serie # git commit graph TUI
    ouch # one command for any archive format
    procs
    sshs # picker over ~/.ssh/config
    watchexec
    just
    mprocs # several long-lived processes in one split view
    lnav # log navigator, merges files into one timeline
  ];

  # fzf/atuin/direnv need shell integration to be worth anything; the package
  # alone does nothing. fish is the enabled shell here.
  programs.fzf = {
    fuzzyCompletion = true; # **<tab>
    keybindings = true; # ctrl-r history, ctrl-t files, alt-c cd
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # caches dev shells so `cd` isn't a rebuild
  };

  # trippy and bandwhich need CAP_NET_RAW; these modules install setcap wrappers
  # so they run without sudo (sudo would also lose your user config). trippy's
  # binary is `trip`, and it comes from the wrapper, not from a package entry.
  programs.trippy.enable = true;
  programs.bandwhich.enable = true;

  # Installs hyprlock AND registers security.pam.services.hyprlock. The package
  # alone cannot authenticate, so this has to be the module, not a package line.
  # Bound to SUPER SHIFT L; config lives in ~/.config/hypr/hyprlock.conf.
  programs.hyprlock.enable = true;

  # swayosd has no NixOS module in this nixpkgs, so all three pieces are wired
  # by hand. The backend is a Type=dbus service that owns org.erikreider.swayosd
  # on the SYSTEM bus, so it needs all of:
  #
  #   1. systemd.packages       -- the unit file itself
  #   2. services.dbus.packages -- share/dbus-1/system.d bus policy. Without it
  #      the unit starts and immediately dies with "Request to own name refused
  #      by policy".
  #   3. environment.systemPackages (not users.users.*.packages) -- polkit reads
  #      actions/rules from the system profile only; per-user profiles are never
  #      searched. This also puts swayosd-client on PATH for the media keys.
  #
  # graphical.target, not multi-user.target: the shipped unit is After=/PartOf=
  # graphical.target, and graphical.target is itself After=multi-user.target, so
  # pulling it into multi-user makes the transaction cyclic and nothing starts.
  environment.systemPackages = [ pkgs.swayosd ];
  systemd.packages = [ pkgs.swayosd ];
  services.dbus.packages = [ pkgs.swayosd ];
  systemd.services.swayosd-libinput-backend.wantedBy = [ "graphical.target" ];

  # mkForce because desktop.nix already defines these two keys -- same-key
  # definitions in two modules are a conflict, not a merge. Drop this block
  # along with the file and desktop.nix's values take over again.
  xdg.mime.defaultApplications = {
    "application/pdf" = lib.mkForce "org.pwmt.zathura.desktop";
    # "application/pdf" = lib.mkForce "sioyek.desktop";
    # "application/pdf" = lib.mkForce "org.gnome.Papers.desktop";

    "inode/directory" = lib.mkForce "org.kde.dolphin.desktop";
    # "inode/directory" = lib.mkForce "org.gnome.Nautilus.desktop";
  };
}
