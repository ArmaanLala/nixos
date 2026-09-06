# Ollama with ROCm. Beard-only: the render node ordering below is hardcoded to
# that machine's card — parameterise it if a second GPU host appears.
{ pkgs, lib, ... }:

{
  services.ollama = {
    package = pkgs.ollama-rocm;
    enable = true;
    host = "[::]";
  };

  # ollama probes for GPUs once at startup: at boot it used to beat the DRM
  # render node by ~1s, find nothing, and silently run on CPU until restarted.
  # display-manager ordering is ~100ms too early, so wait on the device — and
  # udev doesn't tag DRM nodes for systemd by default, hence this rule.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", TAG+="systemd"
  '';

  systemd.services.ollama = {
    # renderD128 is the discrete 7900 XTX (PCI 03:00.0); the iGPU is renderD129.
    after = [ "dev-dri-renderD128.device" ];
    requires = [ "dev-dri-renderD128.device" ];
    serviceConfig.User = lib.mkForce "armaan";
  };

  # Unauthenticated inference endpoint, deliberately open to the LAN.
  networking.firewall.allowedTCPPorts = [ 11434 ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      rocmPackages.rocm-runtime
      rocmPackages.rocblas
    ];
  };
}
