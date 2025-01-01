{ config, lib, ... }:
{
  sops = lib.mkIf (!config.swarselsystems.isPublic) {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/sops" "${config.home.homeDirectory}/.ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = lib.swarselsystems.mkIfElseList config.swarselsystems.isBtrfs "/persist/.dotfiles/secrets/general/secrets.yaml" "${config.home.homeDirectory}/.dotfiles/secrets/general/secrets.yaml";

    validateSopsFiles = false;
    secrets = {
      mrswarsel = { path = "/run/user/1000/secrets/mrswarsel"; };
      nautilus = { path = "/run/user/1000/secrets/nautilus"; };
      leon = { path = "/run/user/1000/secrets/leon"; };
      swarselmail = { path = "/run/user/1000/secrets/swarselmail"; };
      github_notif = { path = "/run/user/1000/secrets/github_notif"; };
      u2f_keys = { path = "${config.home.homeDirectory}/.config/Yubico/u2f_keys"; };
    };
  };
}
