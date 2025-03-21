{ lib, ... }:
{
  options.swarselsystems = {
    monitors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
    };
    sharescreen = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    lowResolution = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    highResolution = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };
}
