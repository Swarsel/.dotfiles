{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/home";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/home";
}
