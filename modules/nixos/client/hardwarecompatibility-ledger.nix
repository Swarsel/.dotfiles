{ lib, config, pkgs, ... }:
{
  options.swarselmodules.ledger = lib.mkEnableOption "ledger config";
  config = lib.mkIf config.swarselmodules.ledger {
    hardware.ledger.enable = true;

    services.udev.packages = with pkgs; [
      ledger-udev-rules
    ];
  };

}
