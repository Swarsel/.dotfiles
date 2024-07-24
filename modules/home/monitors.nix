{ lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.swarselsystems.monitors = mkOption {
    type = types.attrsOf (types.attrsOf types.str);
    default = { };
  };
}
