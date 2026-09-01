# Common configuration shared across all hosts
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Wakes drapion through the NanoKVM, which is the only always-on box that sits
  # on 10.0.0.0/24 and can therefore put a magic packet on the wire at all.
  #
  # No-op when drapion is already up, so it is safe to call unconditionally --
  # that is what lets the ProxyCommand below wrap every `ssh drapion`.
  wake-drapion = pkgs.writeShellScriptBin "wake-drapion" ''
    set -u

    MAC=d8:43:ae:45:60:68
    DRAPION=10.0.0.183
    # LAN address first (direct path), tailnet second so this still works
    # off-site. The KVM is reachable both ways.
    KVM_ADDRS="10.0.0.18 100.111.67.1"

    up() {
      ${pkgs.coreutils}/bin/timeout 2 \
        ${pkgs.bash}/bin/bash -c "echo >/dev/tcp/$1/22" 2>/dev/null
    }

    if [ "''${1:-}" != "--force" ] && up "$DRAPION"; then
      exit 0
    fi

    kvm=""
    for a in $KVM_ADDRS; do
      if up "$a"; then
        kvm=$a
        break
      fi
    done
    if [ -z "$kvm" ]; then
      echo "wake-drapion: cannot reach the KVM on any of: $KVM_ADDRS" >&2
      exit 1
    fi

    # etherwake puts a raw 0x0842 frame straight onto eth0. `wakeonlan` also
    # works but routes through the IP stack, and on this box it chose wlan0 --
    # the raw frame takes the interface out of the equation.
    ${pkgs.openssh}/bin/ssh -n -o BatchMode=yes -o ConnectTimeout=5 \
      -o StrictHostKeyChecking=accept-new \
      root@"$kvm" "etherwake -i eth0 $MAC" || exit 1
    echo "wake-drapion: magic packet sent via $kvm" >&2

    # S3 resume plus sshd is normally well under a minute; cap the wait so a
    # failed wake surfaces as an error instead of hanging the caller forever.
    n=0
    while [ $n -lt 60 ]; do
      if up "$DRAPION"; then
        echo "wake-drapion: drapion is up" >&2
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 2
      n=$((n + 1))
    done
    echo "wake-drapion: no response from drapion after 120s" >&2
    exit 1
  '';
in
{
  # === Boot & System ===
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

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
    "10.0.0.183" = [ "drapion" ];
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

    "100.99.14.97" = [ "ts-drapion" ];
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
    extraGroups = [
      "networkmanager"
      "wheel"
      "armaan"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPS2foqCO+tCzjg/CYsuaTX5SsjZyEpquDjbH4WXkLwR armaan@thinkpad 2025-12-03"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGWCoSW1PMIeftP7bqfZntLdRvhGBhpvzaLFZrXTvTrp armaanlala@apple-j616c 2025-12-03"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoygK39u8MDsc701vj1Vn9ow3eOtpk6kU+9UnmYrduq 2025-12-10 armaan@nix-thinkpad"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3BghIktdP46BOXdHpS2JgtytHs0SFIjv+58EP/Pniw armaan@drapion 04-03-2026"
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
    # drapion no longer idle-suspends (desktop.idleSuspend = false), but when it
    # is off for any other reason its NIC is asleep and a plain ssh would just
    # time out. `Match exec` runs the wake as a side effect while parsing the
    # config, then ssh connects directly -- unlike a ProxyCommand it keeps nc
    # out of the data path entirely.
    #
    # wake-drapion no-ops when the host is already up, so the usual cost is one
    # 2s TCP probe. The block must precede the group below: first match per
    # keyword wins, and a failed wake falls through to it for User.
    Match host drapion exec "${wake-drapion}/bin/wake-drapion"
      User armaan

    # The NanoKVM. Its web UI has its own separate account -- these are the
    # system credentials, and root is the only user on the device.
    Host kvm ts-kvm
      User root

    Host atlas proton lenix webster thinkpad drapion
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
    wake-drapion
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
