{ lib, config, ... }:
let
  inherit (config.swarselsystems) mainUser xdgDir homeDir;
  modules = config.home-manager.users.${mainUser}.swarselmodules;
in
{
  config = lib.mkIf config.swarselsystems.withHomeManager {
    sops.secrets = (lib.optionalAttrs modules.mail
      {
        address1-token = { path = "${xdgDir}/secrets/address1-token"; owner = mainUser; };
        address2-token = { path = "${xdgDir}/secrets/address2-token"; owner = mainUser; };
        address3-token = { path = "${xdgDir}/secrets/address3-token"; owner = mainUser; };
        address4-token = { path = "${xdgDir}/secrets/address4-token"; owner = mainUser; };
      }) // (lib.optionalAttrs modules.waybar {
      github-notifications-token = { path = "${xdgDir}/secrets/github-notifications-token"; owner = mainUser; };
    }) // (lib.optionalAttrs modules.emacs {
      fever-pw = { path = "${homeDir}/.emacs.d/.fever"; owner = mainUser; };
    }) // (lib.optionalAttrs modules.zsh {
      croc-password = { path = "${xdgDir}/secrets/croc-password"; owner = mainUser; };
    });
  };
}
