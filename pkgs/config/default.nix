{
  self,
  homeConfig,
  config,
  lib,
  pkgs,
  ...
}:
lib.genAttrs (lib.swarselsystems.readNix "pkgs/config") (
  name:
  pkgs.callPackage "${self}/pkgs/config/${name}" {
    inherit
      self
      name
      homeConfig
      config
      ;
  }
)
