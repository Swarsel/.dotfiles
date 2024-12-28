{ lib, ... }:
{
  options.swarselsystems.monitors = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
    default = { };
  };
  options.swarselsystems.sharescreen = lib.mkOption {
    type = lib.types.str;
    default = "";
  };
  options.swarselsystems.lowResolution = lib.mkOption {
    type = lib.types.str;
    default = "";
  };
  options.swarselsystems.highResolution = lib.mkOption {
    type = lib.types.str;
    default = "";
  };
}
