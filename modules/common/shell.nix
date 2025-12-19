# Shell configuration: Fish, Bash integration, aliases, starship
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.common.enableShell {
    programs.bash = {
      interactiveShellInit = ''
        if [[ $EUID -ne 0 && $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };

    programs.fish = {
      enable = true;
      shellAliases = {
        v = "nvim";
        cat = "bat";
        mv = "mv -i";
        rm = "rm -Iv";
        df = "df -h";
        du = "du -h -d 1";
        k = "killall";
        p = "ps aux | grep $1";
        l = "eza --color=auto --icons -h";
        ll = "eza --color=auto --icons -lh";
        ls = "eza --color=auto --icons -h";
        la = "eza --color=auto --icons -lah";
      };
    };
  };
}
