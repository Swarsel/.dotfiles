{ self, lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules-clone/home/server";
  modulesPath = "${self}/modules-clone";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules-clone/home/server" ++ [
    "${modulesPath}/home/common/settings.nix"
  ];
}
