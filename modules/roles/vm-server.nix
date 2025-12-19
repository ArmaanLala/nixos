# VM Server role: bundles common VM server modules
# Used by: atlas, proton, webserv, weed
{ ... }:

{
  imports = [
    ../auto-upgrade.nix
    ../vm-config.nix
    ../vm-hardware-config.nix
  ];
}
