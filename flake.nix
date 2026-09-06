{
  description = "NixOS configurations for all hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";
    # No `follows`: vpn-confinement declares no inputs, so an override warns every eval.
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    pwndbg.url = "github:pwndbg/pwndbg";
    pwndbg.inputs.nixpkgs.follows = "nixpkgs";
    # No `follows`: overriding nixpkgs changes the derivation hash and defeats
    # the Cachix binary cache that's the whole point of using this flake.
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs =
    {
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

      # Cherry-pick individual packages from unstable on the 25.11 hosts, as
      # `unstable.foo`. Instantiated once and shared; allowUnfree has to be
      # repeated here because it is set on the host's own pkgs, not this one.
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      specialArgs = { inherit pwndbg unstable claude-code; };
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

        drapion = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            disko.nixosModules.disko
            ./hosts/drapion/configuration.nix
          ];
        };
      };

      formatter.${system} = treefmtEval.config.build.wrapper;

      # Makes `nix flake check` fail on formatting drift, not just advise via `nix fmt`.
      checks.${system}.formatting = treefmtEval.config.build.check self;
    };
}
