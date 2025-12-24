{ self, lib, pkgs, config, homeConfig, ... }:
let
  mkPackages = names: pkgs: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = pkgs.callPackage "${self}/pkgs/config/${name}" { inherit self name homeConfig config; };
    })
    names);
  packageNames = lib.swarselsystems.readNix "pkgs/config";
in
mkPackages packageNames pkgs
