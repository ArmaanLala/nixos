# What a desktop host does when it goes *idle*: the greeter's blank/suspend
# timers and the command hypridle's last listener runs.
#
# Split out of desktop.nix so one host can opt out without forking the rest of
# the desktop role. drapion is the machine we ssh *into*: its RTL8125 sleeps
# with the box, so an unattended suspend strands every inbound session and needs
# a magic packet from another host to undo.
#
# Scope is deliberately idle-only. Suspending on purpose -- `systemctl suspend`,
# the keyboard's sleep key, the waybar power menu -- stays available everywhere,
# because the problem was never S3 itself, it was the machine deciding on S3
# while nobody was there to notice.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.desktop;
in
{
  options.desktop.autoSuspend = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether idling eventually suspends the machine on its own. With this off
      nothing auto-suspends: the displays still blank and the session still
      locks on hypridle's earlier timers, but the box stays up and SSHable
      until someone suspends it deliberately.

      hypridle's config is a plain dotfile shared by every host, so the opt-out
      works by installing `idle-suspend` as a no-op rather than by editing the
      timer.
    '';
  };

  config = {
    # Idle handling *at the greeter*. hypridle only exists inside a logged-in
    # compositor; tuigreet is a TUI on tty1, so the timers come from the kernel
    # (blank) and logind (suspend) instead.
    #
    # The kernel default is 0 (never blank). Only keyboard input resets the timer
    # -- console *output* doesn't -- so tuigreet's --time clock redrawing once a
    # second doesn't hold the screen on. fbcon passes the blank down to the DRM
    # driver, which drops the CRTC, so the monitor generally sleeps rather than
    # just going black. Applies to VTs only: a compositor holding DRM master
    # never sees it. Blanking is display-off, not suspend, so it stays either
    # way -- it is exactly the behaviour autoSuspend = false keeps.
    boot.kernelParams = [ "consoleblank=300" ];

    # IdleAction fires when every idle-capable session is idle. Greeter sessions
    # count (systemd's SESSION_CLASS_CAN_IDLE includes them) and are type=tty, so
    # "idle" means the atime of /dev/tty1, i.e. actual keystrokes. Graphical
    # sessions are judged by an explicit idle hint that neither niri nor Hyprland
    # sets, so this cannot fire under a live desktop -- hypridle still owns that.
    # Idle tty/ssh logins do count, and `systemd-inhibit --what=idle` blocks it.
    #
    # This is the path that bites an always-on host, and the one most easily
    # missed: sitting at the greeter, or holding an idle SSH shell, is enough to
    # suspend the machine out from under you without any desktop involved.
    #
    # Note that logind only re-reads this on reload, which `nixos-rebuild switch`
    # does not do -- `systemctl reload systemd-logind` after a change (reload,
    # not restart: a restart takes the graphical session with it).
    services.logind.settings.Login = {
      IdleAction = if cfg.autoSuspend then "suspend" else "ignore";
      IdleActionSec = "15min";
    };

    # The command hypridle's 20-minute listener runs. Always installed under
    # this name -- hypridle.conf is shared across hosts and would otherwise log
    # "command not found" every idle period on the opted-out ones.
    environment.systemPackages = [
      (
        if cfg.autoSuspend then
          # Suspend, wrapped so it never drops a live SSH session.
          #
          # The waiting has to happen inside this script: hypridle fires
          # on-timeout once per idle period and never retries, so simply
          # declining to suspend would leave the box awake until someone touched
          # it locally.
          #
          # hyprlock doubles as the idle proxy. The 10-min listener locked the
          # session, so hyprlock still running means nobody has come back to the
          # machine. Once it exits the user has unlocked, this timeout is stale,
          # and suspending now would pull the desktop out from under them.
          (pkgs.writeShellScriptBin "idle-suspend" ''
            while ${pkgs.procps}/bin/pidof hyprlock >/dev/null 2>&1; do
              # sport matches inbound sessions only -- our own outbound ssh to other
              # hosts lands on dport and must not hold this machine awake.
              if [ -z "$(${pkgs.iproute2}/bin/ss -H -t state established '( sport = :ssh )')" ]; then
                exec ${pkgs.systemd}/bin/systemctl suspend
              fi
              ${pkgs.coreutils}/bin/sleep 60
            done
          '')
        else
          # Displays are already off and the session already locked by the time
          # hypridle gets here; there is nothing left to do but say so. A manual
          # `systemctl suspend` still works -- only the automatic one is gone.
          (pkgs.writeShellScriptBin "idle-suspend" ''
            echo "idle-suspend: auto-suspend is off on ${config.networking.hostName}; staying awake" >&2
          '')
      )
    ];
  };
}
