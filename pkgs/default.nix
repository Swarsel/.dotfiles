{ pkgs, ... }:
let
  packageNames = [
    "pass-fuzzel"
    "cura5"
    "hm-specialisation"
    "cdw"
    "cdb"
    "bak"
    "timer"
    "e"
    "swarselcheck"
    "waybarupdate"
    "opacitytoggle"
    "fs-diff"
    "update-checker"
    "github-notifications"
    "screenshare"
    "bootstrap"
    "t2ts"
    "ts2t"
  ];
  mkPackages = names: builtins.listToAttrs (map
    (name: {
      inherit name;
      value = pkgs.callPackage ./${name} { };
    })
    names);
in
mkPackages packageNames
