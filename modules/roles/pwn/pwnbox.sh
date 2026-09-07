VM=pwnbox
SHARE="${PWNBOX_SHARE:-$HOME/pwn}"
MEM="${PWNBOX_MEM:-4096}"
CPUS="${PWNBOX_CPUS:-4}"
DISK_SIZE="${PWNBOX_DISK:-20G}"

URI=qemu:///system
IMG_DIR=/var/lib/libvirt/images
DISK="$IMG_DIR/$VM.qcow2"
SEED="$IMG_DIR/$VM-seed.iso"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/pwnbox"
BASE_URL=https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img
BASE="$CACHE/${BASE_URL##*/}"
BACKING="$IMG_DIR/${BASE##*/}"
CLOUD_INIT=@CLOUD_INIT@

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
	-o LogLevel=ERROR -o ControlPath=none)

die() {
	echo "pwnbox: $*" >&2
	exit 1
}
info() { echo "==> $*"; }

exists() { virsh -c "$URI" dominfo "$VM" >/dev/null 2>&1; }
running() { [ "$(virsh -c "$URI" domstate "$VM" 2>/dev/null)" = "running" ]; }

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

wait_for_ssh() {
	local i
	for ((i = 45; i > 0; i--)); do
		ssh "${SSH_OPTS[@]}" -o ConnectTimeout=2 -o BatchMode=yes "armaan@$1" true 2>/dev/null &&
			return 0
		sleep 2
	done
	return 1
}

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
	exists && die "$VM already exists; use 'pwnbox rebuild' to start over"
	[ -r "$HOME/.ssh/id_ed25519.pub" ] || die "no ~/.ssh/id_ed25519.pub to authorize"

	mkdir -p "$SHARE" "$CACHE"

	if [ ! -f "$BASE" ]; then
		info "fetching Ubuntu 26.04 cloud image"
		curl -fL -C - --progress-bar -o "$BASE.part" "$BASE_URL"
		mv "$BASE.part" "$BASE"
	fi

	info "building cloud-init seed"
	local tmp
	tmp=$(mktemp -d)
	trap 'rm -rf "${tmp:-}"' EXIT
	sed "s|@SSH_PUBKEY@|$(cat "$HOME/.ssh/id_ed25519.pub")|" "$CLOUD_INIT" >"$tmp/user-data"
	printf 'instance-id: %s\nlocal-hostname: %s\n' "$VM-$(date +%s)" "$VM" >"$tmp/meta-data"
	cloud-localds "$tmp/seed.iso" "$tmp/user-data" "$tmp/meta-data"

	info "provisioning disk ($DISK_SIZE)"
	[ -f "$BACKING" ] || sudo install -m 0644 "$BASE" "$BACKING"
	sudo qemu-img create -q -f qcow2 -F qcow2 -b "$BACKING" "$DISK" "$DISK_SIZE"
	sudo install -m 0644 "$tmp/seed.iso" "$SEED"

	info "defining domain (sharing $SHARE)"
	sudo virt-install \
		--connect "$URI" \
		--name "$VM" \
		--memory "$MEM" \
		--vcpus "$CPUS" \
		--cpu host-passthrough \
		--osinfo detect=on,require=off \
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
	ip=$(wait_for_ip 90) || die "no DHCP lease; try 'pwnbox console'"
	sync_terminfo "$ip"
	cat <<EOF

  $VM is up at $ip

  The toolchain is still installing. Watch it finish with:

      pwnbox ssh -- cloud-init status --wait

  then reboot once for vsyscall=emulate:

      pwnbox ssh -- sudo reboot
EOF
}

cmd_start() {
	case "$(virsh -c "$URI" domstate "$VM" 2>/dev/null)" in
	running)
		info "already running"
		return
		;;
	"") die "no such VM; run 'pwnbox create'" ;;
	esac
	virsh -c "$URI" start "$VM" >/dev/null
	VM_IP=$(wait_for_ip 60) || true
	info "started; ip ${VM_IP:-(pending)}"
	[ -n "${VM_IP:-}" ] && sync_terminfo "$VM_IP"
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

sync_terminfo() {
	local ip="$1" t="${TERM:-xterm-256color}"
	wait_for_ssh "$ip" || {
		info "guest ssh not up; skipping terminfo sync"
		return
	}
	if infocmp -x "$t" 2>/dev/null | ssh_to "$ip" "sudo tic -x - 2>/dev/null"; then
		info "installed terminfo for $t"
	else
		info "terminfo sync for $t skipped (TERM falls back)"
	fi
}

ssh_to() {
	local ip="$1"
	shift
	exec ssh "${SSH_OPTS[@]}" "armaan@$ip" "$@"
}

cmd_sync() {
	local ip agent=() renv=()
	ip=$(ensure_ip) || exit 1
	[ "${1:-}" = "-A" ] && {
		agent=(-A)
		renv=(env PWN_DOTFILES_SSH=1)
	}
	ssh "${agent[@]}" "${SSH_OPTS[@]}" "armaan@$ip" "${renv[@]}" /usr/local/bin/pwn-dotfiles
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
	printf 'share   %s\n' "$SHARE"
}

cmd_destroy() {
	exists || die "no such VM"
	read -rp "destroy $VM and its disk? ($SHARE is untouched) [y/N] " a
	[ "$a" = y ] || {
		echo "aborted"
		return
	}
	running && virsh -c "$URI" destroy "$VM" >/dev/null
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
usage: pwnbox <command>

  create     download the image and define the VM (first run)
  start      boot it
  stop       graceful shutdown
  ssh [cmd]  ssh in as armaan (starts it if needed)
  sync [-A]  re-clone and stow the dotfiles; -A for the private nvim submodule
  console    serial console, for when networking is broken
  ip         print the guest IP
  status     state, IP, share
  destroy    remove the VM and its disk ($SHARE is never touched)
  rebuild    destroy then create

env: PWNBOX_SHARE (default \$HOME/pwn) PWNBOX_MEM PWNBOX_CPUS PWNBOX_DISK
EOF
}

case "${1:-}" in
create | start | stop | ssh | sync | console | ip | status | destroy | rebuild)
	cmd=$1
	shift
	if [ "$cmd" = ssh ] && [ "${1:-}" = -- ]; then shift; fi
	"cmd_$cmd" "$@"
	;;
"" | -h | --help | help) usage ;;
*)
	usage
	exit 1
	;;
esac
