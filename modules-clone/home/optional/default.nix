{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules-clone/home/optional";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules-clone/home/optional";
}
