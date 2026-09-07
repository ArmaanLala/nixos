# bread - workstation: Ryzen 7800X3D, RX 7900 XTX, 2TB NVMe (btrfs).
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

  networking.hostName = "bread";
  services.udisks2.enable = true;

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
