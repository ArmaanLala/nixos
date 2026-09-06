# Common configuration shared across all hosts
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./sops.nix ];

  # === Boot & System ===
  boot.loader.systemd-boot.enable = lib.mkDefault true;

  # 2026-09-05: without this, systemd-boot keeps a kernel+initrd pair in the ESP
  # for every generation and eventually fills it -- on beard (then drapion) that
  # meant a hard
  # `No space left on device` mid-bootloader-install, which aborts the switch and
  # leaves a half-copied .tmp behind. Note the installer writes entries for EVERY
  # generation in the system profile, so a too-full ESP keeps failing until old
  # generations are actually deleted, not just skipped.
  # beard's ESP was only 127M and a single 6.18.49 kernel+initrd is ~41M, so it
  # fits about three distinct kernel builds. The real fix is a bigger ESP.
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 5;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;

  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # === Networking ===
  services.tailscale = {
    enable = true;
    # Without this tailscaled shoves 100.100.100.100 into resolvconf at a higher
    # priority than NetworkManager on every start/reconnect, so pihole
    # (10.0.0.222) never wins and local DNS breaks. MagicDNS names aren't needed
    # -- the tailnet IPs are pinned in `networking.hosts` below.
    # extraUpFlags would be a no-op here; it only runs with an authKeyFile.
    extraSetFlags = [ "--accept-dns=false" ];
  };
  networking.networkmanager.enable = true;
  networking.firewall.enable = lib.mkDefault true;

  # Pin pihole ahead of whatever DHCP hands out, so DNS doesn't depend on the
  # router advertising it. openresolv `name_servers` prepends to the dynamic
  # list; the DHCP-provided servers still follow as fallback. No public resolver
  # is appended on purpose -- if pihole is down DNS should fail loudly rather
  # than quietly resolving around the ad-blocking.
  #
  # `networking.nameservers` is NOT the option for this: in nixpkgs it only
  # feeds the networkd/dhcpcd paths and is never read by config/resolvconf.nix,
  # so under NetworkManager + resolvconf it silently does nothing.
  #
  # mkDefault so roaming hosts can drop the pin -- 10.0.0.222 is unreachable
  # off-LAN and would stall every fresh lookup until it times out.
  networking.resolvconf.extraConfig = lib.mkDefault ''
    name_servers='10.0.0.222'
  '';

  # iperf3: 5201 is control (TCP) and data, so UDP tests (-u) need UDP open too.
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
    # Local network
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
    # Same box: renamed drapion -> beard on 2026-09-05. Both names kept
    # pointing here so anything still saying "drapion" resolves.
    "10.0.0.183" = [
      "beard"
      "drapion"
    ];
    "10.0.0.186" = [ "lenix" ];
    "10.0.0.200" = [ "hydra" ];
    "10.0.0.201" = [ "loki" ];
    "10.0.0.202" = [ "calliope" ];
    "10.0.0.203" = [ "iris" ];
    "10.0.0.222" = [ "pihole" ];
    "10.0.0.250" = [ "alpine" ];

    # Tailscale IPs
    "100.76.77.32" = [ "macbook" ];
    "100.90.169.115" = [ "ts-atlas" ];

    # Stale until beard rejoins the tailnet -- update the IP after `tailscale up`.
    "100.99.14.97" = [
      "ts-beard"
      "ts-drapion"
    ];
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

  # === Users ===
  users.groups.armaan = {
    gid = 1000;
  };

  users.users.armaan = {
    isNormalUser = true;
    description = "Armaan Lala";
    # Pinned, not auto-allocated. Without this the uid comes from
    # /var/lib/nixos/uid-map, which is state -- so a reinstall onto an empty
    # disk is free to hand out a different number, and every file restored from
    # a backup with --numeric-owner then belongs to a uid that no longer exists.
    # users.groups.armaan.gid above was already pinned for the same reason.
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
      # CLI tools
      ripgrep
      fd
      lazygit
      delta # configured in programs.git below
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
      # fish itself comes from programs.fish.enable
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

  # Spliced into /etc/ssh/ssh_config ahead of the module's own `Host *` block,
  # so anything here wins. First match per keyword wins, hence `Host *` last;
  # short names resolve through `networking.hosts` above, not HostName lines.
  # Non-NixOS clients (macbook) never get this -- copy to ~/.ssh/config there.
  programs.ssh.extraConfig = ''
    # The NanoKVM. Its web UI has its own separate account -- these are the
    # system credentials, and root is the only user on the device.
    Host kvm ts-kvm
      User root

    Host atlas proton lenix webster thinkpad beard
      User armaan

    # Tailscale twins -- the bare names above are 10.0.0.x and hang off-LAN.
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
      # github disconnects after too many wrong key offers from the agent.
      IdentitiesOnly yes

    Host *
      IdentityFile ~/.ssh/id_ed25519
      # Reuse one connection per host. %C hashes the destination to keep the
      # socket path under the ~104 char unix socket limit.
      ControlMaster auto
      ControlPath ~/.ssh/control-%C
      ControlPersist 5m
      # Ride out brief wifi drops and suspends instead of dropping the shell.
      ServerAliveInterval 60
      ServerAliveCountMax 3
  '';

  # === Shell ===
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

  # === Packages ===
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

  # === Nix Settings ===
  # `!include` (not `include`) tolerates the file being absent, so unprovisioned
  # hosts still evaluate. See docs/secrets.md.
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

  # Make ad-hoc `nix shell nixpkgs#foo` / `nix-shell -p` use this host's own
  # nixpkgs instead of fetching a channel. pkgs.path is per-host correct.
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

      # delta highlights changed words within a line by default.
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true; # n / N jump between files in the diff
        line-numbers = true;
        hyperlinks = true; # ghostty turns file:line into clickable links
      };

      # delta reads these to render moved blocks and conflicts properly.
      diff.colorMoved = "default";
      merge.conflictstyle = "zdiff3";

      # Word/char granularity on demand, where delta's intra-line highlight
      # isn't enough.
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

  # === Auto Upgrade ===
  # Runs as root via nix with no local checkout, so no file-ownership /
  # "git pull needs root" problems. The module adds --refresh automatically, so
  # every run sees the latest commit. See README "Deploy model".
  system.autoUpgrade = {
    enable = true;
    flake = "github:ArmaanLala/nixos#${config.networking.hostName}";
    dates = "Sat *-*-* 03:00:00";
    randomizedDelaySec = "45min";
    persistent = true;
    allowReboot = false;
    flags = [ "-L" ];
  };
}
