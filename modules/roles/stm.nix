# STM32 embedded development - toolchain, flashing, and debugging
# Targets the STM32F411 (Cortex-M4F, thumbv7em-none-eabihf) dev board.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Cross toolchain: arm-none-eabi-{gcc,g++,gdb,objcopy,size,...}
    gcc-arm-embedded

    # Flashing and on-chip debugging
    openocd # SWD debug server, `-f interface/stlink.cfg -f target/stm32f4x.cfg`
    stlink-gui # st-flash/st-info/st-util plus a GUI flasher; conflicts with plain `stlink`
    probe-rs-tools # probe-rs, cargo-flash, cargo-embed, RTT
    dfu-util # F411's ROM bootloader over USB (BOOT0 high, 0483:df11)

    # Serial console for printf-style debugging over the USB-UART bridge
    tio # `tio /dev/ttyUSB0`, reconnects on its own when the board resets

    bear # compile_commands.json out of a CubeMX Makefile, so clangd finds the HAL
  ];

  users.users.armaan.packages = with pkgs; [
    stm32cubemx # clock/pinmux config and HAL project generation
    cutecom # GUI serial terminal, for when scrollback and hex view beat tio

    # Rust embedded workflow (rustup from roles/dev.nix provides the compiler:
    # `rustup target add thumbv7em-none-eabihf`)
    cargo-binutils # cargo size/objdump/nm via llvm-tools
    cargo-generate # `cargo generate cortex-m-quickstart`
    flip-link # moves the stack below .bss/.data so overflow faults instead of corrupting
    svd2rust # peripheral access crate from the ST SVD
  ];

  # ST-Link probes: openocd's rules cover V2/V2-1/V3, stlink's cover the
  # st-flash/st-util side. Both tag uaccess, so no plugdev membership needed.
  services.udev.packages = with pkgs; [
    openocd
    stlink-gui
  ];

  # Neither package ships a rule for the F411 in DFU mode, which is how the board
  # enumerates when it boots from system memory with no probe attached.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0660", TAG+="uaccess"
  '';

  # USB-serial bridges (CH340, CP210x, FTDI) come up as ttyUSB* owned by dialout.
  users.users.armaan.extraGroups = [ "dialout" ];
}
