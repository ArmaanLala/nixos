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

        weed = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/weed/configuration.nix
          ];
        };

        beef = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit zen-browser;
          };
          modules = [
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
    };
}
