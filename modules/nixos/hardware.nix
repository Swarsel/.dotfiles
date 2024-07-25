{ lib, ... }:

{
  options.swarselsystems.hasBluetooth = lib.mkEnableOption "bluetooth availability";
  options.swarselsystems.hasFingerprint = lib.mkEnableOption "fingerprint sensor availability";
  options.swarselsystems.trackpoint.isAvailable = lib.mkEnableOption "trackpoint availability";
  options.swarselsystems.trackpoint.device = lib.mkOption {
    type = lib.types.str;
    default = "";
  };
}
