{ lib, config, ... }:
{
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = lib.swarselsystems.mkIfElse (config.swarselsystems.initialSetup || !config.swarselsystems.isSecureBoot) (lib.mkForce true) (lib.mkForce false);
    };
    lanzaboote = lib.mkIf (!config.swarselsystems.initialSetup && config.swarselsystems.isSecureBoot) {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
