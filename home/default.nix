{ config, pkgs, lib, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  imports = [
    ./fish.nix
    ./git.nix
    ./ghostty.nix
  ];

  home.stateVersion = "25.11";

  # Disable nixpkgs version check (we're using unstable for some hosts)
  home.enableNixpkgsReleaseCheck = false;

  # Note: Neovim config is managed by stow (dotfiles/.config/nvim submodule)
  # We don't need to manage it here to avoid conflicts

  # Core CLI tools that should be available everywhere
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    eza
    lazygit
    htop
    jq
    yq
  ] ++ lib.optionals isLinux [
    # Linux-specific packages
  ] ++ lib.optionals isDarwin [
    # macOS-specific packages
  ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
