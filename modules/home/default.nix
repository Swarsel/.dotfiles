# @ future me: dont panic, this file is not read in by readNix
{ self, lib, ... }:
let
  sharedNames = lib.swarselsystems.readNix "modules/shared";
in
{
  imports = lib.swarselsystems.mkImports sharedNames "modules/shared" ++ [
    "${self}/nix/flake-file-options.nix"
    "${self}/modules/home/common/sharedoptions.nix"
  ];
}
