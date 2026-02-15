{
  description = "NixOS configurations for all hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    copyparty.url = "github:9001/copyparty";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
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
      nixos-hardware,
      vpn-confinement,
      copyparty,
      disko,
      colmena,
      treefmt-nix,
      ...
    }:
    let
      # Single source of truth for host configurations
      hosts = {
        atlas = {
          modules = [
            vpn-confinement.nixosModules.default
            ./hosts/atlas/configuration.nix
          ];
          targetHost = "ts-atlas";
        };

        beef = {
          modules = [
            ./hosts/beef/configuration.nix
          ];
          targetHost = "ts-beef";
        };

        drapion = {
          modules = [
            disko.nixosModules.disko
            ./hosts/drapion/configuration.nix
          ];
          targetHost = "ts-drapion";
        };

        proton = {
          modules = [
            vpn-confinement.nixosModules.default
            ./hosts/proton/configuration.nix
          ];
          targetHost = "ts-proton";
        };

        lenix = {
          modules = [ ./hosts/lenix/configuration.nix ];
          targetHost = "ts-lenix";
        };

        webserv = {
          modules = [
            copyparty.nixosModules.default
            ./hosts/webserv/configuration.nix
          ];
          targetHost = "ts-web";
        };

        thinkpad = {
          modules = [
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga-7th-gen
            ./hosts/thinkpad/configuration.nix
          ];
          targetHost = "ts-thinkpad";
        };
      };

      # Generate nixosConfigurations from hosts
      mkNixosConfig =
        name: cfg:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit colmena copyparty; };
          modules = cfg.modules;
        };

      # Generate colmena node from hosts
      mkColmenaNode = name: cfg: {
        imports = cfg.modules;
        deployment.targetHost = cfg.targetHost;
      };
    in
    {
      nixosConfigurations = builtins.mapAttrs mkNixosConfig hosts;

      colmenaHive = colmena.lib.makeHive (
        {
          meta = {
            nixpkgs = import nixpkgs { system = "x86_64-linux"; };
            specialArgs = { inherit colmena copyparty; };
          };

          defaults =
            { ... }:
            {
              imports = [ ./modules/common.nix ];
              deployment = {
                targetUser = "armaan";
              };
            };
        }
        // builtins.mapAttrs mkColmenaNode hosts
      );

      formatter.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./lib/treefmt.nix;
        in
        treefmtEval.config.build.wrapper;

      devShells.x86_64-linux.default =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        pkgs.mkShell {
          packages = [ colmena.packages.x86_64-linux.colmena ];
        };

      apps.x86_64-linux.colmena = {
        type = "app";
        program = "${colmena.packages.x86_64-linux.colmena}/bin/colmena";
      };
    };
}
