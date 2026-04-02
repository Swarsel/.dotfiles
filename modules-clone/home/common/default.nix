{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules-clone/home/common";
  sharedNames = lib.swarselsystems.readNix "modules-clone/shared";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules-clone/home/common" ++
    lib.swarselsystems.mkImports sharedNames "modules-clone/shared";
}
