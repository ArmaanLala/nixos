# MicroBin pastebin, built from Armaan's fork (upstream master + a custom colour
# scheme -- Nord syntax highlighting and a forced dark theme). This overrides
# nixpkgs' `microbin` package with the fork's source and hands it to the upstream
# NixOS module via `package`, so all of nixpkgs' build wiring is inherited.
#
# Secret: the admin password comes from sops (secrets/webster.yaml ->
# microbin_admin_password), rendered into an EnvironmentFile via sops.templates.
#
# Public at https://bin.armaanlala.tech via the Cloudflare tunnel -> port 5980
# (the external port the old compose exposed; 8080 is taken by open-webui here).
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
    # The fork regenerated Cargo.lock wholesale, so nixpkgs' cargoHash is no use;
    # vendor straight from the lockfile instead.
    cargoDeps = pkgs.rustPlatform.importCargoLock {
      lockFile = inputs.microbin-src + "/Cargo.lock";
    };
    # nixpkgs' patches target the 2.0.4 tag and don't apply to the fork.
    patches = [ ];
    doCheck = false;
  });
in
{
  sops.secrets.microbin_admin_password.sopsFile = ../../secrets/webster.yaml;

  # microbin reads credentials from an EnvironmentFile; sops.templates renders
  # one with the decrypted password substituted in at activation.
  sops.templates."microbin.env".content = ''
    MICROBIN_ADMIN_USERNAME=armaan
    MICROBIN_ADMIN_PASSWORD=${config.sops.placeholder.microbin_admin_password}
  '';

  services.microbin = {
    enable = true;
    package = microbin;
    dataDir = "/var/lib/microbin";
    passwordFile = config.sops.templates."microbin.env".path;

    # Only the values that differ from stock MicroBin defaults; ported from
    # old-compose/servarr.yaml. The module already defaults BIND/PORT/telemetry.
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

      # One worker deadlocks the whole service if a request stalls.
      MICROBIN_THREADS = 2;

      # The /admin update check calls https://api.microbin.eu/version/ with a
      # no-timeout client (fork's src/util/version.rs). That host is unreachable
      # from webster, so leaving this on hangs the admin page indefinitely.
      MICROBIN_DISABLE_UPDATE_CHECKING = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 5980 ];
}
