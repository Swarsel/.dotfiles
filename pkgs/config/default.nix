{ self, homeConfig, lib, pkgs, ... }:
let
  mkPackages = names: pkgs: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = pkgs.callPackage "${self}/pkgs/config/${name}" { inherit self name homeConfig; };
    })
    names);
  packageNames = lib.swarselsystems.readNix "pkgs/config";
in
mkPackages packageNames pkgs
