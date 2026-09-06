# trumpet-snipes -- a static site plus a small Java job that rebuilds its
# leaderboard JSON from the GroupMe API.
#
# The site itself is served from the Nix store (via staticSites). The generated
# JSON can't live there, so this module adds a /json/ location pointing at a
# writable dir that a systemd timer fills.
#
# Secret: the GroupMe token comes from sops (secrets/webster.yaml ->
# groupme_token), rendered into an EnvironmentFile via sops.templates.
{
  config,
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
  groupme = pkgs.runCommand "trumpet-snipes-groupme" { nativeBuildInputs = [ pkgs.jdk_headless ]; } ''
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
    source = src + "/website";
  };

  # Live leaderboard JSON, overriding the committed (stale) website/json/.
  services.nginx.virtualHosts."trumpet-snipes".locations."/json/".alias = "${jsonDir}/";

  systemd.tmpfiles.rules = [ "d ${jsonDir} 0755 nginx nginx -" ];

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
        ${pkgs.jdk_headless}/bin/java \
          -cp ${groupme}/share/lib/json-simple-1.1.1.jar:${groupme}/share/classes \
          com.jmschonfeld.SnipeLeaderboard json \
          groupid=${groupId} date=${leaderboardStart} token="$GROUPME_TOKEN" \
          > ${jsonDir}/index.json.tmp
        mv ${jsonDir}/index.json.tmp ${jsonDir}/index.json
      '';
    };
  };

  # Also runnable on demand: `systemctl start trumpet-snipes-json` (scripts/trumpet).
  systemd.timers.trumpet-snipes-json = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/30";
      Persistent = true;
      RandomizedDelaySec = "2m";
    };
  };
}
