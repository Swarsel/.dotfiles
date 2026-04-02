{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules-clone/nixos/server";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules-clone/nixos/server";
}
