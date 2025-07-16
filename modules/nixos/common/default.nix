{ self, lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/common";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/common" ++ [
    "${self}/modules/shared/sharedsetup.nix"
  ];


}
