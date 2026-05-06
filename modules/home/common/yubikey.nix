{ lib, config, confLib, type, ... }:
let
  inherit (config.swarselsystems) homeDir;
in
{

  config = {
    swarselsystems.enabledHomeModules = [ "yubikey" ];

    pam.yubico.authorizedYubiKeys = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) {
      ids = [
        confLib.getConfig.repo.secrets.common.yubikeys.dev1
        confLib.getConfig.secrets.common.yubikeys.dev2
      ];
    };
  } // lib.optionalAttrs (type != "nixos") {
    sops.secrets = lib.mkIf (!config.swarselsystems.isPublic) {
      u2f-keys = { path = "${homeDir}/.config/Yubico/u2f_keys"; };
    };
  };
}
