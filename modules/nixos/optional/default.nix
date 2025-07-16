{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/optional";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/optional";
}
