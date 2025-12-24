# @ future me: dont panic, this file is not read in by readNix
{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/home";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/home";
}
