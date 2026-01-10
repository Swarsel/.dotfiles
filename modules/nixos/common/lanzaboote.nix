{ lib, pkgs, config, minimal, ... }:
let
  inherit (config.swarselsystems) isSecureBoot isImpermanence;
in
{
  options.swarselmodules.lanzaboote = lib.mkEnableOption "lanzaboote config";
  config = lib.mkIf config.swarselmodules.lanzaboote {

    environment.systemPackages = lib.mkIf isSecureBoot [
      pkgs.sbctl
    ];

    environment.persistence."/persist" = lib.mkIf (isImpermanence && isSecureBoot) {
      directories = [{ directory = "/var/lib/sbctl"; }];
    };

    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = lib.swarselsystems.mkIfElse (minimal || !isSecureBoot) (lib.mkForce true) (lib.mkForce false);
      };
      lanzaboote = lib.mkIf (!minimal && isSecureBoot) {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        configurationLimit = 6;
      };
    };
  };
}
