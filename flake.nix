{
  description = "NixOS configurations for all hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
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
      };
    };
}
