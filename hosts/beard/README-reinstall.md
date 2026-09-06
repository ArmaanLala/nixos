# Installing beard (formerly drapion)

The machine is being renamed as part of this rebuild: it was `drapion`, it comes
back as `beard`. `hosts/drapion/` is a frozen copy of the old config, kept for
reference; the NAS backup directory is still named `drapion/` because that is
the machine that produced it.

**The flake attribute must equal `networking.hostName`.** `common.nix` sets
`system.autoUpgrade.flake = "github:ArmaanLala/nixos#${config.networking.hostName}"`,
so if the two ever drift the weekly 03:00 Saturday upgrade fails silently.

Written 2026-09-05, when the 1.8T disk hit 94% and the 127M ESP had already
broken a bootloader install mid-copy. The layout lives in `hosts/beard/disko.nix`.

## What this does and does not touch

| Device                        | Contents           | Fate                                    |
| ----------------------------- | ------------------ | --------------------------------------- |
| `nvme0n1` Samsung 980 PRO 2TB | ESP + btrfs root   | **ERASED** and rebuilt by disko         |
| `nvme1n1` Crucial P3 500G     | Windows + recovery | **untouched** — absent from `disko.nix` |

The catch: Windows boots from `/EFI/Microsoft` on **nvme0n1's ESP**, not from its
own disk. Reformatting nvme0n1 therefore breaks Windows even though the Windows
install itself survives. Restoring that directory (step 6) fixes it.

## 0. Pre-flight — do not skip

Backups live on `truenas:/mnt/wdblue/nightbeef` under `drapion/`:

| File                          | Contents                                                                   |
| ----------------------------- | -------------------------------------------------------------------------- |
| `drapion.tar.zst`             | all of `/home/armaan` (27G compressed)                                     |
| `drapion-system.tar.zst`      | `/etc`, `/var/lib/{NetworkManager,sbctl,tailscale}`, `/boot/EFI/Microsoft` |
| `drapion-nixos-state.tar.zst` | `/var/lib/nixos` — the uid/gid maps                                        |
| `beef_backup.tar.zst`         | pre-existing archive, copied verbatim                                      |

Verify before erasing anything. `zstd -t` checks the embedded xxhash:

```bash
for f in /mnt/nightbeef/drapion/*.tar.zst; do zstd -t "$f" || echo "BAD: $f"; done
```

Also confirm the ESP copy at `/mnt/media/DRAPION_EFI` is intact — this is the
Windows rescue path and it is easier to check now than to regret later:

```bash
test -s /mnt/media/DRAPION_EFI/EFI/Microsoft/Boot/bootmgfw.efi && echo OK
```

Push any config changes, since step 3 fetches the flake from GitHub:

```bash
cd ~/dotfiles/.config/nixos && git push
```

## 1. Boot the installer

Any recent NixOS minimal ISO -- 25.05, 25.11 and 26.05 all work. The ISO is only
a live environment: `nixos-install --flake` builds the target system from this
flake (pinned to nixpkgs 26.05), and `nix run github:nix-community/disko` fetches
its own tooling, so neither the installed version nor `mkfs` comes from the
stick. Prefer the newest ISO you have, since less has to be downloaded. Get networking up (`nmtui` for wifi; ethernet is
usually automatic) and confirm `ping github.com` works.

## 2. Confirm the disk is the one you think it is

Disko addresses the disk by `by-id`, but check anyway — this is the last moment
where a mistake is cheap:

```bash
ls -l /dev/disk/by-id/ | grep -E 'Samsung_SSD_980_PRO|CT500P3PSSD8'
```

`nvme-Samsung_SSD_980_PRO_2TB_S6B0NU0W945573Z` is the target. If that string
does not appear, **stop** — the disk was replaced and `disko.nix` needs updating
before anything is erased.

## 3. Partition, format, mount

This erases nvme0n1.

```bash
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko -- \
  --mode destroy,format,mount \
  --flake 'github:ArmaanLala/nixos#beard'
```

Check it landed: `mount | grep /mnt` should show `/mnt`, `/mnt/home`, `/mnt/nix`,
`/mnt/boot` and `/mnt/.swapvol`.

## 4. Install

```bash
sudo nixos-install --flake 'github:ArmaanLala/nixos#beard' --no-root-password
```

## 5. Restore data

Ownership comes from `--numeric-owner`, and `uid = 1000` is pinned in
`modules/core/common.nix`, so uids line up without further work.

```bash
mkdir -p /tmp/nas && sudo mount -t nfs truenas:/mnt/wdblue/nightbeef /tmp/nas

# home
sudo rm -rf /mnt/home/armaan
zstd -dc /tmp/nas/drapion/drapion.tar.zst \
  | sudo tar -C /mnt/home --numeric-owner --acls --xattrs -xf -

# uid/gid maps, so nixos does not reallocate service uids
zstd -dc /tmp/nas/drapion/drapion-nixos-state.tar.zst \
  | sudo tar -C /mnt/var/lib --numeric-owner -xf -
```

From `drapion-system.tar.zst`, restore **selectively** — do not unpack `/etc`
wholesale over a fresh NixOS install, most of it is generated from the flake:

```bash
mkdir -p /tmp/sys && zstd -dc /tmp/nas/drapion/drapion-system.tar.zst \
  | sudo tar -C /tmp/sys -xf -
sudo cp -a /tmp/sys/etc/ssh/ssh_host_* /mnt/etc/ssh/          # host identity
sudo cp -a /tmp/sys/var/lib/NetworkManager /mnt/var/lib/      # wifi creds
sudo cp -a /tmp/sys/var/lib/sbctl /mnt/var/lib/               # secure boot keys
```

## 6. Restore the Windows bootloader

Without this Windows is unbootable. systemd-boot auto-detects `bootmgfw.efi` and
adds the menu entry itself; the BCD points at nvme1n1, which was never touched.

```bash
sudo cp -a /tmp/sys/EFI/Microsoft /mnt/boot/EFI/
sudo /mnt/nix/var/nix/profiles/system/bin/switch-to-configuration boot
```

Then reboot and confirm **both** entries appear in the systemd-boot menu.

## 7. After first boot

Rename fallout first — these are the things that break precisely because the
host came back under a new name:

- **Rebuild `webster`.** Its `openWebui.ollamaUrl` now says `http://beard:11434`;
  open-webui cannot reach Ollama until webster has picked that up.
- **`tailscale up`**, then remove the stale `drapion` node in the tailnet admin.
  The new node gets a new tailnet IP, so update `"100.99.14.97" = [ "ts-beard" ... ]`
  in `modules/core/common.nix` to whatever it actually receives — that entry is
  wrong until you do.
- **Update `known_hosts` on your other machines.** The restored ssh host keys are
  valid, but they are filed under `drapion`, so the first connection to `beard`
  prompts to trust a "new" host.
- **Confirm the weekly upgrade resolves.** `networking.hostName` is `beard` and
  the flake attribute is `beard`; if they ever drift, `system.autoUpgrade` fails
  silently every Saturday:
  ```bash
  nix eval "github:ArmaanLala/nixos#nixosConfigurations.$(hostname).config.system.build.toplevel.drvPath"
  ```
- Once beard is trustworthy, delete `hosts/drapion/`, its `flake.nix` block and
  its `.github/workflows/check.yml` entry.

Then the ordinary post-install bits:

- `tailscale up` — tailscale state was backed up but re-authing is simpler.
- Steam: reinstall and re-download. Local saves not synced to Steam Cloud were
  lost when `steamapps/` was deleted on 2026-09-05; nothing to restore.
- `ollama pull` the models you want; the 63G in `/var/lib/private/ollama` was
  deliberately not backed up.
- The libvirt VMs (`linux2024.qcow2`, `pwnbox.qcow2`) were deleted before the
  backup ran and do not exist anywhere. Rebuild from `modules/services/libvirt.nix`.

## Why the ESP is 4G

The original was 127M, shared with Windows, leaving ~94M. A single 6.18.49
kernel+initrd pair is ~41M, so three generations did not fit and
`nixos-rebuild` failed with `No space left on device` partway through installing
the bootloader. The cost unit is a distinct **(kernel, initrd) pair**, not a
distinct kernel version — generations 234/235/236 were all 6.18.49 yet held two
of each. 4G is ~90 generations and 0.2% of the disk.
