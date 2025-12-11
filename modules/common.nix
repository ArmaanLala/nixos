# Common configuration shared across all hosts
{ pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  services.tailscale.enable = true;
  networking.networkmanager.enable = true;
  networking.firewall.enable = lib.mkDefault false;
  networking.hosts = {
    "10.0.0.30" = [ "prometheus" ];
    "10.0.0.31" = [ "clio" ];
    "10.0.0.32" = [ "orpheus" ];
    "10.0.0.33" = [ "aether" ];
    "10.0.0.69" = [ "proton" ];
    "10.0.0.99" = [ "teapot" ];
    "10.0.0.100" = [ "servarr" ];
    "10.0.0.101" = [ "seagate" ];
    "10.0.0.102" = [ "repoman" ];
    "10.0.0.105" = [ "weed" ];
    "10.0.0.113" = [ "thinkpad" ];
    "10.0.0.114" = [ "thinkpad" ];
    "10.0.0.139" = [ "photos" ];
    "10.0.0.144" = [ "cftunnel" ];
    "10.0.0.160" = [ "truenas" ];
    "10.0.0.174" = [ "atlas" ];
    "10.0.0.183" = [ "beef" ];
    "10.0.0.186" = [ "lenix" ];
    "10.0.0.200" = [ "hydra" ];
    "10.0.0.201" = [ "loki" ];
    "10.0.0.202" = [ "calliope" ];
    "10.0.0.203" = [ "iris" ];
    "10.0.0.222" = [ "pihole" ];
    "10.0.0.250" = [ "alpine" ];
    "100.103.38.71" = [ "jumpbox" ];
  };

  time.timeZone = "America/Los_Angeles";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  services.xserver.xkb.layout = "us";

  users.groups.armaan = {
    gid = 1000;
  };

  users.users.armaan = {
    isNormalUser = true;
    description = "Armaan Lala";
    extraGroups = [
      "networkmanager"
      "wheel"
      "armaan"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxWbEebtUXP/g3+lSqQxRV8j3HbDZPEfvksbBognPtz armaan@nyx 2025-12-2"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPS2foqCO+tCzjg/CYsuaTX5SsjZyEpquDjbH4WXkLwR armaan@thinkpad 2025-12-03"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGWCoSW1PMIeftP7bqfZntLdRvhGBhpvzaLFZrXTvTrp armaanlala@apple-j616c 2025-12-03"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIOlH4q2wStz0qVgW9iVvJ4v/sH13wCnQkkgFCpIVGmY 2025-12-10 armaan@beef"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoygK39u8MDsc701vj1Vn9ow3eOtpk6kU+9UnmYrduq 2025-12-10 armaan@nix-thinkpad"
    ];
    # User-specific packages: CLI utilities and user-facing tools
    # (Core dev tools like git, gcc, python3 are in environment.systemPackages)
    packages = with pkgs; [
      # CLI tools
      ripgrep
      fd
      lazygit
      neovim
      nil
      nixfmt-rfc-style
      tealdeer
      duf
      gdu
      htop
      wget
      parallel
      bat
      bat-extras.batman
      eza
      mediainfo
      zip
      unzip
      rmlint
      tokei

      # Shell and terminal
      fish
      tmux
      fastfetch
      starship
      zoxide

      # Formatters
      stylua
    ];
  };

  programs.bash = {
    interactiveShellInit = ''
      if [[ $EUID -ne 0 && $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      v = "nvim";
      cat = "bat";
      mv = "mv -i";
      rm = "rm -Iv";
      df = "df -h";
      du = "du -h -d 1";
      k = "killall";
      p = "ps aux | grep $1";
      l = "eza --color=auto --icons -h";
      ll = "eza --color=auto --icons -lh";
      ls = "eza --color=auto --icons -h";
      la = "eza --color=auto --icons -lah";
    };
  };

  nix.settings = {
    trusted-users = [
      "root"
      "@wheel"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  nixpkgs.config.allowUnfree = true;

  environment.variables.EDITOR = "nvim";

  programs.git = {
    enable = true;
    config = {
      credential.helper = "!gh auth git-credential";
      user.name = "Armaan Lala";
      user.email = "armaanlala@gmail.com";
    };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/etc/nixos";
  };

  # Core system packages: root/service essentials + fundamental dev tools
  environment.systemPackages = with pkgs; [
    # System essentials
    vim
    nmap
    lsof
    strace

    # Core development tools
    git
    gcc
    python3
  ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkDefault true;
      KbdInteractiveAuthentication = lib.mkDefault true;
    };
  };
}
