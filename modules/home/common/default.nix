{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/home/common";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/home/common";
}
