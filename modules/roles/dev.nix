{
  pkgs,
  pwndbg,
  unstable,
  ...
}:

let
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
  programs.fzf = {
    fuzzyCompletion = true;
    keybindings = true;
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.trippy.enable = true;
  programs.bandwhich.enable = true;

  environment.systemPackages = with pkgs; [
    gcc
    clang
    llvm
    cmake
    ninja
    gnumake

    gdb
    lldb
    pwndbg.packages.x86_64-linux.pwndbg
    pwndbg.packages.x86_64-linux.pwndbg-lldb
    valgrind
    perf

    pkg-config
    autoconf
    automake
    libtool
  ];

  users.users.armaan.packages = with pkgs; [
    rustup
    go
    gopls
    zig
    zls
    jdk
    nodejs
    python3
    uv

    nil
    clang-tools
    ruff

    zed-editor

    jq
    yq

    hyperfine

    dnsutils
    tcpdump
    wireguard-tools

    yt-dlp
    imagemagick

    ghidra-hidpi
    hexyl
    imhex
    radare2
    libqalculate
    heh
    binsider

    sherlock

    atuin
    difftastic
    unstable.hunk
    glow
    gping
    serie
    ouch
    procs
    sshs
    watchexec
    just
    mprocs
    lnav
    usbutils

    nix-output-monitor
    nvd
    nix-tree
    comma

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
