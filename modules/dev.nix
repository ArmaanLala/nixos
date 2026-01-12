# Development environment - Languages, debugging, and tools
{ pkgs, ... }:

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

    # Data processing
    jq
    yq

    # Benchmarking and profiling
    hyperfine

    # Networking tools
    dnsutils # dig, nslookup
    tcpdump
    iperf3
    wireguard-tools

    # Media tools
    yt-dlp
    imagemagick

    # Reverse engineering
    ghidra
    hexyl
    imhex

    # OSINT
    sherlock

    # Formatters
    treefmt
    nixfmt-rfc-style
    rustfmt
    stylua
    shfmt
    taplo
    yamlfmt
    nodePackages.prettier
  ];
}
