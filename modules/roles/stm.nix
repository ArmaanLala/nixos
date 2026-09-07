{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gcc-arm-embedded

    openocd
    stlink-gui
    probe-rs-tools
    dfu-util

    tio

    bear
  ];

  users.users.armaan.packages = with pkgs; [
    stm32cubemx
    cutecom

    cargo-binutils
    cargo-generate
    flip-link
    svd2rust
  ];

  services.udev.packages = with pkgs; [
    openocd
    stlink-gui
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0660", TAG+="uaccess"
  '';

  users.users.armaan.extraGroups = [ "dialout" ];
}
