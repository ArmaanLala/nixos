{ pkgs, ... }:
{
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;
  programs.rustfmt.enable = true;
  programs.gofmt.enable = true;
  programs.clang-format.enable = true;
  programs.ruff-format.enable = true;
  programs.ruff-check.enable = true;
  programs.stylua.enable = true;
  programs.shfmt.enable = true;
  programs.taplo.enable = true;
  programs.yamlfmt.enable = true;
  programs.prettier.enable = true;
  programs.prettier.includes = [
    "*.json"
    "*.md"
  ];

  settings.global.excludes = [ "secrets/*" ];
}
