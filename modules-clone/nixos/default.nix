# @ future me: dont panic, optionals and darwin are not read in  by readNix
{ lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules-clone/nixos";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules-clone/nixos";
}
