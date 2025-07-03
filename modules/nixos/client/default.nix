{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/client";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/client";
}
