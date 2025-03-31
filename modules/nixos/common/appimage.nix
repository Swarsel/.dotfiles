{ lib, config, ... }:
{
  options.swarselsystems.modules.appimage = lib.mkEnableOption "appimage config";
  config = lib.mkIf config.swarselsystems.modules.appimage {
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };

}
