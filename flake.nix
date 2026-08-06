{
  description = "NixOS configurations for all hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";
    # No `follows` for vpn-confinement: that flake declares no inputs at all, so
    # an override would warn about a non-existent input on every evaluation.
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    pwndbg.url = "github:pwndbg/pwndbg";
    pwndbg.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      vpn-confinement,
      treefmt-nix,
      pwndbg,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./lib/treefmt.nix;

      specialArgs = { inherit pwndbg; };
    in
    {
      # Hosts pull the newest config from git and rebuild themselves via
      # system.autoUpgrade (configured in modules/common.nix).
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
          modules = [ ./hosts/proton/configuration.nix ];
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

        # drapion tracks unstable rather than the 25.11 release.
        drapion = nixpkgs-unstable.lib.nixosSystem {
          inherit system specialArgs;
          modules = [ ./hosts/drapion/configuration.nix ];
        };
      };

      formatter.${system} = treefmtEval.config.build.wrapper;

      # Makes `nix flake check` fail on formatting drift instead of leaving
      # `nix fmt` advisory. CI runs this alongside the per-host evaluations.
      checks.${system}.formatting = treefmtEval.config.build.check self;
    };
}
