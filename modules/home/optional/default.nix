{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/home/optional";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/home/optional";
}
