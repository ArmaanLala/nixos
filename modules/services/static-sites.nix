# Static sites served straight off disk by nginx.
#
# Content lives OUTSIDE this repo in /var/www/<name> and is published by the
# deploy.sh in each source project (~/pptnight, ~/givememoney). nginx serves the
# files live, so updating a site needs no rebuild — just rsync.
{ config, lib, ... }:
let
  cfg = config.staticSites;
in
{
  options.staticSites = lib.mkOption {
    default = { };
    example = {
      alpd.port = 8417;
    };
    description = ''
      Static sites to serve, keyed by name. Each one gets its web root created,
      an nginx virtual host on its port, and that port opened in the firewall —
      previously three hand-maintained lists.
    '';
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            port = lib.mkOption {
              type = lib.types.port;
              description = "Port this site listens on.";
            };

            root = lib.mkOption {
              type = lib.types.str;
              default = "/var/www/${name}";
              description = "Directory served for this site.";
            };
          };
        }
      )
    );
  };

  config = lib.mkIf (cfg != { }) {
    systemd.tmpfiles.rules = [
      "d /var/www 0755 root root -"
    ]
    ++ lib.mapAttrsToList (_: site: "d ${site.root} 0755 armaan users -") cfg;

    services.nginx = {
      enable = true;
      virtualHosts = lib.mapAttrs (_: site: {
        listen = [
          {
            addr = "0.0.0.0";
            port = site.port;
          }
        ];
        locations."/".root = site.root;
        # Never serve dotfiles/dirs (.claude, .git, ...) even though the web
        # root is the source project's working directory.
        locations."~ /\\.".return = 404;
      }) cfg;
    };

    networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: site: site.port) cfg;
  };
}
