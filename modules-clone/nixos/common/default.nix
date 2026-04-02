{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules-clone/nixos/common";
  sharedNames = lib.swarselsystems.readNix "modules-clone/shared";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules-clone/nixos/common" ++
    lib.swarselsystems.mkImports sharedNames "modules-clone/shared";
}
