{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos";
}
