{ lib, ... }:
let
  moduleNames = lib.swarselsystems.readNix "modules/home";
in
lib.swarselsystems.mkModules moduleNames "home"
