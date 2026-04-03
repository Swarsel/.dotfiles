{ config, globals, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir;
  inherit (config.repo.secrets.common.emacs) radicaleUser;
in
{
  config = { } // {
    sops =
      {
        secrets = {
          address1-token = { owner = mainUser; };
          address2-token = { owner = mainUser; };
          address3-token = { owner = mainUser; };
          address4-token = { owner = mainUser; };
          github-notifications-token = { owner = mainUser; };
          fever-pw = { path = "${homeDir}/.emacs.d/.fever"; owner = mainUser; };
          emacs-radicale-pw = { owner = mainUser; };
          github-forge-token = { owner = mainUser; };
          radicale-token = { owner = mainUser; };
          anki-user = { owner = mainUser; };
          anki-pw = { owner = mainUser; };
        };
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
