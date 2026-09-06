# pwnvm - manage the Ubuntu 24.04 pwn VM.
#
# The VM exists because NixOS is a hostile host for challenge binaries: no
# /lib64 loader, no way to apt-install a matching libc6-dbg, and a kernel we do
# not control. It shares $HOME/pwn with the host over virtiofs at the *same
# absolute path* in the guest, so cwd and argv[0] lengths match and local stack
# offsets stay stable between an exploit run here and one over ssh.

VM=pwnbox
SHARE="${PWNVM_SHARE:-$HOME/pwn}"
MEM="${PWNVM_MEM:-4096}"
CPUS="${PWNVM_CPUS:-4}"
DISK_SIZE="${PWNVM_DISK:-20G}"

URI=qemu:///system
IMG_DIR=/var/lib/libvirt/images
DISK="$IMG_DIR/$VM.qcow2"
SEED="$IMG_DIR/$VM-seed.iso"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/pwnvm"
BASE_URL=https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
BASE="$CACHE/${BASE_URL##*/}"
# Staged copy of $BASE that qemu can actually reach: under qemu:///system the
# disk is opened as the `qemu` user, which cannot traverse into $HOME.
BACKING="$IMG_DIR/${BASE##*/}"
CLOUD_INIT=@CLOUD_INIT@

# Throwaway VM on a NAT network; a churning host key is expected here.
#
# ControlPath=none opts out of the ControlMaster/ControlPersist 5m set in
# programs.ssh.extraConfig: a rebuilt VM reuses the same DHCP address, so a
# surviving master would silently serve sessions from the previous machine.
# (This is what makes `chsh` in the guest look like it did not take.)
SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR -o ControlPath=none)

die() {
  echo "pwnvm: $*" >&2
  exit 1
}
info() { echo "==> $*"; }

exists() { virsh -c "$URI" dominfo "$VM" >/dev/null 2>&1; }
running() { [ "$(virsh -c "$URI" domstate "$VM" 2>/dev/null)" = "running" ]; }

# Lease only: --source agent needs qemu-guest-agent running in the guest, which
# the cloud image ships but leaves inactive, so that query always fails and just
# costs a wasted libvirt round trip per poll.
vm_ip() {
  virsh -c "$URI" -q domifaddr "$VM" --source lease 2>/dev/null |
    awk '$4 ~ /\./ {sub("/.*", "", $4); print $4; exit}'
}

wait_for_ip() {
  local ip i
  for ((i = ${1:-60}; i > 0; i--)); do
    ip=$(vm_ip)
    [ -n "$ip" ] && {
      echo "$ip"
      return 0
    }
    sleep 2
  done
  return 1
}

# Start if needed and hand back the address. Memoised: without it cmd_start
# polls for the lease, then the caller polls again from zero, so a VM that never
# gets one burns the timeout twice over.
VM_IP=""
ensure_ip() {
  [ -n "$VM_IP" ] && {
    echo "$VM_IP"
    return 0
  }
  running || cmd_start
  VM_IP=$(wait_for_ip 60) || die "could not determine IP"
  echo "$VM_IP"
}

cmd_create() {
  exists && die "$VM already exists; use 'pwnvm rebuild' to start over"
  [ -r "$HOME/.ssh/id_ed25519.pub" ] || die "no ~/.ssh/id_ed25519.pub to authorize"

  mkdir -p "$SHARE" "$CACHE"

  if [ ! -f "$BASE" ]; then
    info "fetching Ubuntu 24.04 cloud image"
    curl -fL -C - --progress-bar -o "$BASE.part" "$BASE_URL"
    mv "$BASE.part" "$BASE"
  fi

  info "building cloud-init seed"
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  sed "s|@SSH_PUBKEY@|$(cat "$HOME/.ssh/id_ed25519.pub")|" "$CLOUD_INIT" >"$tmp/user-data"
  printf 'instance-id: %s\nlocal-hostname: %s\n' "$VM-$(date +%s)" "$VM" >"$tmp/meta-data"
  cloud-localds "$tmp/seed.iso" "$tmp/user-data" "$tmp/meta-data"

  info "provisioning disk ($DISK_SIZE)"
  # Stage the immutable base once, then give each VM a thin qcow2 overlay on it.
  # Copying the full ~600MB image per create (and per rebuild) bought nothing.
  [ -f "$BACKING" ] || sudo install -m 0644 "$BASE" "$BACKING"
  sudo qemu-img create -q -f qcow2 -F qcow2 -b "$BACKING" "$DISK" "$DISK_SIZE"
  sudo install -m 0644 "$tmp/seed.iso" "$SEED"

  info "defining domain (sharing $SHARE)"
  # memfd + access.mode=shared is what makes virtiofs possible at all.
  sudo virt-install \
    --connect "$URI" \
    --name "$VM" \
    --memory "$MEM" \
    --vcpus "$CPUS" \
    --cpu host-passthrough \
    --osinfo require=off,name=ubuntu24.04 \
    --disk "path=$DISK,format=qcow2,bus=virtio" \
    --disk "path=$SEED,device=cdrom" \
    --network network=default,model=virtio \
    --memorybacking source.type=memfd,access.mode=shared \
    --filesystem "driver.type=virtiofs,source.dir=$SHARE,target.dir=pwnshare" \
    --graphics none \
    --console pty,target_type=serial \
    --import \
    --noautoconsole

  info "waiting for boot"
  local ip
  ip=$(wait_for_ip 90) || die "no DHCP lease; try 'pwnvm console'"
  sync_terminfo "$ip"
  cat <<EOF

  $VM is up at $ip

  cloud-init is still installing the toolchain (pwntools, pwndbg, one_gadget,
  seccomp-tools, glibc-all-in-one, fish and friends). Watch it finish with:

      pwnvm ssh -- cloud-init status --wait

  Then reboot once to pick up vsyscall=emulate:

      pwnvm ssh -- sudo reboot

  $SHARE on the host is $SHARE in the guest.
EOF
}

cmd_start() {
  # domstate fails outright for an undefined domain, so it answers both
  # "does it exist" and "is it running" in one call.
  case "$(virsh -c "$URI" domstate "$VM" 2>/dev/null)" in
  running)
    info "already running"
    return
    ;;
  "") die "no such VM; run 'pwnvm create'" ;;
  esac
  virsh -c "$URI" start "$VM" >/dev/null
  VM_IP=$(wait_for_ip 60) || true
  info "started; ip ${VM_IP:-(pending)}"
}

cmd_stop() {
  running || {
    info "not running"
    return
  }
  virsh -c "$URI" shutdown "$VM" >/dev/null
  info "shutdown signalled"
}

cmd_ssh() {
  local ip
  ip=$(ensure_ip) || exit 1
  exec ssh "${SSH_OPTS[@]}" "armaan@$ip" "$@"
}

# Ghostty's terminfo is not in Ubuntu's database, so without this TERM is
# unknown in the guest and you get no colors and a broken keypad.
sync_terminfo() {
  local ip="$1" t="${TERM:-xterm-256color}"
  if infocmp -x "$t" 2>/dev/null | ssh_to "$ip" "tic -x - 2>/dev/null"; then
    info "installed terminfo for $t"
  else
    info "could not sync terminfo for $t (harmless; TERM falls back)"
  fi
}

ssh_to() {
  local ip="$1"
  shift
  # SC2029: remote-side expansion is what we want here - callers pass literal
  # commands to run in the guest, not host-local paths.
  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "armaan@$ip" "$@"
}

cmd_sync() {
  # -A forwards the agent so the private nvim submodule can be fetched over SSH.
  # Needs a key loaded on the host: ssh-add ~/.ssh/id_ed25519
  local agent=() remote_env=""
  if [ "${1:-}" = "-A" ]; then agent=(-A) remote_env="PWN_DOTFILES_SSH=1 "; fi
  local ip
  ip=$(ensure_ip) || exit 1
  # One connection for both: `tic` reads stdin to EOF and exits, so the dotfiles
  # run can follow it rather than paying a second handshake (ControlPath=none
  # means there is no multiplexing to fall back on).
  # shellcheck disable=SC2029
  infocmp -x "${TERM:-xterm-256color}" 2>/dev/null |
    ssh "${agent[@]}" "${SSH_OPTS[@]}" "armaan@$ip" \
      "tic -x - 2>/dev/null; ${remote_env}/usr/local/bin/pwn-dotfiles"
}

cmd_ip() { vm_ip; }
cmd_console() { exec virsh -c "$URI" console "$VM"; }

cmd_status() {
  local state
  state=$(virsh -c "$URI" domstate "$VM" 2>/dev/null) ||
    {
      echo "not created"
      return
    }
  printf 'state   %s\n' "$state"
  printf 'ip      %s\n' "$(vm_ip)"
  printf 'share   %s (same path in guest)\n' "$SHARE"
}

cmd_destroy() {
  exists || die "no such VM"
  read -rp "destroy $VM and its disk? ($SHARE is untouched) [y/N] " a
  [ "$a" = y ] || {
    echo "aborted"
    return
  }
  running && virsh -c "$URI" destroy "$VM" >/dev/null
  # No --nvram/--remove-all-storage: the domain is BIOS-booted so there is no
  # NVRAM, and the rm below already covers the disk. $BACKING is shared with
  # future creates and must survive.
  virsh -c "$URI" undefine "$VM" >/dev/null
  sudo rm -f "$DISK" "$SEED"
  info "destroyed"
}

cmd_rebuild() {
  cmd_destroy
  cmd_create
}

usage() {
  cat <<EOF
usage: pwnvm <command>

  create     download the image and define the VM (first run)
  start      boot it
  stop       graceful shutdown
  ssh [cmd]  ssh in as armaan (starts it if needed)
  sync [-A]  re-clone/stow dotfiles and reinstall \$TERM's terminfo.
             -A forwards your ssh agent so private submodules (nvim) resolve.
  console    serial console, for when networking is broken
  ip         print the guest IP
  status     state, IP, share
  destroy    remove the VM and its disk ($SHARE is never touched)
  rebuild    destroy then create

env: PWNVM_SHARE (default \$HOME/pwn) PWNVM_MEM PWNVM_CPUS PWNVM_DISK
EOF
}

case "${1:-}" in
create | start | stop | ssh | sync | console | ip | status | destroy | rebuild)
  cmd=$1
  shift
  # `pwnvm ssh -- <cmd>` reads better than `pwnvm ssh <cmd>`; accept both.
  if [ "$cmd" = ssh ] && [ "${1:-}" = -- ]; then shift; fi
  "cmd_$cmd" "$@"
  ;;
"" | -h | --help | help) usage ;;
*)
  usage
  exit 1
  ;;
esac
