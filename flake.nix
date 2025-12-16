{
  description = "NixOS configurations for all hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    stylix.url = "github:danth/stylix/release-25.11";
    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-darwin,
      nixos-hardware,
      nix-darwin,
      zen-browser,
      vpn-confinement,
      stylix,
      colmena,
      treefmt-nix,
      ...
    }:
    {
      nixosConfigurations = {
        atlas = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            vpn-confinement.nixosModules.default
            ./hosts/atlas/configuration.nix
          ];
        };

        beef = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit zen-browser;
          };
          modules = [
            stylix.nixosModules.stylix
            ./hosts/beef/configuration.nix
          ];
        };

        proton = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            vpn-confinement.nixosModules.default
            ./hosts/proton/configuration.nix
          ];
        };

        lenix = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/lenix/configuration.nix
          ];
        };

        webserv = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/webserv/configuration.nix
          ];
        };

        thinkpad = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit zen-browser;
          };
          modules = [
            stylix.nixosModules.stylix
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga-7th-gen
            ./hosts/thinkpad/configuration.nix
          ];
        };
      };

      darwinConfigurations = {
        "Armaans-MacBook-Pro" = nix-darwin.lib.darwinSystem {
          modules = [
            ./hosts/macbook/configuration.nix
          ];
        };
      };

      colmenaHive = colmena.lib.makeHive {
        meta = {
          nixpkgs = import nixpkgs { system = "x86_64-linux"; };
          specialArgs = {
            inherit zen-browser;
          };
        };

        defaults =
          { ... }:
          {
            imports = [ ./modules/common.nix ];
            deployment.targetUser = "armaan";
          };

        atlas = {
          imports = [
            vpn-confinement.nixosModules.default
            ./hosts/atlas/configuration.nix
          ];
          deployment.targetHost = "ts-atlas";
        };

        beef = {
          imports = [
            stylix.nixosModules.stylix
            ./hosts/beef/configuration.nix
          ];
          deployment.targetHost = "ts-beef";
        };

        proton = {
          imports = [
            vpn-confinement.nixosModules.default
            ./hosts/proton/configuration.nix
          ];
          deployment.targetHost = "ts-proton";
        };

        lenix = {
          imports = [ ./hosts/lenix/configuration.nix ];
          deployment.targetHost = "ts-lenix";
        };

        webserv = {
          imports = [ ./hosts/webserv/configuration.nix ];
          deployment.targetHost = "ts-web";
        };

        thinkpad = {
          imports = [
            stylix.nixosModules.stylix
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga-7th-gen
            ./hosts/thinkpad/configuration.nix
          ];
          deployment.targetHost = "ts-thinkpad";
        };
      };

      formatter.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        in
        treefmtEval.config.build.wrapper;
    };
}
