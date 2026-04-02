{ lib, config, ... }:
{
  options.swarselprofiles.hotel = lib.mkEnableOption "is this a hotel host";
  config = lib.mkIf config.swarselprofiles.hotel {
    swarselprofiles.personal = true;
    swarselmodules = {
      yubikey = false;
    };

  };

}
