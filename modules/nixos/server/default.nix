{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/server";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/server";
}
