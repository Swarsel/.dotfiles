{ lib, config, nixosConfig ? null, ... }:
let
  # mirrorAttrs = lib.mapAttrs (_: v: lib.mkDefault v) nixosConfig.swarselsystems;
  mkDefaultCommonAttrs = base: defaults:
    lib.mapAttrs (_: v: lib.mkDefault v)
      (lib.filterAttrs (k: _: base ? ${k}) defaults);
in
{
  # config.swarselsystems = mirrorAttrs;
  config.swarselsystems = lib.mkIf (nixosConfig != null) (mkDefaultCommonAttrs config.swarselsystems nixosConfig.swarselsystems);
}
