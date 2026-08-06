# NixOS config review — cleanup & organization

**Repo:** `/home/armaan/dotfiles/.config/nixos` (symlinked from `/etc/nixos`)
**Scope:** 6 hosts, 13 modules, 1333 lines of Nix
**Date:** 2026-08-06 (commit `712887c`, working tree dirty)

Line references are to the **working tree**, not `HEAD`. Six files are currently modified:
`flake.lock`, `flake.nix`, `hosts/drapion/configuration.nix`, `hosts/proton/configuration.nix`, `modules/desktop.nix`, `modules/dev.nix`.

## How this was verified

Every claim below was checked against the config, then independently audited by a second pass that re-derived the numbers and tested the proposed code. Corrections from that audit are folded in.

- All 6 hosts evaluate cleanly in **pure** mode (`nix eval .#nixosConfigurations.<h>.config.system.build.toplevel.drvPath`), with no `NIXPKGS_ALLOW_UNFREE` needed. Nothing here is currently broken.
- Package attribute names in `dev.nix` / `desktop.nix` / `gaming.nix` were resolved against both the locked stable (25.11) and unstable nixpkgs. All exist; no typos.
- Duplicate packages were found by intersecting evaluated `environment.systemPackages` with `users.users.armaan.packages` **by store path** per host.
- Option defaults were read from the pinned nixpkgs source, not from memory.
- Formatting drift was measured with the flake's own treefmt wrapper (`--fail-on-change`) against a copy of the tree.
- `flake.lock` was parsed as JSON to attribute every duplicated input.
- VPN-Confinement's `wireguardConfigFile` handling was read from the pinned source; the store-copy question was tested directly.
- systemd ordering claims were checked against live units and boot journal timings on drapion.

---

## Snapshot

| Host       | Channel  | Role                                                  | Hardware                       |
| ---------- | -------- | ----------------------------------------------------- | ------------------------------ |
| `atlas`    | 25.11    | \*arr stack + VPN-confined sabnzbd                    | generic VM (label disks)       |
| `proton`   | 25.11    | Jellyfin                                              | VM, own hw config              |
| `lenix`    | 25.11    | Jellyfin + Immich                                     | bare metal, GRUB/BIOS          |
| `webserv`  | 25.11    | copyparty, vikunja, actual, open-webui, suwayomi      | generic VM                     |
| `thinkpad` | 25.11    | laptop desktop                                        | X1 Yoga 7th gen                |
| `drapion`  | unstable | workstation, Ollama/ROCm, nginx static sites, libvirt | Ryzen 7800X3D + AMD GPU, btrfs |

The bones are good: hosts are thin, `modules/nfs.nix` and `modules/open-webui.nix` show you already know how to write real options, and `autoUpgrade`-from-GitHub is a clean deployment story. Most of what follows is _organizational drift_ — things that accumulated rather than things that are wrong. The exceptions are in Tier 1.

---

# Tier 1 — Correctness and operational risk

### 1. Unpushed work vs. hosts that auto-upgrade from GitHub

**What's there:** six modified files, none pushed. `HEAD` equals `origin/main` at `712887c`, so **nothing in the working tree is on GitHub** — including the `flake.nix` rewrite (~88 lines, inlining `mkNixosConfig` back into six explicit `nixosSystem` blocks) and the drapion ollama/GPU ordering fix.

**Why it matters:** `common.nix:235` points every host at `github:ArmaanLala/nixos#${hostname}` every Saturday at 03:00. Local edits to `/etc/nixos` are invisible to that job. Rebuild drapion locally today, forget to push, and next Saturday it reverts to `712887c` — silently losing the udev rule and the `dev-dri-renderD128.device` ordering, and quietly putting Ollama back on CPU. That's the exact failure the fix was written to prevent, which makes this more than a hygiene point.

**Change:** commit and push before relying on a local rebuild. Longer term, make divergence visible — a motd/fastfetch hook or a timer that warns when `/etc/nixos` is dirty or behind `origin/main` costs ~10 lines. See also #21: CI on `main`, since a broken `main` breaks all six hosts at once.

---

### 2. Ollama is exposed to the whole LAN with no authentication

**What's there:** `hosts/drapion/configuration.nix:36` sets `services.ollama.host = "[::]"`, and line 57 opens `11434` in `networking.firewall.allowedTCPPorts`.

**Why it matters:** Ollama has no auth of any kind. Anything on `10.0.0.0/24` can enumerate your models, run inference on your 7900 XTX, and — via `POST /api/pull` and `DELETE /api/delete` — add or destroy models in the store. The only consumer in this repo is `webserv`'s open-webui (`openWebui.ollamaUrl = "http://drapion:11434"`), which is a single known host.

**Change:** bind to the tailnet interface, or firewall the port to the one client that needs it:

```nix
networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 11434 ];
# and drop 11434 from the global allowedTCPPorts list
```

If open-webui reaches drapion over LAN rather than tailnet, scope it to that address instead. Either way, `allowedTCPPorts` fleet-wide is too broad for an unauthenticated inference endpoint.

---

### 3. copyparty is an anonymous read-write file server

**What's there** (`hosts/webserv/configuration.nix:24-43`): volume `"/"` → `/mnt/copyparty` with `access.rw = "*"`, listening on `0.0.0.0:3923`, port opened at line 57.

**Why it matters:** `*` is copyparty's everyone/anonymous principal. Any device on the LAN — including anything that joins your wifi — can read _and write_ the NFS share behind it, with no credential. Immich (`host = "0.0.0.0"`, `openFirewall = true`) is in the same category, though at least it has a login.

**Change:** if this is deliberate for LAN convenience, say so in a comment so it survives review. If not, copyparty supports accounts and per-volume grants:

```nix
services.copyparty = {
  accounts.armaan.passwordFile = "/run/secrets/copyparty-armaan";
  volumes."/" = {
    path = "/mnt/copyparty";
    access = { r = "*"; rw = [ "armaan" ]; };   # or drop r entirely
  };
};
```

---

### 4. drapion: password SSH is force-enabled, and `@wheel` is a trusted nix user

**What's there:** `common.nix:128` sets `security.sudo.wheelNeedsPassword = false` (default is `true`), `common.nix:191-194` sets `nix.settings.trusted-users = [ "root" "@wheel" ]`, and `hosts/drapion/configuration.nix:143` does `services.openssh.settings.PasswordAuthentication = lib.mkForce true`.

**Why it matters:** key-only auth everywhere else is doing nothing for this one host. Note the honest version of the severity argument: `trusted-users = [ "@wheel" ]` is _already_ root-equivalent — a trusted user can hand the nix daemon arbitrary derivations and substituters — so the marginal risk from passwordless sudo is smaller than it first looks. The real issue is that a guessable password is now a **network-reachable** path to that whole bundle. The `mkForce` also has no comment explaining why it exists.

**Change:** narrow the exception rather than deleting it:

```nix
# Password SSH is only for <reason>; restrict it to the LAN + tailnet.
services.openssh.extraConfig = ''
  Match Address 10.0.0.0/24,100.64.0.0/10
    PasswordAuthentication yes
'';
```

and drop the `mkForce`. Verified: the sshd module appends `extraConfig` last and its own directives use `mkOrder 0`, so the `Match` block lands after `PasswordAuthentication no` and the generated config passes `sshd -t`. One latent gotcha — any _future_ `extraConfig` from another module would land inside the `Match` block, so keep it last or use `mkOrder`.

---

### 5. `media-server.nix`: half the \*arr services run as `armaan`, half don't — check before changing

**What's there** (`modules/media-server.nix:5-19`, paraphrased — the file spells each attribute on its own line):

```nix
services.radarr   = { enable = true; openFirewall = true; user = "armaan"; group = "armaan"; };
services.sonarr   = { enable = true; openFirewall = true; user = "armaan"; group = "armaan"; };
services.prowlarr = { enable = true; openFirewall = true; };   # no user/group
services.bazarr   = { enable = true; openFirewall = true; };   # no user/group
```

**Why it matters — and what's actually unknown:** radarr/sonarr were given the `armaan` identity so they can write to `/mnt/media` (NFS from truenas). Bazarr writes subtitles into that same tree as its own uid. Whether that _succeeds_ depends entirely on the truenas export's `maproot`/`mapall` settings, which aren't in this repo and weren't inspected — it may well be working fine today. Prowlarr genuinely doesn't need it (indexer proxy, touches no media), but nothing in the file says so, so the asymmetry reads as an oversight either way.

**Change:** first, check reality — `ls -l` a recently-downloaded subtitle and see which uid owns it. Then either add a comment recording why bazarr is fine, or fold it in with the writers:

```nix
{ lib, ... }:
let
  # Services that write into the NFS media tree must share the armaan identity.
  mediaWriters = [ "radarr" "sonarr" "bazarr" ];
  # Indexer proxy; touches no media, keeps its own user.
  indexers = [ "prowlarr" ];
in
{
  services =
    lib.genAttrs mediaWriters (_: {
      enable = true; openFirewall = true; user = "armaan"; group = "armaan";
    })
    // lib.genAttrs indexers (_: { enable = true; openFirewall = true; });
}
```

(Verified this evaluates to the right 4-service attrset; `//` binds looser than application, and `services.bazarr` does have `user`/`group` options.)

**Migration hazard if you do flip bazarr:** the 25.11 bazarr module's tmpfiles rule re-owns `/var/lib/bazarr` itself but **not its existing contents**, so bazarr-as-armaan can fail on its own pre-existing SQLite DB. `chown -R armaan:armaan /var/lib/bazarr` in the same change.

---

### 6. `immich.nix` creates a directory on an NFS automount

**What's there** (`modules/immich.nix:12-14`): `systemd.tmpfiles.rules = [ "d /mnt/immich/media 0755 immich immich -" ]`, while lenix mounts `/mnt/immich` from truenas with `x-systemd.automount,noauto,soft,timeo=30`.

**Why it matters:** measured on drapion (same mount options), the automount unit is established at t≈7.0s and `systemd-tmpfiles-setup.service` runs at t≈9.1s — so the autofs trigger is always armed first, and tmpfiles _will_ fire the mount. If truenas isn't reachable, you block for the `timeo=30` window during early boot. The `chown immich:immich` additionally depends on the export's id-mapping cooperating.

**Change:** **the obvious fix does not work** — adding `after`/`requires` on `mnt-immich.mount` to `systemd-tmpfiles-setup` creates an ordering cycle (`tmpfiles-setup → sysinit.target → basic.target → NetworkManager-wait-online → network-online.target → mnt-immich.mount → tmpfiles-setup`), which systemd breaks by dropping a job nondeterministically. Don't do that.

Correct options, in order of preference:

1. Create `media/` once on truenas with the right ownership and **delete the tmpfiles rule**. Simplest, and the export owns its own layout.
2. Hang it off immich instead of early boot:
   ```nix
   systemd.services.immich-server = {
     after = [ "mnt-immich.mount" ];
     requires = [ "mnt-immich.mount" ];
   };
   ```
   plus an `ExecStartPre` mkdir, or a oneshot ordered `After=remote-fs.target`.

---

### 7. `modules/vpn.nix` only works if the flake also added the vpn-confinement module

**What's there:** `flake.nix:40` adds `vpn-confinement.nixosModules.default` to atlas _only_, while `modules/vpn.nix` (which defines `vpnNamespaces.wg`) sits in the shared `modules/` directory looking like any other importable module.

**Why it matters:** importing it from a second host gives an `option does not exist` error with no hint that the fix lives in `flake.nix`. A trap you'll hit exactly once, six months from now.

**Change:** make the module self-contained, the way `webserv` already handles copyparty —

```nix
# modules/vpn.nix
{ vpn-confinement, ... }:
{
  imports = [ vpn-confinement.nixosModules.default ];
  vpnNamespaces.wg = { ... };
}
```

with `vpn-confinement` threaded through `specialArgs`. Failing that, a one-line comment at the top of the file.

_Note on the secret:_ `wireguardConfigFile = "/etc/nixos/secrets/proton.conf"` is correct as a **quoted string**. The option's type is `path`, but `types.path`'s merge is `mergeEqualOption` with a string-shaped check — no store copy — and vpn-up.nix interpolates it into a shell script read at runtime. So the secret stays out of `/nix/store`. If you ever "clean this up" into a bare path literal, it won't leak — it will **fail evaluation outright** with `access to absolute path '/etc/nixos/secrets/proton.conf' is forbidden in pure evaluation mode`, on every host. Loud, not silent, but still worth a comment saying the string form is deliberate.

---

# Tier 2 — Deduplication and structure

### 8. All six hosts import `common.nix` and `nfs.nix` by hand

Twelve lines of ceremony, plus a failure mode where a new host silently misses `common.nix`. The `../../modules/` relative paths are also why these modules can't be reused or tested from outside the repo.

**Change:** hoist the universal ones into the flake and expose the rest:

```nix
nixosModules = {
  common = ./modules/common.nix;
  nfs = ./modules/nfs.nix;
  desktop = ./modules/desktop.nix;
  # ...
};
# in each nixosSystem:
modules = [ self.nixosModules.common self.nixosModules.nfs ./hosts/atlas/configuration.nix ];
```

Hosts then import only what makes them _different_.

---

### 9. NFS mount strings are repeated 16 times

13 `truenas:/mnt/wdblue/*` strings plus 3 `ts-truenas:` ones (thinkpad, which reaches the NAS over the tailnet).

**Change:** extend the option you already have. **Careful — the mapping isn't uniform:** `/mnt/media` → `wdblue/arr` on five hosts, and `/mnt/buzz` → `wdblue/phub`. A bare `[ "media" "games" ]` list would silently generate the nonexistent `/mnt/wdblue/media`. Use an attrset so the two renames are expressible:

```nix
options.nfs = {
  server = lib.mkOption {
    type = lib.types.str;
    default = "truenas";
    description = "Host to reach the NAS by. Roaming hosts use ts-truenas.";
  };
  shares = lib.mkOption {
    # { localName = shareNameUnderWdblue; }
    type = lib.types.attrsOf lib.types.str;
    default = { };
  };
};

config.fileSystems = lib.mapAttrs' (local: share:
  lib.nameValuePair "/mnt/${local}" (mkNfsMount "${config.nfs.server}:/mnt/wdblue/${share}")
) config.nfs.shares;
```

Hosts become:

```nix
nfs.shares = { games = "games"; immich = "immich"; media = "arr"; manga = "manga"; nightbeef = "nightbeef"; };
nfs.server = "ts-truenas";   # thinkpad only
```

If the `x = x;` repetition annoys you, default the value to the key. Keep the raw `nfsMounts` attrset available for anything that doesn't fit.

---

### 10. Hostnames are written three times each

The attr name in `flake.nix`, `networking.hostName` in the host file, and an entry in the `networking.hosts` table.

**Change:** if you reintroduce a host-generating helper, `modules = [ { networking.hostName = name; } ... ]` removes one copy for free. Noting you _just_ removed `mkNixosConfig` in the working tree — if that was deliberate, skip this. Six explicit blocks are ~30 lines and are arguably clearer when hosts differ in channel and extra modules; I wouldn't push you back.

---

### 11. `networking.hosts` is a 36-entry static table pushed to every machine

`common.nix:33-78` — 46 lines, 25 LAN entries and 11 tailnet entries (37 hostnames; `100.103.38.71` has two). Several names appear nowhere else in the repo: `weed`, `teapot`, `alpine`, `hydra`, `loki`, `calliope`, `iris`.

**Why it matters:** thinkpad is a laptop, and it carries this map to every coffee shop, where `10.0.0.x` may be someone else's devices. More concretely: **`n8n.com` is a real public domain**, and this table hijacks it in `/etc/hosts` on all six machines. Same shape of problem with `webserv.com`. You also already run pihole, Tailscale MagicDNS, and avahi/mDNS — three working name services this table bypasses.

**Change:** rename the `.com` entries to something unambiguously local (`n8n.lan`), then either **trim** (drop the tailnet block entirely if MagicDNS is on; it gives you `atlas`, `drapion` etc. for free) or **restructure** into `modules/inventory.nix` keyed by hostname, which is how you actually look things up:

```nix
inventory.lan = { atlas = "10.0.0.174"; drapion = "10.0.0.183"; ... };
networking.hosts = lib.mapAttrs' (n: ip: lib.nameValuePair ip [ n ]) config.inventory.lan;
```

The inventory then doubles as the network documentation nothing currently provides.

---

### 12. `desktop.nix` is carrying gaming, and `gaming.nix` is half-empty

`desktop.nix:78-80` has `wineWow64Packages.waylandFull`, `itch`, `protonup-qt`; `desktop.nix:127-128` has `mgba`, `melonds`; drapion adds `steamtinkerlaunch`, `winetricks`, `r2modman`. Meanwhile `gaming.nix` (28 lines) has Steam, gamemode, mangohud, `protonup-ng`.

You can't answer "what do I get from gaming.nix" by reading gaming.nix. Also `protonup-ng` and `protonup-qt` are two frontends for the same job, both installed on both desktop hosts.

**Change:** move it all into `gaming.nix` and pick one protonup. Both desktop hosts import both modules, so the _set_ of installed packages doesn't change — but note the move shifts them from `users.users.armaan.packages` to `environment.systemPackages` (gaming.nix's existing style), i.e. from armaan-only to system-wide. Keep them in `users.users.armaan.packages` inside gaming.nix if you'd rather not.

---

### 13. Genuinely duplicate packages

Measured by store-path intersection on the evaluated configs:

| Package       | Where                                                                                                                                                   | Fix                                                                                  |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `fish`        | `common.nix:120` user packages **and** `programs.fish.enable` (which adds `pkgs.fish` to `systemPackages` itself — verified at `programs/fish.nix:319`) | drop from user packages                                                              |
| `claude-code` | `desktop.nix:95` (user) **and** `hosts/drapion:121` (system)                                                                                            | drop one — note they differ in scope; removing drapion's takes it out of root's PATH |
| `firefox`     | drapion + thinkpad, but not `desktop.nix`                                                                                                               | move to `desktop.nix`                                                                |

Also a decision, not a bug: two compositors (niri + hyprland), two bars (waybar + quickshell), two notification daemons (mako + dunst), two terminals (ghostty + alacritty). Fine if deliberate; if it's migration residue, dropping the losers cuts real closure size.

---

### 14. Two host files have become grab bags

**drapion (155 lines)** mixes AMD GPU + ROCm, Ollama (now with a udev rule and device ordering), nginx static sites (~35 lines), libvirt, QMK udev rules, and 15 packages.

**webserv (83 lines)** mixes inline copyparty config, vikunja, actual, and two oci-containers — structurally the same problem, and worth saying plainly since the rest of the hosts are 22-34 lines.

**Change:** extract the self-contained features. The nginx block is the clearest candidate — it has a real design (content lives outside the repo in `/var/www`, published by rsync, dotfiles 404'd). `modules/static-sites.nix` with an option:

```nix
staticSites = { alpd = { port = 8417; }; givememoney = { port = 8418; }; };
```

generating the tmpfiles rules, virtualHosts, **and** firewall ports — currently a hand-maintained third list at `drapion:57`. Same treatment for `modules/ollama.nix` (the GPU-ordering logic deserves to be findable) and `modules/libvirt.nix`; webserv's containers → `modules/suwayomi.nix`.

---

### 15. `vm.nix`'s `useGenericHardware` option exists to be turned off

61 lines and an `mkMerge` to express "two things sometimes both wanted", with one consumer whose only use is disabling most of it (`proton` sets `vm.useGenericHardware = false`).

**Change:** split into `modules/vm-guest.nix` (qemuGuest, growPartition, autoResize — ~6 lines) and `modules/vm-disks.nix`. atlas/webserv import both; proton imports only the guest half. The option, the `mkMerge`, and the comment explaining the option all disappear.

---

### 16. `modules/` is flat and mixes three kinds of thing

13 files spanning fleet policy (`common.nix`), roles (`desktop`, `dev`, `gaming`, `media-server`), single services (`jellyfin` — 8 lines, `immich` — 15), and infrastructure (`nfs`, `vm`, `podman`, `vpn`).

```
modules/
  core/       common.nix  inventory.nix
  hardware/   vm-guest.nix  vm-disks.nix  nfs.nix
  roles/      desktop.nix  dev.nix  gaming.nix  media-server.nix
  services/   jellyfin.nix  immich.nix  open-webui.nix  static-sites.nix
              ollama.nix  vpn.nix  podman.nix  suwayomi.nix
```

Combine with #8 so hosts reference `self.nixosModules.jellyfin` and never touch a relative path. `vpn.nix` + `vpn-sabnzbd.nix` are only ever used together by one host — merge unless a second VPN-confined client is planned.

---

# Tier 3 — Flake and tooling hygiene

### 17. The `claude-code` input is dead

`flake.nix:12` declares it, but the uncommitted change removed its overlay from `desktop.nix` and the outputs function no longer destructures it. Both `desktop.nix:95` and drapion now get `claude-code` from nixpkgs (2.1.140 stable / 2.1.222 unstable — both verified).

**Change:** delete the input. It costs a whole extra nixpkgs-unstable node in the lock and shows up in every `nix flake update` diff for nothing.

---

### 18. `flake.lock` carries six nixpkgs nodes

Parsed from the lock:

| node               | pulled by      | channel                  |
| ------------------ | -------------- | ------------------------ |
| `nixpkgs`          | claude-code    | nixpkgs-unstable         |
| `nixpkgs-unstable` | **you**        | nixos-unstable (drapion) |
| `nixpkgs_2`        | copyparty      | **nixos-25.05**          |
| `nixpkgs_3`        | nixos-hardware | unstable channel tarball |
| `nixpkgs_4`        | **you**        | nixos-25.11              |
| `nixpkgs_5`        | pwndbg         | nixpkgs-unstable         |

So four _third-party_ copies on top of your two. Your `flake.nix` declares exactly one `follows` (treefmt-nix). Notably, `webserv` builds copyparty against a nixpkgs two releases behind everything else on that machine.

**Change:** add follows one at a time, rebuilding after each:

```nix
nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";   # saves a full channel tarball fetch
copyparty.inputs.nixpkgs.follows = "nixpkgs";
pwndbg.inputs.nixpkgs.follows = "nixpkgs";
```

Two caveats. **Do not** add `vpn-confinement.inputs.nixpkgs.follows` — that flake has no inputs at all, so it's a no-op that emits `warning: input 'vpn-confinement' has an override for a non-existent input 'nixpkgs'` on every evaluation, forever. And `pwndbg` drags a whole `uv2nix`/`pyproject-nix` stack (all three already follow _its_ nixpkgs), so it's the most likely to break under a forced override — if it does, revert it and leave a comment saying why. Deleting the dead `claude-code` input (#17) removes one node for free.

---

### 19. Formatting has drifted in exactly one file

Your own treefmt wrapper with `--fail-on-change`: **27 files processed, 1 changed** — `hosts/drapion/hardware-configuration.nix`, still in nixos-generate-config's single-line-list style while every other host's has been nixfmt'd.

**Change:** `nix fmt`. The "do not modify this file" header is about content, not whitespace — you already reformatted lenix's and thinkpad's.

---

### 20. The flake has no `checks`, so treefmt is advisory

```nix
let treefmtEval = treefmt-nix.lib.evalModule pkgs ./lib/treefmt.nix;
in {
  formatter.${system} = treefmtEval.config.build.wrapper;
  checks.${system}.formatting = treefmtEval.config.build.check self;
}
```

(Verified against treefmt-nix's `module-options.nix`: `build.check` is `functionTo package` and expects the project tree, usually `self`. This needs `self` back in the outputs argument list — the uncommitted change removed it.)

---

### 21. No CI, on a fleet that pulls `main` unattended

Highest-leverage item in this tier. Six machines rebuild from `github:ArmaanLala/nixos` every Saturday and nothing verifies `main` evaluates first.

```yaml
strategy:
  matrix:
    host: [atlas, proton, lenix, webserv, thinkpad, drapion]
steps:
  - uses: actions/checkout@v4
  - uses: DeterminateSystems/nix-installer-action@main
  - run: nix eval .#nixosConfigurations.${{ matrix.host }}.config.system.build.toplevel.drvPath
```

Evaluation alone catches the realistic failures — options renamed after a `flake update`, typo'd attrs, missing imports — in about a minute per host with no build capacity. Confirmed this works in pure mode with no unfree special-casing, since `nixpkgs.config.allowUnfree` is set inside the config itself. Add `nix flake check` once #20 lands.

Pair with `OnFailure=` on `nixos-upgrade.service` pinging ntfy/email, so a host that fails to upgrade tells you instead of quietly staying behind.

---

### 22. Small redundancies in `common.nix`

- `services.xserver.xkb.layout = "us"` (line 17) — verified `"us"` is already the default (`xserver.nix:469`). Delete, or keep with a comment marking it as documentation.
- `services.avahi.publish.enable` is set at `common.nix:27-28` and again at `desktop.nix:12`. Same value, merges fine; the desktop copy only needs `userServices = true`.
- `nix.extraOptions = "!include /etc/nix/github-token.conf"` (lines 186-188) is correct as written — `man 5 nix.conf`: "A missing file is an error unless `!include` is used instead." Worth a comment saying that's deliberate, because it reads like a landmine. See also #27 — that file is an undocumented secret.

### 23. `dev.nix` installs the formatters treefmt already provides

Lines 72-79 install `treefmt`, `nixfmt`, `rustfmt`, `stylua`, `shfmt`, `taplo`, `yamlfmt`, `prettier` — the same set `lib/treefmt.nix` declares and that the `nix fmt` wrapper already pins. Two sources of truth for formatter versions.

**Change:** keep only what your editor/LSP invokes directly (`nixfmt`, `ruff`, `clang-tools`); drop the rest in favour of `nix fmt`. Especially drop bare `treefmt`, which will pick up a different config than the flake's.

### 24. Pin the registry so ad-hoc `nix shell` uses your nixpkgs

```nix
nix.registry.nixpkgs.flake = nixpkgs;
nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
```

`nix shell nixpkgs#foo` currently fetches a _different_ nixpkgs than your system is built from — slow, and a source of "why is this version different". Verified this produces a correct `/etc/nix/registry.json`. It needs the input threaded through `specialArgs`, which currently passes only `copyparty` and `pwndbg` — a good reason to pass `inputs` wholesale.

### 25. SDDM is running as an X11 greeter

`desktop.nix:10` enables `services.xserver` with the comment "for XWayland support". XWayland actually comes from `programs.hyprland.xwayland.enable` (already set) and `xwayland-satellite` (already installed). What `xserver.enable` is really doing is satisfying SDDM's assertion (`sddm.nix:349`: `xcfg.enable || cfg.wayland.enable`), so removing it requires setting `sddm.wayland.enable = true` in the same commit.

That option is still `mkEnableOption "experimental Wayland support"` upstream, so this is a "try it, keep a rollback generation" change rather than a safe cleanup. **If you keep X11, fix the comment** — it states the wrong reason, which is precisely how this survives future cleanups.

### 26. Comments that state the wrong thing

Two found, and they're worth treating as a category since #25 is a third:

- `hosts/drapion/configuration.nix:26`: "_btrfs via disko_" — `grep -rn disko` across all `*.nix` and `flake.lock` returns only this comment. drapion uses a stock `nixos-generate-config` hardware file with a hardcoded `by-uuid` btrfs root. Either adopt disko or fix the comment; right now it would send you looking for a `disko.nix` that never existed.
- `desktop.nix:71`: "_System integration tools like polkit_gnome and xdg-desktop-portals are in environment.systemPackages_" — still true, but it's describing a split the file no longer makes obvious.

---

# Tier 4 — Bigger bets

### 27. Secrets: you already have two, not one

`docs/secrets.md` documents `/etc/nixos/secrets/proton.conf` (atlas, proton). But `common.nix:186` also references `/etc/nix/github-token.conf` on **every** host — a GitHub token that isn't in the repo, isn't in the docs, and has _no_ documented provisioning step at all. A rebuilt host is silently degraded until someone remembers it exists.

Both work today, and as established in #7 the VPN one is store-safe. The problem is undeclared state.

`sops-nix` with host age keys derived from existing SSH host keys would let both live encrypted **in the repo** — which matters specifically here because `autoUpgrade` fetches from GitHub, so the flake source is already your delivery mechanism for everything else. Cost: one input, one module, a key ritual. Your own threshold ("worth it at 2") is already met. Minimum viable alternative: add the github token to `docs/secrets.md` today.

### 28. home-manager — probably not yet

`common.nix` manages user-level concerns (fish aliases, `EDITOR`, git identity, user packages) through NixOS options. That works and is simpler. Given you're already using `stow` for dotfiles, home-manager is a large migration whose main payoff is managing config _files_ (starship, tmux, fish functions) declaratively. Flagging the fork in the road, not recommending it — revisit if the stow side starts fighting you.

### 29. A README

There's `docs/secrets.md` and nothing else. What a future you will want: the host table from the top of this report, the deploy model (autoUpgrade from GitHub, weekly, no reboot), how to add a host, and where secrets come from. Ten minutes, and it's the difference between self-explanatory and archaeology. Pairs naturally with #11's inventory module.

---

# Suggested order

**Cheap and safe, do first**

1. Push the pending work (#1)
2. `nix fmt` (#19)
3. Delete the `claude-code` input (#17)
4. Remove duplicate `fish` / `claude-code` / redundant `xkb.layout` (#13, #22)
5. Add `checks.formatting` + the CI workflow (#20, #21)
6. Fix the `disko` and XWayland comments (#25, #26)

**Security posture, before more refactoring**

7. Scope Ollama's port (#2)
8. Decide copyparty's access model (#3)
9. Narrow or delete drapion's password SSH (#4)

**Structural, one PR each**

10. Hoist `common.nix`/`nfs.nix`, export `nixosModules` (#8)
11. `nfs.shares` / `nfs.server` options (#9)
12. Split `vm.nix` (#15)
13. Extract `static-sites.nix` / `ollama.nix` / `libvirt.nix` from drapion; `suwayomi.nix` from webserv (#14)
14. Reorganize `modules/` into subdirectories (#16)

**Needs a decision or a check from you**

15. bazarr's uid (#5) — `ls -l` a recent subtitle first
16. `networking.hosts` (#11) — trim or restructure? (`n8n.com` should change either way)
17. Duplicate desktop stacks (#13) — deliberate or residue?
18. sops-nix (#27) — or at minimum document the github token

---

## Deliberately not suggested

- **Splitting `common.nix` (244 lines).** Long but cohesive — it's "what every machine gets", and every section has a header. Splitting into `users.nix`/`nix-settings.nix`/`shell.nix` adds five files and zero clarity.
- **Option-gating every module (`myModules.jellyfin.enable`).** Import-to-enable is simpler and correct for a 6-host personal fleet. Options earn their keep when a module needs _parameters_ — which is exactly where you already use them (`nfsMounts`, `openWebui.ollamaUrl`, and the proposed `staticSites`).
- **Unifying `stateVersion`.** `25.05` on atlas/proton/webserv vs `25.11` elsewhere is correct — it records when each host was installed and must not be "fixed".
- **Moving drapion off unstable.** Deliberate and documented. The alternative (an `unstable` overlay for individual packages on stable hosts) is more machinery than it's worth while only one host wants it.
- **Restructuring atlas / proton / lenix / thinkpad.** 22-34 lines each, all of it genuinely host-specific. Already the right shape. (drapion and webserv are the exceptions — see #14.)
