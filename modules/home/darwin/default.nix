{ self, ... }:
let
  modulesPath = "${self}/modules";
in
{
  imports = [
    "${modulesPath}/home/common/settings.nix"
    "${modulesPath}/home/common/sharedsetup.nix"
  ];
}
