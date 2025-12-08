#!/usr/bin/env bash
set -e
host=${1:?Usage: ./deploy.sh <host>}
ssh "$host" "cd /etc/nixos && sudo git pull && sudo nixos-rebuild switch --flake .#$host"
