# Secrets Management

Nothing here is in the repo, and nothing here is provisioned automatically. Each
file has to be placed on the host by hand before the service that needs it will
start. A freshly installed host is silently degraded until these exist.

| Secret                                 | Hosts   | Consumed by                       | Missing-file behaviour               |
| -------------------------------------- | ------- | --------------------------------- | ------------------------------------ |
| `/etc/nixos/secrets/proton.conf`       | atlas   | `modules/vpn.nix`                 | VPN namespace fails to come up       |
| `/etc/nix/github-token.conf`           | all     | `modules/common.nix`              | Tolerated — see below                |
| `/var/lib/vaultwarden/vaultwarden.env` | webster | `hosts/webster/configuration.nix` | `vaultwarden.service` fails to start |

## ProtonVPN config (atlas)

Used by `vpnNamespaces.wg` to confine sabnzbd.

1. Download a WireGuard config from the ProtonVPN dashboard.
2. Place it at `/etc/nixos/secrets/proton.conf` on atlas.
3. `chmod 600 /etc/nixos/secrets/proton.conf`

Note that `wireguardConfigFile` is a **quoted string**, not a path literal. This
is deliberate: as a string the value is interpolated into a shell script and read
at runtime, so the secret never enters `/nix/store`. Rewriting it as a bare path
does not leak it — it fails evaluation outright on every host with `access to
absolute path ... is forbidden in pure evaluation mode`.

## GitHub token (all hosts)

Raises the GitHub API rate limit for flake fetches. `modules/common.nix` pulls it
in with:

```
nix.extraOptions = "!include /etc/nix/github-token.conf";
```

The `!include` (rather than `include`) is deliberate — per `nix.conf(5)` a
missing file is only an error for `include`. A host without the token still
evaluates and rebuilds; it just fetches from GitHub unauthenticated and may hit
rate limits during `nix flake update`.

Format:

```
access-tokens = github.com=ghp_...
```

`chmod 600`, owned by root.

## Vaultwarden admin token (webster)

Vaultwarden runs with `SIGNUPS_ALLOWED = false`, so the admin panel is the only
way to create the first account. Without this file the unit does not start at
all — systemd treats a missing `EnvironmentFile` as fatal.

1. Generate an Argon2id PHC string (needs a TTY; it will not accept piped input):

   ```
   nix run nixpkgs#vaultwarden -- hash
   ```

2. Write it on webster, single-quoted so the `$` in the PHC string survives:

   ```
   sudo install -d -m 0700 /var/lib/vaultwarden
   sudo tee /var/lib/vaultwarden/vaultwarden.env >/dev/null <<'EOF'
   ADMIN_TOKEN='$argon2id$v=19$m=65540,t=3,p=4$...'
   EOF
   sudo chmod 600 /var/lib/vaultwarden/vaultwarden.env
   ```

3. Log in at `https://vault.armaanlala.tech/admin` with the **plaintext** token
   and invite your own account. Keep the plaintext in a password manager — it
   cannot be recovered from the hash.

## On secrets management

Deliberately not using sops-nix or agenix for now — three files placed by hand is
manageable, and this document is the register. Revisit if the count grows or if a
host rebuild ever comes up degraded because one of them was forgotten.

If it does get revisited: `sops-nix` with host age keys derived from the existing
SSH host keys would let all three live encrypted **in this repo**, which fits
here specifically because `system.autoUpgrade` already fetches from GitHub — the
flake source is the delivery mechanism for everything else.
