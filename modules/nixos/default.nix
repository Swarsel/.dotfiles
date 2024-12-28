{ lib, ... }:
let
  moduleNames = [
    "wallpaper"
    "hardware"
    "setup"
    "server"
    "input"
  ];
in
lib.swarselsystems.mkModules moduleNames "nixos"
