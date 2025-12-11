{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.git = {
    enable = true;

    # Use new settings format
    settings = {
      user = {
        name = "ArmaanLala";
        email = "armaan@armaanlala.tech";  # Update this to your actual email
      };

      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = true;
      };

      push = {
        autoSetupRemote = true;
      };

      # Platform-specific credential helper
      credential.helper = if isDarwin then "osxkeychain" else "libsecret";
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
