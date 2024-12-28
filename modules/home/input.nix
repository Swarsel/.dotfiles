{ lib, config, ... }:
{
  options.swarselsystems.inputs = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
    default = { };
  };
  options.swarselsystems.kyria = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
    default = {
      "36125:53060:splitkb.com_splitkb.com_Kyria_rev3" = {
        xkb_layout = "us";
        xkb_variant = "altgr-intl";
      };
      "7504:24926:Kyria_Keyboard" = {
        xkb_layout = "us";
        xkb_variant = "altgr-intl";
      };
    };
  };
  options.swarselsystems.touchpad = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
    default = { };
  };
  options.swarselsystems.standardinputs = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
    default = lib.recursiveUpdate (lib.recursiveUpdate config.swarselsystems.touchpad config.swarselsystems.kyria) config.swarselsystems.inputs;
    internal = true;
  };
  options.swarselsystems.keybindings = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
  };
  options.swarselsystems.shellAliases = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
  };
}
