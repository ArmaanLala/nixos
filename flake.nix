{
  description = "NixOS configurations for all hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    {
      nixosConfigurations = {
        atlas = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/atlas/configuration.nix ];
        };

        proton = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/proton/configuration.nix ];
        };
      };
    };
}
