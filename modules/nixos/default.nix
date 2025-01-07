{ lib, ... }:
let
  moduleNames = lib.swarselsystems.readNix "modules/nixos";
in
lib.swarselsystems.mkModules moduleNames "nixos"
