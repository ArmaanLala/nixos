# sops-nix wiring. Imported by common.nix, so every host has it.
#
# How decryption works here: at activation each host runs `ssh-to-age` on its
# own /etc/ssh/ssh_host_ed25519_key and uses the result as its age identity.
# `.sops.yaml` at the repo root records which host (and your personal) key each
# secret file is encrypted to. Nothing is copied to hosts -- they decrypt with a
# key they already have.
#
# Secrets are declared where they're used (e.g. modules/services/microbin.nix),
# not here. Each `sops.secrets.<name>` names its own `sopsFile`; the decrypted
# value lands at `config.sops.secrets.<name>.path` (under /run/secrets, tmpfs,
# root-only unless you set owner/mode).
{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # The SSH host key doubles as the age identity. This is the module default,
  # pinned here so it's explicit.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
