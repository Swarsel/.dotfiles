{ pkgs, config, lib, ... }:
{

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    trackpoint = lib.mkIf config.swarselsystems.trackpoint.isAvailable {
      enable = true;
      inherit (config.swarselsystems.trackpoint) device;
    };

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };

    enableAllFirmware = true;

    bluetooth = lib.mkIf config.swarselsystems.hasBluetooth {
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };

  services.fprintd.enable = lib.mkIf config.swarselsystems.hasFingerprint true;
}
