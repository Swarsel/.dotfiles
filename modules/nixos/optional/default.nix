{ self, lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/nixos/optional";
  modulesPath = "${self}/modules";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/nixos/optional" ++ [
    "${modulesPath}/home/common/sharedsetup.nix"
  ];


}
