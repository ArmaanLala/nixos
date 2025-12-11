# Developer environment - Languages and tools beyond common.nix
{ pkgs, ... }:

{
  users.users.armaan.packages = with pkgs; [
    # Languages
    rustup
    go
    gopls
    swift
    jdk
    clang
    llvm

    # Python (python3 in common.nix)
    python3Packages.pip
    uv
    ruff

    # Reverse engineering
    ghidra

    # Data processing
    jq
    yq
  ];
}
