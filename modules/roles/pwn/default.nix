# Binary exploitation - CTF pwn tooling, a shared challenge dir, and a pwn VM.
#
# NixOS is a poor host for challenge binaries: /lib64/ld-linux-x86-64.so.2 is
# only a stub, and there is no way to apt-install a libc6-dbg matching whatever
# glibc a challenge was built against. Three layers, cheapest first:
#
#   1. nix-ld + pwninit on the host - enough to triage a fresh download and to
#      solve anything where patchelf'ing onto the provided libc is sufficient.
#   2. distrobox (`pwnbox`) - a throwaway Ubuntu userland for "just apt-get it".
#   3. the VM (`pwnvm`) - own kernel, so global ASLR, vsyscall=emulate and
#      kernel-pwn work. See ./pwnvm.sh.
#
# All three see ~/pwn. The VM mounts it at the same absolute path so cwd and
# argv[0] lengths match and stack offsets stay comparable across them.
{ pkgs, lib, ... }:

let
  pwnvm = pkgs.writeShellApplication {
    name = "pwnvm";
    runtimeInputs = with pkgs; [
      curl
      cloud-utils
      qemu-utils
      libvirt
      virt-manager # virt-install
      openssh
      ncurses # infocmp, for the terminfo sync
    ];
    text = builtins.replaceStrings [ "@CLOUD_INIT@" ] [ "${./cloud-init.yaml}" ]
      (builtins.readFile ./pwnvm.sh);
  };

  # Throwaway Ubuntu userland. Uses a dedicated home (~/pwn) rather than the
  # host home on purpose: distrobox's default is to share $HOME, which drags
  # your whole shell environment in, and environment size shifts stack
  # addresses. This keeps runs closer to reproducible.
  pwnbox = pkgs.writeShellApplication {
    name = "pwnbox";
    # podman comes from services/podman.nix, configured with this system's
    # containers.conf and dockerCompat links; a bare pkgs.podman here would
    # shadow it on PATH.
    runtimeInputs = with pkgs; [ distrobox ];
    text = ''
      if ! podman container exists pwnbox; then
        echo "==> creating pwnbox (ubuntu:24.04)"
        distrobox create \
          --name pwnbox \
          --image docker.io/library/ubuntu:24.04 \
          --home "$HOME/pwn" \
          --no-entry \
          --additional-packages \
            "build-essential gdb gdbserver patchelf ltrace strace file elfutils \
             python3-dev python3-venv python3-pip ruby ruby-dev libc6-dbg git curl" \
          --yes
      fi
      exec distrobox enter pwnbox -- "$@"
    '';
  };
in
{
  imports = [
    ../../services/podman.nix # distrobox needs a container backend
    ../../services/libvirt.nix # pwnvm drives qemu:///system
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      glibc
      zlib
      openssl
      ncurses
      libxml2
      libseccomp
    ];
  };

  # libvirt spawns virtiofsd out of this list; without it the VM's --filesystem
  # fails to start.
  virtualisation.libvirtd.qemu.vhostUserPackages = [ pkgs.virtiofsd ];

  systemd.tmpfiles.rules = [ "d /home/armaan/pwn 0755 armaan users -" ];

  users.users.armaan.packages = with pkgs; [
    pwnvm
    pwnbox
    distrobox

    pwninit # patch a binary onto the provided libc/ld, fetch symbols
    patchelf # the manual version of the above
    one_gadget # execve("/bin/sh") one-shot offsets
    checksec # RELRO / canary / NX / PIE
    rubyPackages.seccomp-tools # dump seccomp filters

    # dev.nix also puts a bare `python3` in this profile and the collision is
    # resolved by merge order; hiPrio makes this one win, so `import pwn` works
    # on the host.
    (lib.hiPrio (python3.withPackages (ps: with ps; [
      pwntools
      ropgadget
      ropper
      capstone
      unicorn
      angr
    ])))
  ];
}
