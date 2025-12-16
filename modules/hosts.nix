# Network hosts configuration
{ ... }:

{
  networking.hosts = {
    # Local network
    "10.0.0.30" = [ "prometheus" ];
    "10.0.0.31" = [ "clio" ];
    "10.0.0.32" = [ "orpheus" ];
    "10.0.0.33" = [ "aether" ];
    "10.0.0.69" = [ "proton" ];
    "10.0.0.99" = [ "teapot" ];
    "10.0.0.100" = [ "servarr" ];
    "10.0.0.101" = [ "seagate" ];
    "10.0.0.102" = [ "repoman" ];
    "10.0.0.105" = [ "weed" ];
    "10.0.0.113" = [ "thinkpad" ];
    "10.0.0.114" = [ "thinkpad" ];
    "10.0.0.139" = [ "photos" ];
    "10.0.0.144" = [ "cftunnel" ];
    "10.0.0.160" = [ "truenas" ];
    "10.0.0.174" = [ "atlas" ];
    "10.0.0.183" = [ "beef" ];
    "10.0.0.186" = [ "lenix" ];
    "10.0.0.200" = [ "hydra" ];
    "10.0.0.201" = [ "loki" ];
    "10.0.0.202" = [ "calliope" ];
    "10.0.0.203" = [ "iris" ];
    "10.0.0.222" = [ "pihole" ];
    "10.0.0.250" = [ "alpine" ];

    # Tailscale IPs
    "100.76.77.32" = [ "macbook" ];
    "100.90.169.115" = [ "ts-atlas" ];
    "100.111.77.26" = [ "ts-beef" ];
    "100.100.183.39" = [ "ts-desktop" ];
    "100.106.33.35" = [ "iphone" ];
    "100.106.156.10" = [ "ts-lenix" ];
    "100.112.154.50" = [ "ts-nyx" ];
    "100.87.181.8" = [ "ts-proton" ];
    "100.103.38.71" = [
      "jumpbox"
      "ts-tailscale"
    ];
    "100.126.39.59" = [ "ts-thinkpad" ];
    "100.96.173.87" = [ "ts-web" ];
    "100.91.201.78" = [ "ts-truenas" ];
  };
}
