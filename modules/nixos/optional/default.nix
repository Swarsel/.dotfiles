# @ future me: dont panic, this file is not read in by readNix
{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/optional";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/optional";
}
