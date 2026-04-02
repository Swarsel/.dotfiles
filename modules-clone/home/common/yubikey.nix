{ lib, config, confLib, type, ... }:
let
  inherit (config.swarselsystems) homeDir;
in
{
  options.swarselmodules.yubikey = lib.mkEnableOption "yubikey settings";

  config = lib.mkIf config.swarselmodules.yubikey ({

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
  });
}
