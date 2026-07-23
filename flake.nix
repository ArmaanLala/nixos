{
  description = "NixOS configurations for all hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    copyparty.url = "github:9001/copyparty";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    claude-code.url = "github:sadjow/claude-code-nix";
    pwndbg.url = "github:pwndbg/pwndbg";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      vpn-confinement,
      copyparty,
      treefmt-nix,
      claude-code,
      pwndbg,
      ...
    }:
    let
      specialArgs = {
        inherit
          copyparty
          pwndbg
          claude-code
          ;
      };

      # All hosts. Each entry provides a module list; the optional `nixpkgs`
      # attribute overrides the default (stable) channel for that host.
      # Hosts pull the newest config from git and rebuild themselves via
      # system.autoUpgrade (configured in modules/common.nix).
      hosts = {
        atlas.modules = [
          vpn-confinement.nixosModules.default
          ./hosts/atlas/configuration.nix
        ];

        proton.modules = [ ./hosts/proton/configuration.nix ];

        lenix.modules = [ ./hosts/lenix/configuration.nix ];

        webserv.modules = [
          copyparty.nixosModules.default
          ./hosts/webserv/configuration.nix
        ];

        thinkpad.modules = [
          nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga-7th-gen
          ./hosts/thinkpad/configuration.nix
        ];

        drapion = {
          modules = [ ./hosts/drapion/configuration.nix ];
          nixpkgs = nixpkgs-unstable;
        };
      };

      # Generate a nixosSystem from a host entry
      mkNixosConfig =
        name: cfg:
        let
          pkgs = if cfg ? nixpkgs then cfg.nixpkgs else nixpkgs;
        in
        pkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = cfg.modules;
        };
    in
    {
      nixosConfigurations = builtins.mapAttrs mkNixosConfig hosts;

      formatter.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./lib/treefmt.nix;
        in
        treefmtEval.config.build.wrapper;
    };
}
