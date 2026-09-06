# Static sites served by nginx, one nginx virtual host per entry.
#
# Two ways to provide content:
#   * `source` unset  -- content lives outside the repo in /var/www/<name>;
#     nginx serves it live, so updating the site is an rsync, not a rebuild.
#   * `source` set     -- content comes from a flake input (a plain source tree)
#     and is served straight from the Nix store. Updating the site is
#     `nix flake update site-<name>` + rebuild: declarative, atomic, revertable.
{
  config,
  lib,
  ...
}:
let
  cfg = config.staticSites;

  # Web root for one site: a store path when `source` is set, else the mutable
  # /var/www dir.
  siteRoot =
    site:
    if site.source != null then
      "${site.source}${lib.optionalString (site.subdir != "") "/${site.subdir}"}"
    else
      site.root;

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
      mutable /var/www dir (default) or a flake-input source tree (`source`).
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
              example = lib.literalExpression "inputs.site-seth";
              description = ''
                A source tree (typically a `flake = false` input) to serve from
                the Nix store instead of a mutable /var/www dir. When set, `root`
                is ignored and no host directory is created.
              '';
            };

            subdir = lib.mkOption {
              type = lib.types.str;
              default = "";
              example = "website";
              description = "Subdirectory of `source` that holds the web root.";
            };

            extraLocations = lib.mkOption {
              type = lib.types.attrsOf lib.types.attrs;
              default = { };
              description = ''
                Extra nginx `locations` entries merged into this site's virtual
                host -- e.g. pointing one path at a mutable dir that a timer
                writes into, while the rest of the site is served from the store.
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
        locations = {
          "/".root = siteRoot site;
          # Web roots are rsync'd or checked-out project dirs, so block dotfiles
          # (.git, .claude).
          "~ /\\.".return = 404;
        }
        // site.extraLocations;
      }) cfg;
    };

    networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: site: site.port) cfg;
  };
}
