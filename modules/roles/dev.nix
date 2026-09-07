# Development environment - Languages, debugging, and tools
{
  pkgs,
  pwndbg,
  unstable,
  ...
}:

let
  # Ghidra hardcodes -Dsun.java2d.uiScale=1 in support/launch.properties, which
  # is unreadable on HiDPI. That file is in the read-only store, but the JVM
  # applies _JAVA_OPTIONS after the command line, so it wins over the shipped
  # value. Wrapping bin/ghidra also covers the launcher: ghidra.desktop uses a
  # bare `Exec=ghidra`, resolved through PATH.
  ghidra-hidpi = pkgs.symlinkJoin {
    name = "ghidra-hidpi";
    paths = [ pkgs.ghidra ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ghidra \
        --set _JAVA_OPTIONS "-Dsun.java2d.uiScale=2"
    '';
  };
in
{
  # Package alone does nothing -- these need the module's shell integration.
  programs.fzf = {
    fuzzyCompletion = true; # **<tab>
    keybindings = true; # ctrl-r history, ctrl-t files, alt-c cd
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # caches dev shells so `cd` isn't a rebuild
  };

  # Modules, not packages: both need CAP_NET_RAW and install setcap wrappers so
  # they run without sudo. trippy's binary is `trip`.
  programs.trippy.enable = true;
  programs.bandwhich.enable = true;

  environment.systemPackages = with pkgs; [
    # C/C++ toolchain
    gcc
    clang
    llvm
    cmake
    ninja
    gnumake

    # Debuggers and profilers
    gdb
    lldb
    pwndbg.packages.x86_64-linux.pwndbg
    pwndbg.packages.x86_64-linux.pwndbg-lldb
    valgrind
    perf

    # Build tools
    pkg-config
    autoconf
    automake
    libtool
  ];

  users.users.armaan.packages = with pkgs; [
    # Programming languages
    rustup
    go
    gopls
    zig
    zls
    jdk
    nodejs
    python3
    uv

    # Language servers and tooling
    nil # Nix LSP
    clang-tools # clangd, clang-format, etc.
    ruff # Python linter

    # Editors
    zed-editor

    # Data processing
    jq
    yq

    # Benchmarking and profiling
    hyperfine

    # Networking tools
    dnsutils # dig, nslookup
    tcpdump
    wireguard-tools

    # Media tools
    yt-dlp
    imagemagick

    # Reverse engineering
    ghidra-hidpi
    hexyl
    imhex
    radare2 # also provides rax2, the base/encoding converter
    libqalculate # qalc, multi-base calculator with bitwise ops
    heh # TUI hex editor with a multi-base byte inspector
    binsider # TUI ELF analyzer

    # OSINT
    sherlock

    # Shell & CLI
    atuin # shell history synced across hosts
    difftastic # structural diff -- ignores pure reindents
    unstable.hunk # TUI diff viewer for large agent-generated changesets
    glow # markdown in the terminal
    gping # ping with a live graph
    serie # git commit graph TUI
    ouch # one command for any archive format
    procs
    sshs # picker over ~/.ssh/config
    watchexec
    just
    mprocs # several long-lived processes in one split view
    lnav # log navigator, merges files into one timeline
    usbutils # lsusb

    # Nix workflow
    nix-output-monitor # readable rebuild output
    nvd # diffs two generations: what actually changed on a switch
    nix-tree # walk the store closure
    comma # `, <program>` runs anything in nixpkgs without installing it

    # Formatters
    treefmt
    nixfmt
    rustfmt
    stylua
    shfmt
    taplo
    yamlfmt
    prettier
  ];
}
