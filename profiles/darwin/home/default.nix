{ self, ... }:
let
  profilesPath = "${self}/profiles";
in
{
  imports = [
    "${profilesPath}/home/common/settings.nix"
  ];
}
