# User configuration: groups, users, SSH keys
{ ... }:

{
  users.groups.armaan = {
    gid = 1000;
  };

  users.users.armaan = {
    isNormalUser = true;
    description = "Armaan Lala";
    extraGroups = [
      "networkmanager"
      "wheel"
      "armaan"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxWbEebtUXP/g3+lSqQxRV8j3HbDZPEfvksbBognPtz armaan@nyx 2025-12-2"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPS2foqCO+tCzjg/CYsuaTX5SsjZyEpquDjbH4WXkLwR armaan@thinkpad 2025-12-03"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGWCoSW1PMIeftP7bqfZntLdRvhGBhpvzaLFZrXTvTrp armaanlala@apple-j616c 2025-12-03"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIOlH4q2wStz0qVgW9iVvJ4v/sH13wCnQkkgFCpIVGmY 2025-12-10 armaan@beef"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoygK39u8MDsc701vj1Vn9ow3eOtpk6kU+9UnmYrduq 2025-12-10 armaan@nix-thinkpad"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
    };
  };
}
