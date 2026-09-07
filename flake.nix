{
  description = "NixOS configurations for all hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    pwndbg.url = "github:pwndbg/pwndbg";
    pwndbg.inputs.nixpkgs.follows = "nixpkgs";
    claude-code.url = "github:sadjow/claude-code-nix";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    site-seth = {
      url = "github:ArmaanLala/seth";
      flake = false;
    };
    site-trumpet-snipes = {
      url = "github:ArmaanLala/trumpet-snipes";
      flake = false;
    };

    microbin-src = {
      url = "github:ArmaanLala/microbin";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      disko,
      vpn-confinement,
      treefmt-nix,
      pwndbg,
      claude-code,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./lib/treefmt.nix;

      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      specialArgs = {
        inherit
          inputs
          pwndbg
          unstable
          claude-code
          ;
      };
    in
    {
      nixosConfigurations = {
        atlas = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            vpn-confinement.nixosModules.default
            ./hosts/atlas/configuration.nix
          ];
        };

        proton = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            ./hosts/proton/configuration.nix
            vpn-confinement.nixosModules.default
          ];
        };

        lenix = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [ ./hosts/lenix/configuration.nix ];
        };

        webster = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [ ./hosts/webster/configuration.nix ];
        };

        thinkpad = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga-7th-gen
            ./hosts/thinkpad/configuration.nix
          ];
        };

        bread = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            disko.nixosModules.disko
            ./hosts/bread/configuration.nix
          ];
        };
      };

      formatter.${system} = treefmtEval.config.build.wrapper;

      checks.${system}.formatting = treefmtEval.config.build.check self;
    };
}
