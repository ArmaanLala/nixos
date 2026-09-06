# Secrets Management

Most secrets live **encrypted in this repo** under `secrets/`, managed with
[sops-nix](https://github.com/Mic92/sops-nix). Each host decrypts the ones meant
for it at activation, using an age key derived from its own SSH host key — so
nothing is copied to hosts by hand, and `system.autoUpgrade` delivers secret
changes along with everything else.

Two secrets can't work this way and stay hand-placed (see the end of this doc):

| Secret                           | Hosts | Consumed by                | Why not sops                                           |
| -------------------------------- | ----- | -------------------------- | ------------------------------------------------------ |
| `/etc/nix/github-token.conf`     | all   | `modules/core/common.nix`  | `nix` needs it to fetch flake inputs, before sops runs |
| `/etc/nixos/secrets/proton.conf` | atlas | `modules/services/vpn.nix` | not migrated yet — see below                           |

## What's in sops

| File                   | Decryptable by  | Contents                                   |
| ---------------------- | --------------- | ------------------------------------------ |
| `secrets/webster.yaml` | armaan, webster | `microbin_admin_password`, `groupme_token` |

Each value is wired to a service in its module via `sops.secrets` +
`sops.templates` (grep the module for `sops.`). The decrypted result lands under
`/run/secrets/` (tmpfs, root-only) and never touches the Nix store or disk.

Vaultwarden needs no secret: it runs from the upstream container with
`SIGNUPS_ALLOWED=true` and no `ADMIN_TOKEN`.

## How it works

- **`.sops.yaml`** (repo root) maps secret files to the age keys allowed to
  decrypt them. Host keys are `ssh <host> 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age`.
  `armaan` is the personal key at `~/.config/sops/age/keys.txt` on the
  workstation — required to edit any secret.
- **`modules/core/sops.nix`** (imported by `common.nix`, so every host has it)
  points sops-nix at `/etc/ssh/ssh_host_ed25519_key` as the decryption key.
- Secrets are declared in the module that uses them, each naming its own
  `sopsFile`. There is no `defaultSopsFile` — hosts without a secrets file must
  not reference one or eval breaks.

## Editing or adding a secret

Get the tools once: `nix shell nixpkgs#sops nixpkgs#age nixpkgs#ssh-to-age`.

```
cd ~/dotfiles/.config/nixos

# edit an existing file (opens $EDITOR with values decrypted, re-encrypts on save)
sops secrets/webster.yaml

# view without editing
sops -d secrets/webster.yaml

# create a new file — the name must match a creation_rule in .sops.yaml
sops secrets/atlas.yaml
```

Then in the consuming module:

```nix
sops.secrets.my_secret.sopsFile = ../../secrets/webster.yaml;

# for a plain single-value file, config.sops.secrets.my_secret.path is it.
# for an EnvironmentFile / multi-value file, render one:
sops.templates."foo.env".content = ''
  TOKEN=${config.sops.placeholder.my_secret}
'';
# serviceConfig.EnvironmentFile = config.sops.templates."foo.env".path;
```

Commit the encrypted file and the module change together. Push before relying on
a host rebuild (same as the rest of the repo — see README "Deploy model").

## Adding a host to sops

1. `ssh <host> 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age`
2. Add the `age1…` to `.sops.yaml` under `keys:` and to whichever
   `creation_rules` it should be able to decrypt.
3. `sops updatekeys secrets/<file>` for every file whose recipients changed.
4. Commit.

New VM clones share the template's SSH host key — regenerate before using them
for secrets: `sudo rm /etc/ssh/ssh_host_* && sudo ssh-keygen -A && sudo systemctl restart sshd`,
then fix `~/.ssh/known_hosts` on the workstation.

## Recovering

The personal key `~/.config/sops/age/keys.txt` is the escape hatch — keep a copy
in a password manager. If it's lost but any host key still works, decrypt on that
host (or via its `/etc/ssh/ssh_host_ed25519_key`) and re-key with `sops
updatekeys` once a new personal key is in `.sops.yaml`.

---

## GitHub token (all hosts) — hand-placed

Two jobs: raises the GitHub API rate limit for flake fetches, **and** (with
`repo` scope) lets hosts pull the private `site-seth` / `site-trumpet-snipes`
flake inputs. `modules/core/common.nix` pulls it in with:

```
nix.extraOptions = "!include /etc/nix/github-token.conf";
```

This can't be a sops secret: `nix` reads it while fetching flake inputs, which
happens before NixOS activation — so before sops-nix has decrypted anything.

`!include` (not `include`) means a missing file is tolerated — but a host whose
evaluation touches a private input (currently only webster) then fails to fetch
it. Format, `chmod 600`, owned by root:

```
access-tokens = github.com=ghp_...
```

Also add it as a GitHub Actions repository secret so CI can evaluate webster.

## ProtonVPN config (atlas) — hand-placed, migrate later

Used by `vpnNamespaces.wg` to confine sabnzbd.

1. Download a WireGuard config from the ProtonVPN dashboard.
2. Place it at `/etc/nixos/secrets/proton.conf` on atlas, `chmod 600`.

`wireguardConfigFile` is a **quoted string**, not a path literal — deliberately,
so the value is read at runtime and never enters `/nix/store`. A bare path fails
evaluation outright (`access to absolute path … is forbidden in pure evaluation
mode`).

To move it into sops: store the file body as `secrets/atlas.yaml` →
`proton_wg_config` (or as a `format = "binary"` sops file), point
`sops.secrets.proton_wg_config` at it, and set `wireguardConfigFile` to
`config.sops.secrets.proton_wg_config.path`.
