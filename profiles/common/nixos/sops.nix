{ config, ... }:
{
  sops = {

    age.sshKeyPaths = [ "${config.users.users.swarsel.home}/.ssh/sops" ];
    defaultSopsFile = "${config.users.users.swarsel.home}/.dotfiles/secrets/general/secrets.yaml";
    validateSopsFiles = false;

    secrets = {
      swarseluser = { neededForUsers = true; };
      ernest = { };
      frauns = { };
      hotspot = { };
      eduid = { };
      edupass = { };
      handyhotspot = { };
      vpnuser = { };
      vpnpass = { };
    };
    templates = {
      "network-manager.env".content = ''
        ERNEST=${config.sops.placeholder.ernest}
        FRAUNS=${config.sops.placeholder.frauns}
        HOTSPOT=${config.sops.placeholder.hotspot}
        EDUID=${config.sops.placeholder.eduid}
        EDUPASS=${config.sops.placeholder.edupass}
        HANDYHOTSPOT=${config.sops.placeholder.handyhotspot}
        VPNUSER=${config.sops.placeholder.vpnuser}
        VPNPASS=${config.sops.placeholder.vpnpass}
      '';
    };
  };
}
