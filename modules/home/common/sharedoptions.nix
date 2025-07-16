{ lib, config, nixosConfig, ... }:
let
  # mirrorAttrs = lib.mapAttrs (_: v: lib.mkDefault v) nixosConfig.swarselsystems;
  inherit (lib) mkDefault mapAttrs filterAttrs;
  mkDefaultCommonAttrs = base: defaults:
    lib.mapAttrs (_: v: lib.mkDefault v)
      (lib.filterAttrs (k: _: base ? ${k}) defaults);
in
{
  # config.swarselsystems = mirrorAttrs;
  config.swarselsystems = mkDefaultCommonAttrs config.swarselsystems nixosConfig.swarselsystems;
}
