{ pkgs, lib, ... }:

let
  pwnbox = pkgs.writeShellApplication {
    name = "pwnbox";
    runtimeInputs = with pkgs; [
      curl
      cloud-utils
      qemu-utils
      libvirt
      virt-manager
      openssh
      ncurses
    ];
    text = builtins.replaceStrings [ "@CLOUD_INIT@" ] [ "${./cloud-init.yaml}" ] (
      builtins.readFile ./pwnbox.sh
    );
  };
in
{
  imports = [
    ../../services/libvirt.nix
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

  virtualisation.libvirtd.qemu.vhostUserPackages = [ pkgs.virtiofsd ];

  systemd.tmpfiles.rules = [ "d /home/armaan/pwn 0755 armaan users -" ];

  users.users.armaan.packages = with pkgs; [
    pwnbox

    pwninit
    patchelf
    one_gadget
    checksec
    rubyPackages.seccomp-tools

    rizin
    binwalk
    termshark
    ffuf

    (lib.hiPrio (
      python3.withPackages (
        ps: with ps; [
          pwntools
          ropgadget
          ropper
          capstone
          unicorn
        ]
      )
    ))
  ];
}
