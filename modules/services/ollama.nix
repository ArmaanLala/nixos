{ pkgs, lib, ... }:

{
  services.ollama = {
    package = pkgs.ollama-rocm;
    enable = true;
    host = "[::]";
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", TAG+="systemd"
  '';

  systemd.services.ollama = {
    after = [ "dev-dri-renderD128.device" ];
    requires = [ "dev-dri-renderD128.device" ];
    serviceConfig.User = lib.mkForce "armaan";
  };

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
