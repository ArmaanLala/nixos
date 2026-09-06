# Drapion - workstation: Ryzen 7800X3D, RX 7900 XTX, 1.8TB NVMe (btrfs)
{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
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

  # Was `configurationLimit = 3` while the ESP was 127M and shared with Windows
  # -- that is what filled /boot on 2026-09-05 and broke the bootloader install
  # mid-copy. hosts/drapion/disko.nix now declares a 1G ESP, so the override is
  # gone and common.nix's default of 5 applies again.
  #
  # Kept as a note because the failure was non-obvious: the unit of cost is a
  # distinct (kernel, initrd) PAIR, not a distinct kernel version. Generations
  # 234/235/236 were all Linux 6.18.49 yet held two bzImages and two initrds,
  # because the initrd is rebuilt on any initrd-relevant config change and the
  # bzImage on any nixpkgs bump.

  # 2026-09-05: the 25.11 -> 26.05 bump flipped boot.initrd.systemd.enable to
  # true and that doubled the initrd -- the scripted one was 34M unpacked /
  # 14.2M in the ESP, the systemd one is 81M / 27.9M, because it drags in full
  # systemd (18M), openssl (8.6M), btrfs-progs (6.6M), tpm2-tss (3.6M) and lvm2
  # (2.8M). Setting it back to false was what made three generations fit in a
  # 94M ESP.
  #
  # That override is GONE now: disko.nix gives this host a 4G ESP, so 27.9M per
  # generation is noise, and eval warns that the scripted initrd is deprecated
  # and scheduled for removal in 26.11. Taking the default (true) now means not
  # being forced onto it later. Nothing here depended on the scripted path --
  # no LUKS, no TPM unlock, no impermanence, plain btrfs root.

  # 2026-09-05: chasing a Navi31 GPU hang. CS2's VKRenderThread wedges
  # gfx_0.0.0; the driver's first move is a surgical per-ring reset routed
  # through the MES firmware, but MES stops answering:
  #
  #   MES failed to respond to msg=RESET
  #   reset via MES failed and try pipe reset -110   (-110 = ETIMEDOUT)
  #   Ring gfx_0.0.0 reset failed
  #
  # so it escalates to a full device reset, which loses VRAM and kills every
  # GPU context on the box -- including the compositor's. Taking the unified
  # MES path out is an attempt to let the ring reset actually land, so a hung
  # game dies alone instead of taking the desktop with it. This does NOT stop
  # the hang itself. Logs in ~/gpu-debug/. Drop this line if it doesn't help.
  boot.kernelParams = [ "amdgpu.uni_mes=0" ];

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
