{ self, lib, ... }:
let
  importNames = lib.swarselsystems.readNix "modules/home/server";
  modulesPath = "${self}/modules";
in
{
  imports = lib.swarselsystems.mkImports importNames "modules/home/server" ++ [
    "${modulesPath}/home/common/settings.nix"
  ];
}
