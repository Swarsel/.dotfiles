{ lib, config, nixosConfig, ... }:
{
  options.swarselsystems.modules.yubikey = lib.mkEnableOption "yubikey settings";

  config = lib.mkIf config.swarselsystems.modules.yubikey {
    pam.yubico.authorizedYubiKeys = {
      ids = [
        nixosConfig.repo.secrets.common.yubikeys.dev1
        nixosConfig.repo.secrets.common.yubikeys.dev2
      ];
    };
  };
}
