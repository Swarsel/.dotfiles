{ lib, ... }:
let
  moduleNames = lib.swarselsystems.readNix "profiles/nixos";
in
lib.swarselsystems.mkModules moduleNames "nixos"
