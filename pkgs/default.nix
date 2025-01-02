{ lib, pkgs, ... }:
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
    "swarsel-bootstrap"
    "swarsel-rebuild"
    "swarsel-install"
    "swarsel-postinstall"
    "t2ts"
    "ts2t"
    "vershell"
    "eontimer"
    "project"
    "fhs"
  ];
in
lib.swarselsystems.mkPackages packageNames pkgs
