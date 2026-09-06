# nixos

Flake-based NixOS configuration for six machines. Lives at
`~/dotfiles/.config/nixos`, symlinked from `/etc/nixos`.

## Hosts

| Host       | Channel  | Role                                                                                   | Hardware                       |
| ---------- | -------- | -------------------------------------------------------------------------------------- | ------------------------------ |
| `atlas`    | 25.11    | \*arr stack, VPN-confined sabnzbd                                                      | generic VM (label disks)       |
| `proton`   | 25.11    | Jellyfin                                                                               | VM, own hardware config        |
| `lenix`    | 25.11    | Jellyfin + Immich                                                                      | bare metal, GRUB/BIOS          |
| `webster`  | 25.11    | copyparty, vikunja, actual, open-webui, suwayomi, vaultwarden, nextcloud, static sites | generic VM                     |
| `thinkpad` | 25.11    | laptop desktop                                                                         | ThinkPad X1 Yoga 7th gen       |
| `beard`    | unstable | workstation, Ollama/ROCm, libvirt                                                      | Ryzen 7800X3D + AMD GPU, btrfs |

`beard` (formerly `drapion`) deliberately tracks `nixos-unstable`; everything else tracks the 25.11
release. `system.stateVersion` differs per host (25.05 vs 25.11) — that records
when each host was installed and must never be "fixed" to match.

## Deploy model

Hosts do **not** deploy from a local checkout. Each one fetches this repo
straight from GitHub and rebuilds itself:

```nix
system.autoUpgrade = {
  flake = "github:ArmaanLala/nixos#${config.networking.hostName}";
  dates = "Sat *-*-* 03:00:00";
  allowReboot = false;
};
```

The practical consequence: **uncommitted local edits are invisible to the fleet,
and get reverted on the next Saturday run.** Push before relying on a local
rebuild.

Manual rebuild:

```
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
```

## Layout

```
flake.nix              inputs + one nixosSystem block per host
lib/treefmt.nix        formatter config behind `nix fmt`
modules/               shared modules, imported by relative path from hosts/
hosts/<name>/          per-host config + hardware-configuration.nix
docs/secrets.md        the three hand-provisioned secrets
```

`modules/common.nix` is what every machine gets: users, SSH keys, shell, the
`networking.hosts` table, nix settings, and autoUpgrade. Modules are
import-to-enable — importing `modules/jellyfin.nix` turns Jellyfin on. Where a
module needs _parameters_ it defines real options instead (`nfsMounts`,
`openWebui.ollamaUrl`).

## Adding a host

1. `hosts/<name>/configuration.nix` importing at minimum `../../modules/common.nix`,
   plus `networking.hostName` and `system.stateVersion`.
2. Its `hardware-configuration.nix` (or `../../modules/vm.nix` for a generic VM).
3. A `nixosSystem` block in `flake.nix`.
4. An entry in the `networking.hosts` table in `modules/common.nix`.
5. Add it to the CI matrix in `.github/workflows/check.yml`.
6. Provision any secrets it needs — see `docs/secrets.md`.

Renaming a host has a catch: autoUpgrade resolves `#${config.networking.hostName}`,
so once main carries only the new name, the still-old-named machine's timer fails
on a missing flake attribute until you rebuild it manually once.

## Checks

```
nix fmt                      # format (treefmt)
nix flake check              # formatting check
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
```

CI runs the per-host evaluation plus the formatting check on every push to main.
Evaluation catches the realistic breakage — options renamed by a flake update,
typo'd attributes, missing imports — without needing build capacity.
