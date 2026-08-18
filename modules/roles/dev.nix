# Development environment - Languages, debugging, and tools
{ pkgs, pwndbg, ... }:

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
