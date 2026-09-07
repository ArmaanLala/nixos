# Secrets

Most secrets live **encrypted in this repo** under `secrets/`, via
[sops-nix](https://github.com/Mic92/sops-nix). Each host decrypts what it needs
at activation using an age key derived from its own SSH host key — nothing is
copied by hand, and `system.autoUpgrade` ships secret changes with everything
else.

| File                   | Decryptable by  | Contents                                   |
| ---------------------- | --------------- | ------------------------------------------ |
| `secrets/webster.yaml` | armaan, webster | `microbin_admin_password`, `groupme_token` |

Two secrets are hand-placed instead:

**`/etc/nix/github-token.conf`** (all hosts, pulled in by `common.nix` as
`nix.extraOptions = "!include ..."`). Can't be sops because `nix` reads it while
fetching flake inputs, before activation. `!include` tolerates it being absent,
but a host whose eval touches a private input (currently only webster's
`site-seth` / `site-trumpet-snipes`) then fails to fetch it. Format, `chmod 600`,
root-owned:

```
access-tokens = github.com=ghp_...
```

Also add it as the `FLAKE_PRIVATE_TOKEN` Actions secret so CI can evaluate
webster.

**`/etc/nixos/secrets/proton.conf`** (atlas) — a ProtonVPN WireGuard config used
by `modules/services/vpn.nix` to confine sabnzbd. `wireguardConfigFile` is a
quoted string, not a path literal, so the file is read at runtime and never
enters the store. Download it from the ProtonVPN dashboard, place it there,
`chmod 600`. Migrate to sops later: store the body as `secrets/atlas.yaml` →
`proton_wg_config` and point `wireguardConfigFile` at
`config.sops.secrets.proton_wg_config.path`.

## How it works

- **`.sops.yaml`** (repo root) maps secret files to the age keys allowed to
  decrypt them. Host key → age: `ssh <host> 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age`.
  `armaan` is the personal key at `~/.config/sops/age/keys.txt` — required to
  edit any secret. Keep a copy in a password manager; it's the recovery path.
- **`modules/core/sops.nix`** (imported by `common.nix`) points sops-nix at
  `/etc/ssh/ssh_host_ed25519_key`.
- Secrets are declared in the module that uses them, each naming its own
  `sopsFile`. No `defaultSopsFile` — hosts without a secrets file must not
  reference one or eval breaks. Decrypted values land under `/run/secrets/`
  (tmpfs, root-only), never the store.

## Editing / adding

```bash
nix shell nixpkgs#sops nixpkgs#age nixpkgs#ssh-to-age
cd ~/dotfiles/.config/nixos

sops secrets/webster.yaml          # edit (decrypts in $EDITOR, re-encrypts on save)
sops -d secrets/webster.yaml       # view
sops secrets/atlas.yaml            # create -- name must match a rule in .sops.yaml
```

In the consuming module:

```nix
sops.secrets.my_secret.sopsFile = ../../secrets/webster.yaml;
# single value:  config.sops.secrets.my_secret.path
# EnvironmentFile: render one via sops.templates."foo.env" with
#                  ${config.sops.placeholder.my_secret}
```

Commit the encrypted file and the module change together, and push before
rebuilding a host.

## Adding a host to sops

1. `ssh <host> 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age`
2. Add the `age1…` to `.sops.yaml` under `keys:` and the relevant
   `creation_rules`.
3. `sops updatekeys secrets/<file>` for each file whose recipients changed; commit.

New VM clones share the template's SSH host key — regenerate before using them
for secrets: `sudo rm /etc/ssh/ssh_host_* && sudo ssh-keygen -A && sudo systemctl restart sshd`.
