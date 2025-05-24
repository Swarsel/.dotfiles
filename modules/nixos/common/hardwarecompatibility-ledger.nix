{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.ledger = lib.mkEnableOption "ledger config";
  config = lib.mkIf config.swarselsystems.modules.ledger {
    hardware.ledger.enable = true;

    services.udev.packages = with pkgs; [
      ledger-udev-rules
    ];
  };

}
