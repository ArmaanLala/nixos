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
      disko,
      colmena,
      treefmt-nix,
      claude-code,
      pwndbg,
      ...
    }:
    let
      # Hosts managed remotely via colmena
      remoteHosts = {
        atlas = {
          modules = [
            vpn-confinement.nixosModules.default
            ./hosts/atlas/configuration.nix
          ];
          targetHost = "ts-atlas";
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
            (
              { pkgs, ... }:
              {
                nixpkgs.overlays = [ claude-code.overlays.default ];
                environment.systemPackages = [ pkgs.claude-code ];
              }
            )
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga-7th-gen
            ./hosts/thinkpad/configuration.nix
          ];
          targetHost = "ts-thinkpad";
        };
      };

      # Local host, managed separately with nixos-rebuild / nh
      localHosts = {
        drapion = {
          modules = [
            (
              { pkgs, ... }:
              {
                nixpkgs.overlays = [ claude-code.overlays.default ];
                environment.systemPackages = [ pkgs.claude-code ];
              }
            )
            disko.nixosModules.disko
            ./hosts/drapion/configuration.nix
          ];
          nixpkgs = nixpkgs-unstable;
        };
      };

      allHosts = remoteHosts // localHosts;

      # Generate nixosConfigurations from hosts
      mkNixosConfig =
        name: cfg:
        let
          pkgs = if cfg ? nixpkgs then cfg.nixpkgs else nixpkgs;
        in
        pkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit colmena copyparty pwndbg; };
          modules = cfg.modules;
        };

      # Generate colmena node from hosts
      mkColmenaNode = name: cfg: {
        imports = cfg.modules;
        deployment.targetHost = cfg.targetHost;
      };
    in
    {
      nixosConfigurations = builtins.mapAttrs mkNixosConfig allHosts;

      colmenaHive = colmena.lib.makeHive (
        {
          meta = {
            nixpkgs = import nixpkgs { system = "x86_64-linux"; };
            specialArgs = { inherit colmena copyparty pwndbg; };
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
        // builtins.mapAttrs mkColmenaNode remoteHosts
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
