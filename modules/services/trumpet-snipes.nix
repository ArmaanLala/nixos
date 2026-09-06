# trumpet-snipes -- a static site plus a small Java job that rebuilds its
# leaderboard JSON from the GroupMe API.
#
# The site itself is served straight from the flake input (read-only Nix store).
# The generated JSON can't live there, so nginx serves /json/ from a mutable
# directory that a systemd timer writes into.
#
# Secret: the GroupMe token comes from sops (secrets/webster.yaml ->
# groupme_token), rendered into an EnvironmentFile via sops.templates.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  src = inputs.site-trumpet-snipes;
  jsonDir = "/var/lib/trumpet-snipes/json";

  # First day of the leaderboard period, passed to the calculator (MM-DD-YY).
  # Bump this when a new season starts.
  leaderboardStart = "08-01-25";
  groupId = "61897280";

  # com.jmschonfeld.SnipeLeaderboard, compiled from the fork's groupme-java/.
  groupme = pkgs.runCommand "trumpet-snipes-groupme" { nativeBuildInputs = [ pkgs.jdk ]; } ''
    mkdir -p $out/share/classes
    cp -r ${src}/groupme-java/lib $out/share/lib
    javac -cp $out/share/lib/json-simple-1.1.1.jar -d $out/share/classes \
      $(find ${src}/groupme-java/src -name '*.java')
  '';
in
{
  sops.secrets.groupme_token.sopsFile = ../../secrets/webster.yaml;
  sops.templates."groupme.env".content = ''
    GROUPME_TOKEN=${config.sops.placeholder.groupme_token}
  '';

  staticSites.trumpet-snipes = {
    port = 8100;
    source = src;
    subdir = "website";
    # Overrides the committed (stale) website/json/ with the live copy.
    extraLocations."/json/".alias = "${jsonDir}/";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/trumpet-snipes 0755 nginx nginx -"
    "d ${jsonDir} 0755 nginx nginx -"
  ];

  systemd.services.trumpet-snipes-json = {
    description = "Rebuild trumpet-snipes GroupMe snipe leaderboard JSON";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "nginx";
      Group = "nginx";
      EnvironmentFile = config.sops.templates."groupme.env".path;
      ExecStart = pkgs.writeShellScript "trumpet-snipes-json" ''
        set -euo pipefail
        ${pkgs.jre}/bin/java \
          -cp ${groupme}/share/lib/json-simple-1.1.1.jar:${groupme}/share/classes \
          com.jmschonfeld.SnipeLeaderboard json \
          groupid=${groupId} date=${leaderboardStart} token="$GROUPME_TOKEN" \
          > ${jsonDir}/index.json.tmp
        mv ${jsonDir}/index.json.tmp ${jsonDir}/index.json
      '';
    };
  };

  systemd.timers.trumpet-snipes-json = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # The old crontab schedule wasn't kept -- hourly is a guess, adjust freely.
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };
}
