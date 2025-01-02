{ lib, ... }:
let
  moduleNames = [
    "laptop"
    "hardware"
    "monitors"
    "input"
    "nixos"
    "setup"
    "waybar"
    "startup"
    "wallpaper"
    "filesystem"
    "firefox"
  ];
in
lib.swarselsystems.mkModules moduleNames "home"
