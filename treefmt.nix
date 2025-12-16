{ pkgs, ... }:
{
  projectRootFile = "flake.nix";

  # Nix
  programs.nixfmt.enable = true;

  # Rust
  programs.rustfmt.enable = true;

  # Go
  programs.gofmt.enable = true;

  # C/C++
  programs.clang-format.enable = true;

  # Python
  programs.ruff-format.enable = true;
  programs.ruff-check.enable = true;

  # Lua
  programs.stylua.enable = true;

  # Shell
  programs.shfmt.enable = true;

  # TOML
  programs.taplo.enable = true;

  # YAML
  programs.yamlfmt.enable = true;

  # JSON/Markdown
  programs.prettier.enable = true;
  programs.prettier.includes = [
    "*.json"
    "*.md"
  ];
}
