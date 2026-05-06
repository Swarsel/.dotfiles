{ self, ... }:
let
  m = "${self}/modules";
in
{
  imports = [
    "${m}/home/common/settings.nix"
    "${m}/home/common/sops.nix"
    "${m}/home/common/kitty.nix"
    "${m}/home/common/zsh.nix"
    "${m}/home/common/git.nix"
  ];
}
