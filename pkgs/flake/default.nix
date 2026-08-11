{
  self,
  lib,
  pkgs,
  ...
}:
let
  mkPackages =
    names: pkgs:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = pkgs.callPackage "${self}/pkgs/flake/${name}" {
          inherit self name;
          root = self.swarselsystemsLib.root;
        };
      }) names
    );
  packageNames = lib.swarselsystems.readNix "pkgs/flake";
in
mkPackages packageNames pkgs
