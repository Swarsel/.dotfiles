{ lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.swarselsystems.inputs = mkOption {
    type = types.attrsOf (types.attrsOf types.str);
    default = { };
  };
  options.swarselsystems.kyria = mkOption {
    type = types.attrsOf (types.attrsOf types.str);
    default = {
      "36125:53060:splitkb.com_splitkb.com_Kyria_rev3" = {
        xkb_layout = "us";
        xkb_variant = "altgr-intl";
      };
    };
  };
  options.swarselsystems.touchpad = mkOption {
    type = types.attrsOf (types.attrsOf types.str);
    default = { };
  };
  options.swarselsystems.standardinputs = mkOption {
    type = types.attrsOf (types.attrsOf types.str);
    default = lib.recursiveUpdate (lib.recursiveUpdate config.swarselsystems.touchpad config.swarselsystems.kyria) config.swarselsystems.inputs;
    internal = true;
  };
  options.swarselsystems.keybindings = mkOption {
    type = types.attrsOf types.str;
    default = { };
  };

}
