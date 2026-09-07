{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./sops.nix ];

  boot.loader.systemd-boot.enable = lib.mkDefault true;

  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 5;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;

  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--accept-dns=false" ];
  };
  networking.networkmanager.enable = true;
  networking.firewall.enable = lib.mkDefault true;

  networking.resolvconf.extraConfig = lib.mkDefault ''
    name_servers='10.0.0.222'
  '';

  networking.firewall.allowedTCPPorts = [ 5201 ];
  networking.firewall.allowedUDPPorts = [ 5201 ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

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
    "10.0.0.111" = [ "webster" ];
    "10.0.0.139" = [ "photos" ];
    "10.0.0.144" = [ "cftunnel" ];
    "10.0.0.160" = [ "truenas" ];
    "10.0.0.174" = [ "atlas" ];

    "10.0.0.18" = [ "kvm" ];
    "10.0.0.183" = [ "bread" ];
    "10.0.0.186" = [ "lenix" ];
    "10.0.0.200" = [ "hydra" ];
    "10.0.0.201" = [ "loki" ];
    "10.0.0.202" = [ "calliope" ];
    "10.0.0.203" = [ "iris" ];
    "10.0.0.222" = [ "pihole" ];
    "10.0.0.250" = [ "alpine" ];

    "100.76.77.32" = [ "macbook" ];
    "100.90.169.115" = [ "ts-atlas" ];

    "100.99.14.97" = [ "ts-bread" ];
    "100.111.67.1" = [ "ts-kvm" ];
    "100.106.33.35" = [ "iphone" ];
    "100.106.156.10" = [ "ts-lenix" ];
    "100.112.154.50" = [ "ts-nyx" ];
    "100.87.181.8" = [ "ts-proton" ];
    "100.103.38.71" = [
      "jumpbox"
      "ts-tailscale"
    ];
    "100.126.39.59" = [ "ts-thinkpad" ];
    "100.96.173.87" = [ "ts-webster" ];
    "100.91.201.78" = [ "ts-truenas" ];
  };

  users.groups.armaan = {
    gid = 1000;
  };

  users.users.armaan = {
    isNormalUser = true;
    description = "Armaan Lala";
    uid = 1000;
    extraGroups = [
      "networkmanager"
      "wheel"
      "armaan"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPS2foqCO+tCzjg/CYsuaTX5SsjZyEpquDjbH4WXkLwR armaan@thinkpad 2025-12-03"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGWCoSW1PMIeftP7bqfZntLdRvhGBhpvzaLFZrXTvTrp armaanlala@apple-j616c 2025-12-03"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoygK39u8MDsc701vj1Vn9ow3eOtpk6kU+9UnmYrduq 2025-12-10 armaan@nix-thinkpad"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3BghIktdP46BOXdHpS2JgtytHs0SFIjv+58EP/Pniw armaan@beard 04-03-2026"
    ];
    packages = with pkgs; [
      ripgrep
      fd
      lazygit
      delta
      neovim
      tree-sitter
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

      tmux
      fastfetch
      starship
      zoxide
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  programs.ssh.extraConfig = ''
    Host kvm ts-kvm
      User root

    Host atlas proton lenix webster thinkpad bread
      User armaan

    Host ts-* jumpbox
      User armaan

    Host truenas
      User truenas_admin

    Host pihole servarr seagate repoman
      User armaan

    Host dojo.pwn.college
      User hacker

    Host github.com
      User git
      IdentitiesOnly yes

    Host *
      IdentityFile ~/.ssh/id_ed25519
      ControlMaster auto
      ControlPath ~/.ssh/control-%C
      ControlPersist 5m
      ServerAliveInterval 60
      ServerAliveCountMax 3
  '';

  programs.bash.interactiveShellInit = ''
    if [[ $EUID -ne 0 && $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
    then
      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
      exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
    fi
  '';

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

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    screen
    p7zip
    tree
    file
    rsync
    pv
    nmap
    lsof
    strace
    pciutils
    stow
    iperf3
  ];

  nix.extraOptions = ''
    !include /etc/nix/github-token.conf
  '';

  nix.settings = {
    trusted-users = [
      "root"
      "@wheel"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://claude-code.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    ];
  };

  nix.registry.nixpkgs.to = {
    type = "path";
    path = pkgs.path;
  };
  nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

  nixpkgs.config.allowUnfree = true;
  environment.variables.EDITOR = "nvim";

  programs.git = {
    enable = true;
    config = {
      credential.helper = "!gh auth git-credential";
      user.name = "Armaan Lala";
      user.email = "armaanlala@gmail.com";

      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        line-numbers = true;
        hyperlinks = true;
      };

      diff.colorMoved = "default";
      merge.conflictstyle = "zdiff3";

      alias = {
        wdiff = "diff --word-diff=color";
        cdiff = "diff --color-words=.";
      };
    };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/etc/nixos";
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:ArmaanLala/nixos#${config.networking.hostName}";
    dates = "*-*-* 03:00:00";
    randomizedDelaySec = "45min";
    persistent = true;
    allowReboot = false;
    flags = [ "-L" ];
  };
}
