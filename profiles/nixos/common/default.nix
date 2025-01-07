{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "profiles/nixos/common";
in
{
  imports = lib.swarselsystems.mkImports importNames "profiles/nixos/common";

  nixpkgs.config.permittedInsecurePackages = [
    "jitsi-meet-1.0.8043"
    "electron-29.4.6"
  ];

}
