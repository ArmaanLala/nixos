# Scratch module -- everything here is on probation. Delete lines you don't
# want, or delete the file and its import in desktop.nix to revert entirely.
#
# Several hyprland.conf binds point at packages installed here (marked below);
# pruning one means fixing hyprland.conf in the same pass.
#
# Only desktop.nix imports this, so nothing here reaches the non-desktop hosts.
{
  pkgs,
  lib,
  unstable,
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
    poppler-utils
    ffmpegthumbnailer

    # --- TUI gaps in the current setup ---
    fzf # yazi/lf/git all hook into it
    bluetuith # hardware.bluetooth is on with no UI for it
    wiremix # TUI counterpart to pavucontrol
    atuin # shell history synced across hosts
    unstable.hunk # TUI diff viewer for large agent-generated changesets; not in 25.11
    difftastic # structural diff -- ignores pure reindents
    glow # markdown in the terminal
    gping # ping with a live graph

    # --- Nix-specific, aimed at this flake's workflow ---
    nix-output-monitor # readable rebuild output
    nvd # diffs two generations: what actually changed on a switch
    nix-tree # walk the store closure
    comma # `, <program>` runs anything in nixpkgs without installing it

    # --- Screenshot / capture, bound in hyprland.conf ---
    slurp # grimblast bundles its own; wl-screenrec needs it on PATH
    satty # fed from grimblast (SUPER SHIFT S)
    wl-screenrec # VAAPI-accelerated capture (SUPER SHIFT R)
    hyprpicker # SUPER P
    # swayosd is in environment.systemPackages below -- see why there

    # --- Binary exploitation / RE ---
    rizin # radare2 successor, faster triage than opening Ghidra
    binwalk # firmware/blob extraction
    pwninit # patches binary to the challenge libc + writes a pwntools template
    checksec # RELRO/canary/NX/PIE at a glance
    one_gadget # one-shot execve gadgets in a given libc
    python3Packages.ropper # gadget search; not a top-level attr
    termshark # TUI wireshark, reads the same captures as tcpdump
    ffuf # web content/parameter fuzzer

    # --- General CLI ---
    usbutils # lsusb
    serie # git commit graph TUI
    ouch # one command for any archive format
    procs
    sshs # picker over ~/.ssh/config
    watchexec
    just
    mprocs # several long-lived processes in one split view
    lnav # log navigator, merges files into one timeline
  ];

  # Package alone does nothing -- these need the module's fish integration.
  programs.fzf = {
    fuzzyCompletion = true; # **<tab>
    keybindings = true; # ctrl-r history, ctrl-t files, alt-c cd
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # caches dev shells so `cd` isn't a rebuild
  };

  # Modules, not packages: both need CAP_NET_RAW and these install setcap
  # wrappers so they run without sudo. trippy's binary is `trip`.
  programs.trippy.enable = true;
  programs.bandwhich.enable = true;

  # Module, not package: this also registers security.pam.services.hyprlock,
  # without which it cannot authenticate. Bound to SUPER SHIFT L.
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
  environment.systemPackages = [ pkgs.swayosd ];
  systemd.packages = [ pkgs.swayosd ];
  services.dbus.packages = [ pkgs.swayosd ];
  systemd.services.swayosd-libinput-backend.wantedBy = [ "graphical.target" ];

  # mkForce because desktop.nix already defines these two keys -- same-key
  # definitions in two modules are a conflict, not a merge. Drop it and
  # desktop.nix's values take over.
  xdg.mime.defaultApplications = {
    "application/pdf" = lib.mkForce "org.pwmt.zathura.desktop";
    # "application/pdf" = lib.mkForce "sioyek.desktop";
    # "application/pdf" = lib.mkForce "org.gnome.Papers.desktop";

    "inode/directory" = lib.mkForce "org.kde.dolphin.desktop";
    # "inode/directory" = lib.mkForce "org.gnome.Nautilus.desktop";
  };
}
