{ pkgs, config, lib, ... }:
{

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
  config = {
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

      enableAllFirmware = true;

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
