{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/common";
  sharedNames = lib.swarselsystems.readNix "modules/shared";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/common" ++
    lib.swarselsystems.mkImports sharedNames "modules/shared";
}
