{ self, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    "${m}/home/common/settings.nix"
    "${m}/home/server/symlink.nix"
  ];
}
