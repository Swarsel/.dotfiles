{ lib, config, ... }:
{
  options.swarselsystems.modules.lanzaboote = lib.mkEnableOption "lanzaboote config";
  config = lib.mkIf config.swarselsystems.modules.lanzaboote {
    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = lib.swarselsystems.mkIfElse (config.swarselsystems.initialSetup || !config.swarselsystems.isSecureBoot) (lib.mkForce true) (lib.mkForce false);
      };
      lanzaboote = lib.mkIf (!config.swarselsystems.initialSetup && config.swarselsystems.isSecureBoot) {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        configurationLimit = 6;
      };
    };
  };
}
