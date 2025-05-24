{ self, lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/common";
  modulesPath = "${self}/modules";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/common" ++ [
    "${modulesPath}/home/common/sharedsetup.nix"
  ];


}
