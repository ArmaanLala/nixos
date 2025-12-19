# Package configuration: system packages and user packages
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    # Core system packages (always installed, available to root)
    {
      environment.systemPackages = with pkgs; [
        vim
        git
        wget
        curl
        htop
        screen
        p7zip

        # File utilities
        tree
        file
        rsync
        pv

        # System debugging
        nmap
        lsof
        strace
      ];
    }

    # User packages (controlled by toggle)
    (lib.mkIf config.common.enableUserPackages {
      users.users.armaan.packages = with pkgs; [
        # CLI tools
        ripgrep
        fd
        lazygit
        neovim
        tealdeer
        duf
        gdu
        parallel
        bat
        bat-extras.batman
        eza
        mediainfo
        zip
        unzip
        rmlint
        tokei
        gh

        # Shell and terminal
        fish
        tmux
        fastfetch
        starship
        zoxide
      ];
    })
  ];
}
