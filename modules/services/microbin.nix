# MicroBin pastebin, built from Armaan's fork (upstream master + a custom colour
# scheme -- Nord syntax highlighting and a forced dark theme). nixpkgs only
# packages the tagged 2.0.4 release with a different dependency tree, so this
# builds the fork itself and hands it to the upstream NixOS module via `package`.
#
# Secret: the admin password comes from sops (secrets/webster.yaml ->
# microbin_admin_password), rendered into an EnvironmentFile via sops.templates.
#
# Public at https://bin.armaanlala.tech via the Cloudflare tunnel -> port 5980
# (the external port the old compose exposed; 8080 is taken by open-webui here).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  microbin = pkgs.rustPlatform.buildRustPackage {
    pname = "microbin";
    # Fork tracks master; there is no meaningful upstream version past 2.0.4.
    version = "0-unstable-2026-09-06";
    src = inputs.microbin-src;

    # The fork regenerated Cargo.lock wholesale, so nixpkgs' cargoHash is no use;
    # vendor straight from the lockfile instead. No git dependencies in it.
    cargoLock.lockFile = inputs.microbin-src + "/Cargo.lock";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [
      pkgs.oniguruma # syntect's "__syntect-fast" feature links system libonig
      pkgs.openssl
    ];
    env = {
      OPENSSL_NO_VENDOR = true;
      RUSTONIG_SYSTEM_LIBONIG = true;
    };

    # No test suite worth running here, and the build box has no network.
    doCheck = false;

    meta = {
      description = "MicroBin pastebin (ArmaanLala fork)";
      homepage = "https://github.com/ArmaanLala/microbin";
      mainProgram = "microbin";
    };
  };
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

    # Ported from old-compose/servarr.yaml. `settings` maps 1:1 to MICROBIN_*
    # env vars; the module already defaults BIND, PORT, telemetry and listing.
    settings = {
      MICROBIN_PORT = "5980";
      MICROBIN_PUBLIC_PATH = "https://bin.armaanlala.tech/";

      MICROBIN_EDITABLE = true;
      MICROBIN_NO_LISTING = true;
      MICROBIN_HIGHLIGHTSYNTAX = true;
      MICROBIN_HASH_IDS = false;

      # Data lands in <dataDir>/microbin_data (matches the old bind mount).
      MICROBIN_DATA_DIR = "microbin_data";
      MICROBIN_JSON_DB = false;
      MICROBIN_GC_DAYS = 90;
      MICROBIN_DEFAULT_EXPIRY = "24hour";
      MICROBIN_DEFAULT_BURN_AFTER = 0;
      MICROBIN_ETERNAL_PASTA = false;

      MICROBIN_ENABLE_BURN_AFTER = true;
      MICROBIN_ENABLE_READONLY = true;
      MICROBIN_READONLY = false;

      MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
      MICROBIN_ENCRYPTION_SERVER_SIDE = true;
      MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB = 256;
      MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 2048;

      MICROBIN_HIDE_HEADER = false;
      MICROBIN_HIDE_FOOTER = false;
      MICROBIN_HIDE_LOGO = false;
      MICROBIN_WIDE = false;
      MICROBIN_QR = true;

      MICROBIN_THREADS = 1;
      MICROBIN_DISABLE_UPDATE_CHECKING = false;
    };
  };

  networking.firewall.allowedTCPPorts = [ 5980 ];
}
