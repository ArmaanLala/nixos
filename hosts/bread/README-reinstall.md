# Reinstalling bread

Disk layout is in `disko.nix`: a 2TB Samsung 980 PRO with a 4G ESP + btrfs root.
disko wipes **only** that disk (addressed by-id). The second NVMe — a Crucial P3
with Windows — is absent from `disko.nix` and left untouched.

**The catch:** Windows boots from `/EFI/Microsoft` on the _Samsung's_ ESP, so
reformatting it breaks Windows boot even though the Windows partition survives.
Step 4 restores it.

## 0. Pre-flight

Backups on `truenas:/mnt/wdblue/nightbeef/drapion/` (named for the machine that
made them): `drapion.tar.zst` (`/home/armaan`), `drapion-system.tar.zst` (`/etc`,
`/var/lib/{NetworkManager,sbctl,tailscale}`, `/boot/EFI/Microsoft`),
`drapion-nixos-state.tar.zst` (`/var/lib/nixos` uid maps).

```bash
for f in /mnt/nightbeef/drapion/*.tar.zst; do zstd -t "$f" || echo "BAD: $f"; done
cd ~/dotfiles/.config/nixos && git push        # step 1 pulls the flake from GitHub
```

## 1. Partition + install

Boot a recent NixOS minimal ISO, get networking up. Confirm the target disk is
present: `ls /dev/disk/by-id/ | grep Samsung_SSD_980_PRO` — if
`nvme-Samsung_SSD_980_PRO_2TB_S6B0NU0W945573Z` is absent the disk was replaced
and `disko.nix` needs the new id first.

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode destroy,format,mount --flake 'github:ArmaanLala/nixos#bread'
sudo nixos-install --flake 'github:ArmaanLala/nixos#bread' --no-root-password
```

## 2. Restore

`--numeric-owner` + the pinned `uid = 1000` in `common.nix` keep ownership sane.

```bash
mkdir -p /tmp/nas && sudo mount -t nfs truenas:/mnt/wdblue/nightbeef /tmp/nas
D=/tmp/nas/drapion

sudo rm -rf /mnt/home/armaan
zstd -dc $D/drapion.tar.zst           | sudo tar -C /mnt/home    --numeric-owner --acls --xattrs -xf -
zstd -dc $D/drapion-nixos-state.tar.zst | sudo tar -C /mnt/var/lib --numeric-owner -xf -

# system state -- selectively; do NOT unpack /etc wholesale
mkdir -p /tmp/sys && zstd -dc $D/drapion-system.tar.zst | sudo tar -C /tmp/sys -xf -
sudo cp -a /tmp/sys/etc/ssh/ssh_host_*     /mnt/etc/ssh/      # host identity + sops age key
sudo cp -a /tmp/sys/var/lib/NetworkManager /mnt/var/lib/      # wifi creds
sudo cp -a /tmp/sys/var/lib/sbctl          /mnt/var/lib/      # secure boot keys
```

## 3. Windows bootloader

```bash
sudo cp -a /tmp/sys/EFI/Microsoft /mnt/boot/EFI/
sudo /mnt/nix/var/nix/profiles/system/bin/switch-to-configuration boot
```

Reboot; confirm both entries show in the systemd-boot menu.

## 4. After first boot

- `tailscale up`, remove the old node, set `"100.99.14.97" = [ "ts-bread" ]` in
  `common.nix` to the IP it gets.
- Fix `known_hosts` on other machines — the restored host keys are filed under
  the old name.
- `ollama pull` models; reinstall Steam; rebuild libvirt VMs from `libvirt.nix`.
