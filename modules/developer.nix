# Developer environment - Languages and tools beyond common.nix
# (Core tools like git, gcc, python3 are in common.nix environment.systemPackages)
{ pkgs, ... }:

{
  users.users.armaan.packages = with pkgs; [
    # Programming languages
    rustup
    go
    gopls
    jdk
    clang
    llvm

    # Python tooling (python3 interpreter + pip in systemPackages)
    uv
    ruff

    # Reverse engineering
    ghidra

    # Data processing
    jq
    yq

    # Formatters (for editor integration and direct use)
    treefmt
    rustfmt
    clang-tools # includes clang-format
    stylua
    shfmt
    taplo
    yamlfmt
    nodePackages.prettier
  ];
}
