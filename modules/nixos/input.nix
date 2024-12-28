{ lib, ... }:
{
  options.swarselsystems.shellAliases = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
  };
}
