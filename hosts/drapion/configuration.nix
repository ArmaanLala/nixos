# Drapion - workstation: Ryzen 7800X3D, RX 7900 XTX, 1.8TB NVMe (btrfs)
{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/common.nix
    ../../modules/hardware/nfs.nix
    ../../modules/roles/desktop.nix
    ../../modules/roles/dev.nix
    ../../modules/roles/gaming.nix
    ../../modules/roles/pwn
    ../../modules/roles/stm.nix
    ../../modules/services/libvirt.nix
    ../../modules/services/ollama.nix
  ];

  nfs.shares = {
    buzz = "phub";
    games = "games";
    immich = "immich";
    media = "arr";
    manga = "manga";
    nightbeef = "nightbeef";
  };

  networking.hostName = "drapion";
  services.udisks2.enable = true;

  # Never suspend on its own: S3 powers the NIC down and takes SSH and tailscale
  # with it, and this box is the one we ssh *into* -- recovering it means
  # walking over or firing a magic packet from another host. Displays still
  # blank and the session still locks on hypridle's timers. Suspending by hand
  # is still fine; that one is a decision, not a surprise.
  # See modules/roles/idle.nix.
  desktop.autoSuspend = false;

  # Still arm the RTL8125's magic-packet filter. Nothing suspends the box any
  # more, but a deliberate poweroff (or a crash) still needs a `wol`/`etherwake`
  # from truenas or lenix to bring it back before we ssh in.
  networking.interfaces.enp14s0.wakeOnLan.enable = true;

  # NetworkManager reapplies link settings on every (re)connect and would clear
  # the flag the wakeOnLan unit sets at boot. 64 = NM_SETTING_WIRED_WAKE_ON_LAN_MAGIC.
  networking.networkmanager.settings.connection."ethernet.wake-on-lan" = 64;

  # ROCm bits live in modules/services/ollama.nix
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.amdgpu.opencl.enable = true;

  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  environment.systemPackages = with pkgs; [
    calibre
    gimp3
    sbctl
    discord
    claude-code
    ethtool
    grimblast
    quickemu
    godot
    arduino-ide
    freecad
    koboldcpp
    hashcat
  ];

  services.gnome.gnome-keyring.enable = false;

  services.openssh.settings.PasswordAuthentication = lib.mkForce true;

  # Keyboard firmware flashing needs these udev rules
  services.udev.packages = with pkgs; [
    qmk
    qmk-udev-rules
    qmk_hid
    via
    vial
  ];

  system.stateVersion = "25.11";
}
