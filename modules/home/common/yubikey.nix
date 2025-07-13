{ lib, config, nixosConfig, ... }:
let
  inherit (config.swarselsystems) homeDir;
in
{
  options.swarselsystems.modules.yubikey = lib.mkEnableOption "yubikey settings";

  config = lib.mkIf config.swarselsystems.modules.yubikey {

    sops.secrets = lib.mkIf (!config.swarselsystems.isPublic) {
      u2f-keys = { path = "${homeDir}/.config/Yubico/u2f_keys"; };
    };

    pam.yubico.authorizedYubiKeys = lib.mkIf (config.swarselsystems.isNixos && !config.swarselsystems.isPublic) {
      ids = [
        nixosConfig.repo.secrets.common.yubikeys.dev1
        nixosConfig.repo.secrets.common.yubikeys.dev2
      ];
    };
  };
}
