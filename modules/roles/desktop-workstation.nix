# Desktop Workstation role: bundles desktop environment modules
# Used by: beef, thinkpad
{ ... }:

{
  imports = [
    ../desktop.nix
    ../developer.nix
    ../steam.nix
  ];
}
