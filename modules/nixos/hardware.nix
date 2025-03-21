{ lib, ... }:

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
}
