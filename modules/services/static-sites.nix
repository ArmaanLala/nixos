{
  config,
  lib,
  ...
}:
let
  cfg = config.staticSites;
  siteRoot = site: if site.source != null then toString site.source else site.root;
  mutableSites = lib.filterAttrs (_: site: site.source == null) cfg;
in
{
  options.staticSites = lib.mkOption {
    default = { };
    example = {
      alpd.port = 8417;
    };
    description = ''
      Static sites to serve, keyed by name. Each entry gets an nginx virtual
      host on its port and that port opened in the firewall. Content is either a
      mutable /var/www dir (default) or a store path (`source`).
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
              description = ''
                Directory served for this site. Only used when `source` is unset;
                it is created on the host and owned by armaan for rsync.
              '';
            };

            source = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = lib.literalExpression ''inputs.site-seth + "/website"'';
              description = ''
                A store path to serve instead of a mutable /var/www dir. When
                set, `root` is ignored and no host directory is created.
              '';
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
    ++ lib.mapAttrsToList (_: site: "d ${site.root} 0755 armaan users -") mutableSites;

    services.nginx = {
      enable = true;
      virtualHosts = lib.mapAttrs (_: site: {
        listen = [
          {
            addr = "0.0.0.0";
            port = site.port;
          }
        ];
        locations."/".root = siteRoot site;
        locations."~ /\\.".return = 404;
      }) cfg;
    };

    networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: site: site.port) cfg;
  };
}
