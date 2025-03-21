{ lib, config, ... }:
{
  options.swarselsystems = {
    inputs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
    };
    kyria = lib.mkOption {
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
    touchpad = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
    };
    standardinputs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = lib.recursiveUpdate (lib.recursiveUpdate config.swarselsystems.touchpad config.swarselsystems.kyria) config.swarselsystems.inputs;
      internal = true;
    };
    keybindings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
    shellAliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };
}
