{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.swarselsystems.monitors = mkOption {
    type = types.attrsOf (types.attrsOf types.str);
    default = { };
  };
  options.swarselsystems.sharescreen = mkOption {
    type = types.str;
    default = "";
  };
  options.swarselsystems.lowResolution = mkOption {
    type = types.str;
    default = "";
  };
  options.swarselsystems.highResolution = mkOption {
    type = types.str;
    default = "";
  };
}
