{ config, ... }:
{
  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/sops" ];
    defaultSopsFile = "${config.home.homeDirectory}/.dotfiles/secrets/general/secrets.yaml";
    validateSopsFiles = false;
    secrets = {
      mrswarsel = { path = "/run/user/1000/secrets/mrswarsel"; };
      nautilus = { path = "/run/user/1000/secrets/nautilus"; };
      leon = { path = "/run/user/1000/secrets/leon"; };
      swarselmail = { path = "/run/user/1000/secrets/swarselmail"; };
      caldav = { path = "${config.home.homeDirectory}/.emacs.d/.caldav"; };
    };
  };
}
