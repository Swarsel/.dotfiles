{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/home/common";
  sharedNames = lib.swarselsystems.readNix "modules/shared";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/home/common" ++
    lib.swarselsystems.mkImports sharedNames "modules/shared";
}
