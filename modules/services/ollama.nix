# Ollama with ROCm acceleration on an AMD GPU.
#
# Single-consumer module (drapion) — the render node below is that machine's
# discrete card. Parameterise it if a second GPU host ever appears.
{ pkgs, lib, ... }:

{
  services.ollama = {
    package = pkgs.ollama-rocm; # package selects the ROCm backend
    enable = true;
    host = "[::]";
  };

  # ollama probes for GPUs once at startup and lives with whatever it found.
  # At boot it used to beat amdgpu to the punch: /dev/kfd was up but the DRM
  # render node ROCm needs to enumerate an HSA agent appeared ~1s later, so
  # discovery came up empty and the server ran on CPU until it was restarted.
  # Ordering after display-manager/graphical.target is not enough — the DM is
  # "started" ~100ms before the render node exists. Wait on the device itself.
  # udev doesn't tag DRM nodes for systemd by default, which is what leaves
  # dev-dri-renderD128.device inactive and useless for ordering; hence the rule.
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
