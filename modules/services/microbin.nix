{
  config,
  pkgs,
  inputs,
  ...
}:
let
  microbin = pkgs.microbin.overrideAttrs (_: {
    version = "2.1.4-unstable-2026-09-06";
    src = inputs.microbin-src;
    cargoDeps = pkgs.rustPlatform.importCargoLock {
      lockFile = inputs.microbin-src + "/Cargo.lock";
    };
    patches = [ ];
    doCheck = false;
  });
in
{
  sops.secrets.microbin_admin_password.sopsFile = ../../secrets/webster.yaml;

  sops.templates."microbin.env".content = ''
    MICROBIN_ADMIN_USERNAME=armaan
    MICROBIN_ADMIN_PASSWORD=${config.sops.placeholder.microbin_admin_password}
  '';

  services.microbin = {
    enable = true;
    package = microbin;
    dataDir = "/var/lib/microbin";
    passwordFile = config.sops.templates."microbin.env".path;

    settings = {
      MICROBIN_PORT = "5980";
      MICROBIN_PUBLIC_PATH = "https://bin.armaanlala.tech/";

      MICROBIN_EDITABLE = true;
      MICROBIN_NO_LISTING = true;
      MICROBIN_HIGHLIGHTSYNTAX = true;
      MICROBIN_QR = true;

      MICROBIN_ENABLE_BURN_AFTER = true;
      MICROBIN_ENABLE_READONLY = true;
      MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
      MICROBIN_ENCRYPTION_SERVER_SIDE = true;

      MICROBIN_THREADS = 2;

      MICROBIN_DISABLE_UPDATE_CHECKING = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 5980 ];
}
