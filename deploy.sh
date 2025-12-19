#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

deploy_host() {
  local host="$1"
  echo -e "\n\033[1;31mDeploying to $host...\033[0m\n"
  ssh "$host" "cd /etc/nixos && sudo git pull && sudo nixos-rebuild switch --flake .#$host"
}

if [[ $1 == "--all" ]]; then
  for host_dir in "$SCRIPT_DIR"/hosts/*/; do
    host=$(basename "$host_dir")
    deploy_host "$host"
  done
else
  host=${1:?Usage: ./deploy.sh <host> or ./deploy.sh --all}
  deploy_host "$host"
fi
