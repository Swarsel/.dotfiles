{ lib, ... }:
let
  moduleNames = lib.swarselsystems.readNix "profiles/nixos";
in
lib.swarselsystems.mkProfiles moduleNames "nixos"
