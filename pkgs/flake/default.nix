{
  self,
  lib,
  pkgs,
  ...
}:
lib.genAttrs (lib.swarselsystems.readNix "pkgs/flake") (
  name:
  pkgs.callPackage "${self}/pkgs/flake/${name}" {
    inherit self name;
    inherit (self.swarselsystemsLib) root;
  }
)
