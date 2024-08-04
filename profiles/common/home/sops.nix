{ config, lib, ... }:
let
  mkIfElse = p: yes: no: lib.mkMerge [
    (lib.mkIf p yes)
    (lib.mkIf (!p) no)
  ];
in
{
  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/sops" ];
    defaultSopsFile = mkIfElse config.swarselsystems.isBtrfs "/persist/.dotfiles/secrets/general/secrets.yaml" "${config.home.homeDirectory}/.dotfiles/secrets/general/secrets.yaml";

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
