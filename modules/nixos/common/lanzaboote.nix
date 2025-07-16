{ lib, pkgs, config, minimal, ... }:
{
  options.swarselmodules.lanzaboote = lib.mkEnableOption "lanzaboote config";
  config = lib.mkIf config.swarselmodules.lanzaboote {

    environment.systemPackages = lib.mkIf config.swarselsystems.isSecureBoot [
      pkgs.sbctl
    ];

    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = lib.swarselsystems.mkIfElse (minimal || !config.swarselsystems.isSecureBoot) (lib.mkForce true) (lib.mkForce false);
      };
      lanzaboote = lib.mkIf (!minimal && config.swarselsystems.isSecureBoot) {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        configurationLimit = 6;
      };
    };
  };
}
