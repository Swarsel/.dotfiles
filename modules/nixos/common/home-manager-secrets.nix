{ lib, config, globals, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir;
  inherit (config.repo.secrets.common.emacs) radicaleUser;
  modules = config.home-manager.users.${mainUser}.swarselmodules;
in
{
  config = lib.mkIf config.swarselsystems.withHomeManager {
    sops = {
      secrets = (lib.optionalAttrs modules.mail
        {
          address1-token = { owner = mainUser; };
          address2-token = { owner = mainUser; };
          address3-token = { owner = mainUser; };
          address4-token = { owner = mainUser; };
        }) // (lib.optionalAttrs modules.waybar {
        github-notifications-token = { owner = mainUser; };
      }) // (lib.optionalAttrs modules.emacs {
        fever-pw = { path = "${homeDir}/.emacs.d/.fever"; owner = mainUser; };
      }) // (lib.optionalAttrs modules.zsh {
        croc-password = { owner = mainUser; };
      }) // (lib.optionalAttrs modules.emacs {
        emacs-radicale-pw = { owner = mainUser; };
      });
      templates = {
        authinfo = {
          path = "${homeDir}/.emacs.d/.authinfo";
          content = ''
            machine ${globals.services.radicale.domain} login ${radicaleUser} password ${config.sops.placeholder.emacs-radicale-pw}
          '';
          owner = mainUser;
        };
      };
    };
  };
}
