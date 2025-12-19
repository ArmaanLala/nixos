# Secrets Management

VPN config stored at `/etc/nixos/secrets/proton.conf` (gitignored).

## Setup on a new host

1. Copy `proton.conf` to `/etc/nixos/secrets/` on the host
2. Ensure correct permissions: `chmod 600 /etc/nixos/secrets/proton.conf`
3. The vpn.nix module references this path automatically

## Generate new VPN config

1. Download new config from ProtonVPN dashboard
2. Place in `/etc/nixos/secrets/proton.conf` on each VPN host (atlas, proton)
