# nixos

Flake-based NixOS configuration for six machines, all on `nixos-26.05`. Lives at
`~/dotfiles/.config/nixos`, symlinked from `/etc/nixos`.

| Host       | Role                                                                                                  | Hardware                           |
| ---------- | ----------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `atlas`    | \*arr stack, VPN-confined sabnzbd                                                                     | generic VM (label disks)           |
| `proton`   | Jellyfin                                                                                              | VM, own hardware config            |
| `lenix`    | Jellyfin, Immich, Paperless                                                                           | bare metal, GRUB/BIOS              |
| `webster`  | microbin, nextcloud, open-webui, suwayomi, trumpet-snipes, vikunja, actual, vaultwarden, static sites | generic VM                         |
| `thinkpad` | laptop desktop                                                                                        | ThinkPad X1 Yoga 7th gen           |
| `bread`    | workstation: desktop, Ollama/ROCm, libvirt, pwn, STM32                                                | Ryzen 7800X3D + RX 7900 XTX, btrfs |

`system.stateVersion` differs per host (25.05 vs 25.11) — it records when each
host was installed and must never be "fixed" to match.

## Deploy

Hosts do **not** deploy from a local checkout. `system.autoUpgrade`
(`modules/core/common.nix`) fetches `github:ArmaanLala/nixos#<hostname>` daily at
03:00 (+45 min jitter), rebuilds, no reboot. So **uncommitted local edits are
invisible to the fleet and get reverted on the next run** — push first.

```bash
sudo nixos-rebuild switch --flake /etc/nixos#<host>   # or: nh os switch
```

`../../scripts/nixup [host...]` restarts the upgrade unit now on the always-on
servers (one tmux pane each, reboots on success).

## Layout

```
flake.nix              inputs + one nixosSystem per host
lib/treefmt.nix        formatter behind `nix fmt`
modules/core/          common.nix (every host), sops.nix
modules/hardware/      nfs, vm-guest, vm-disks
modules/roles/         desktop, dev, gaming, media-server, stm, pwn/
modules/services/      one file per service, import-to-enable
hosts/<name>/          per-host config + hardware-configuration.nix
docs/secrets.md        sops-nix setup + the one hand-placed secret
```

Modules are import-to-enable. Where a module needs parameters it defines real
options instead (`nfs.shares`, `openWebui.ollamaUrl`, `staticSites`).

## Adding a host

1. `hosts/<name>/configuration.nix` importing `../../modules/core/common.nix`,
   plus `networking.hostName` and `system.stateVersion`.
2. Its `hardware-configuration.nix` (or `modules/hardware/vm-*.nix` for a VM).
3. A `nixosSystem` block in `flake.nix` and a matrix entry in
   `.github/workflows/check.yml`.
4. An entry in the `networking.hosts` table in `modules/core/common.nix`.
5. Provision secrets — see `docs/secrets.md`.

## Checks

`nix fmt` formats; `nix flake check` enforces it. CI evaluates every host on each
push to `main` — a `main` that doesn't evaluate breaks the whole fleet at once.
