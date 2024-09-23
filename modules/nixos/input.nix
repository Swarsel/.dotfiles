{ lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.swarselsystems.shellAliases = mkOption {
    type = types.attrsOf types.str;
    default = { };
  };
}
