# Binary exploitation - CTF pwn tooling. Two layers: nix-ld + pwninit on the
# host for quick triage, and `pwnbox` (see ./pwnbox.sh) - a throwaway Ubuntu VM
# with its own kernel for apt-get, kernel pwn and vsyscall=emulate.
{ pkgs, lib, ... }:

let
  pwnbox = pkgs.writeShellApplication {
    name = "pwnbox";
    runtimeInputs = with pkgs; [
      curl
      cloud-utils
      qemu-utils
      libvirt
      virt-manager # virt-install
      openssh
      ncurses # infocmp, for the terminfo sync
    ];
    text = builtins.replaceStrings [ "@CLOUD_INIT@" ] [ "${./cloud-init.yaml}" ] (
      builtins.readFile ./pwnbox.sh
    );
  };
in
{
  imports = [
    ../../services/libvirt.nix # pwnbox drives qemu:///system
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

  # virtiofsd, for the VM's --filesystem share
  virtualisation.libvirtd.qemu.vhostUserPackages = [ pkgs.virtiofsd ];

  systemd.tmpfiles.rules = [ "d /home/armaan/pwn 0755 armaan users -" ];

  users.users.armaan.packages = with pkgs; [
    pwnbox

    pwninit # patch a binary onto the provided libc/ld, fetch symbols
    patchelf # the manual version of the above
    one_gadget # execve("/bin/sh") one-shot offsets
    checksec # RELRO / canary / NX / PIE
    rubyPackages.seccomp-tools # dump seccomp filters

    rizin # radare2 successor, faster triage than opening Ghidra
    binwalk # firmware/blob extraction
    termshark # TUI wireshark, reads the same captures as tcpdump
    ffuf # web content/parameter fuzzer

    # hiPrio to win the collision with dev.nix's bare python3, so `import pwn` works.
    (lib.hiPrio (
      python3.withPackages (
        ps: with ps; [
          pwntools
          ropgadget
          ropper
          capstone
          unicorn
          # angr # broken in nixpkgs 26.05 (missing setuptools-rust build dep)
        ]
      )
    ))
  ];
}
