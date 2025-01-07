{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "profiles/home/common";
in
{
  imports = lib.swarselsystems.mkImports importNames "profiles/home/common";
}
