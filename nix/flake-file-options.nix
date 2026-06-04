{ lib, ... }:
{
  options.flake-file.inputs = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.attrsOf lib.types.anything);
    default = { };
  };
}
