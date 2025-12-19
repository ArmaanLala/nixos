# Nix settings: experimental features, unfree config, nh integration
{ ... }:

{
  nix.settings = {
    trusted-users = [
      "root"
      "@wheel"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.variables.EDITOR = "nvim";

  programs.git = {
    enable = true;
    config = {
      credential.helper = "!gh auth git-credential";
      user.name = "Armaan Lala";
      user.email = "armaanlala@gmail.com";
    };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/etc/nixos";
  };
}
