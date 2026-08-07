# Content lives outside this repo in /var/www/<name>. nginx serves it live, so
# updating a site is an rsync, not a rebuild.
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
      Static sites to serve, keyed by name. Each entry gets its web root created,
      an nginx virtual host on its port, and that port opened in the firewall.
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
        # Web roots are rsync'd project dirs, so block dotfiles (.git, .claude).
        locations."~ /\\.".return = 404;
      }) cfg;
    };

    networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: site: site.port) cfg;
  };
}
