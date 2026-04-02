{ lib, config, ... }:
{
  options.swarselmodules.appimage = lib.mkEnableOption "appimage config";
  config = lib.mkIf config.swarselmodules.appimage {
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };

}
