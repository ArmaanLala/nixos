{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.fish = {
    enable = true;

    shellInit = ''
      # XDG Base Directory
      set -gx XDG_CONFIG_HOME "$HOME/.config"
      set -gx XDG_DATA_HOME "$HOME/.local/share"
      set -gx XDG_CACHE_HOME "$HOME/.cache"
      set -gx LESSHISTFILE "$XDG_CACHE_HOME/less_history"
      set -gx PYTHON_HISTORY "$XDG_DATA_HOME/python/history"

      # Editor
      set -gx EDITOR nvim
      set -gx VISUAL nvim

      # Go
      set -gx GOPATH "$HOME/go"

      # Add paths
      fish_add_path "$HOME/scripts"
      fish_add_path "$HOME/.local/bin"
    '' + lib.optionalString isDarwin ''
      # macOS-specific paths
      fish_add_path "$HOME/scripts/apple"
    '';

    interactiveShellInit = ''
      # Only run in interactive sessions
      if status is-interactive
          # Commands to run in interactive sessions can go here
      end
    '';

    shellAliases = {
      # Basic utilities
      c = "clear";
      cat = "bat";
      cd = "z";
      df = "df -h";
      du = "du -h -d 1";
      k = "killall";
      mv = "mv -i";
      rm = "rm -Iv";
      v = "nvim";

      # ls replacements (eza)
      l = "eza --color=auto --icons -h";
      la = "eza --color=auto --icons -lah";
      ll = "eza --color=auto --icons -lh";
      ls = "eza --color=auto --icons -h";

      # Git
      lz = "lazygit";

      # Process management
      p = "ps aux | grep";

      # Custom scripts
      i = "$HOME/scripts/install.sh";
      mb = "$HOME/scripts/microbin.sh";
      jump = "ssh -J jumpbox";

      # NixOS-specific
      nrs = "nh os switch";
      nrb = "nh os boot";
      nrt = "nh os test";
      nfu = "nix flake update";
      nfc = "nix flake check";
      ncg = "nh clean all --keep 3";
    } // lib.optionalAttrs (!isDarwin) {
      # Linux-specific aliases
      pman = "sudo pacman -S";
      yay = "paru";
    };

    functions = {
      # Custom fish functions
      collapse = ''
        find . -mindepth 2 -type f -exec mv -i {} . \;
      '';

      rmempty = ''
        find . -type d -empty -delete
      '';

      fish_greeting = ''
        echo -e "\nHi :)"
      '';

      # macOS Radar function (only useful on macOS)
      rdr = lib.optionalString isDarwin ''
        # Colors
        set -l green (set_color green)
        set -l blue (set_color blue)
        set -l yellow (set_color yellow)
        set -l red (set_color red)
        set -l cyan (set_color cyan)
        set -l normal (set_color normal)

        # Check for help flag
        if test "$argv[1]" = "-h" -o "$argv[1]" = "--help"
            echo "Usage: rdr <radar_number>"
            echo ""
            echo "Navigate to a specific Radar problem folder"
            echo ""
            echo "Arguments:"
            echo "  <radar_number>  The radar number (e.g., 123456789)"
            echo ""
            echo "Example:"
            echo "  rdr 123456789"
            return 0
        end

        # Check if radar number is provided
        if test (count $argv) -eq 0
            echo "Usage: rdr <radar_number>"
            return 1
        end

        set -l radar_number $argv[1]
        set -l radar_base_path "$HOME/Library/Application Support/Radar/Downloads/Problem"
        set -l radar_path "$radar_base_path/$radar_number"

        # Check if radar folder exists
        if not test -d "$radar_path"
            echo $red"[ERROR]"$normal" Failed to find radar "$radar_number$normal
            return 1
        end

        # Navigate to the radar folder
        cd "$radar_path"
        if test $status -eq 0
            echo $green"[SUCCESS]"$normal" Found Radar "$cyan$radar_number$normal
        else
            echo $red"[ERROR]"$normal" Failed to navigate to radar "$radar_number$normal
            return 1
        end
      '';
    };
  };

  # Enable Fish shell integrations for other tools
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.bat = {
    enable = true;
  };

  programs.eza = {
    enable = true;
  };
}
