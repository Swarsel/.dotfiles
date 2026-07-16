{
  flake.modules.nixos.hardware =
    {
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    {

      options.swarselsystems = {
        hasBluetooth = lib.mkEnableOption "bluetooth availability";
        hasFingerprint = lib.mkEnableOption "fingerprint sensor availability";
        trackpoint = {
          isAvailable = lib.mkEnableOption "trackpoint availability";
          trackpoint.device = lib.mkOption {
            default = "";
            type = lib.types.str;
          };
        };
      };
      config = {

        users.persistentIds.plugdev = confLib.mkIds 953;
        services.fprintd.enable = lib.mkIf config.swarselsystems.hasFingerprint true;
        hardware = {
          bluetooth = lib.mkIf config.swarselsystems.hasBluetooth {
            enable = true;
            package = pkgs.bluez;
            powerOnBoot = true;
            settings = {
              General = {
                Enable = "Source,Sink,Media,Socket";
              };
            };
          };
          enableAllFirmware = lib.mkDefault true;
          # opengl.driSupport32Bit = true is replaced with graphics.enable32Bit and hence redundant
          graphics = {
            enable = true;
            enable32Bit = true;
          };
          keyboard.qmk.enable = true;
          trackpoint = lib.mkIf config.swarselsystems.trackpoint.isAvailable {
            inherit (config.swarselsystems.trackpoint) device;
            enable = true;
          };
          usbStorage.manageShutdown = true;
        };
      };
    };
}
