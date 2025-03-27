{ lib, ... }:
let
  moduleNames = lib.swarselsystems.readNix "profiles/home";
in
lib.swarselsystems.mkModules moduleNames "home"
