{ self, lib, ... }:
let
  importNames = lib.swarselsystems.readNix "profiles/home/server";
  profilesPath = "${self}/profiles";
in
{
  imports = lib.swarselsystems.mkImports importNames "profiles/home/server" ++ [
    "${profilesPath}/home/common/settings.nix"
    "${profilesPath}/home/common/sharedsetup.nix"
  ];
}
