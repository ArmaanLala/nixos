{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.git = {
    enable = true;

    userName = "ArmaanLala";
    userEmail = "armaan@armaanlala.tech";  # Update this to your actual email

    extraConfig = {
      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = true;
      };

      push = {
        autoSetupRemote = true;
      };

      # macOS-specific credential helper
      credential = lib.mkIf isDarwin {
        helper = "osxkeychain";
      };

      # Linux-specific credential helper (libsecret)
      credential = lib.mkIf (!isDarwin) {
        helper = "libsecret";
      };
    };

    # Global gitignore (can reference your existing one)
    ignores = [
      # OS-specific
      ".DS_Store"
      "Thumbs.db"

      # Editors
      "*~"
      "*.swp"
      "*.swo"
      ".vscode/"
      ".idea/"

      # Build artifacts
      "*.o"
      "*.pyc"
      "__pycache__/"
      "node_modules/"
      "target/"

      # Temporary files
      "*.log"
      ".tmp"
    ];
  };
}
