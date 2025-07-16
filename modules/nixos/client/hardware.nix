{ pkgs, config, lib, ... }:
{

  options.swarselmodules.hardware = lib.mkEnableOption "hardware config";
  options.swarselsystems = {
    hasBluetooth = lib.mkEnableOption "bluetooth availability";
    hasFingerprint = lib.mkEnableOption "fingerprint sensor availability";
    trackpoint = {
      isAvailable = lib.mkEnableOption "trackpoint availability";
      trackpoint.device = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
    };
  };
  config = lib.mkIf config.swarselmodules.hardware {
    hardware = {
      # opengl.driSupport32Bit = true is replaced with graphics.enable32Bit and hence redundant
      graphics = {
        enable = true;
        enable32Bit = true;
      };


      trackpoint = lib.mkIf config.swarselsystems.trackpoint.isAvailable {
        enable = true;
        inherit (config.swarselsystems.trackpoint) device;
      };

      keyboard.qmk.enable = true;

      enableAllFirmware = lib.mkDefault true;

      bluetooth = lib.mkIf config.swarselsystems.hasBluetooth {
        enable = true;
        package = pkgs.stable.bluez;
        powerOnBoot = true;
        settings = {
          General = {
            Enable = "Source,Sink,Media,Socket";
          };
        };
      };
    };

    services.fprintd.enable = lib.mkIf config.swarselsystems.hasFingerprint true;
  };
}
