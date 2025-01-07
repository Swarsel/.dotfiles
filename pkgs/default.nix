{ lib, pkgs, ... }:
let
  packageNames = lib.swarselsystems.readNix "pkgs";
in
lib.swarselsystems.mkPackages packageNames pkgs
