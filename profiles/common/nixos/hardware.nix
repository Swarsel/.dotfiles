{ pkgs, ... }:
{

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };

    enableAllFirmware = true;

    bluetooth = {
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };
}
