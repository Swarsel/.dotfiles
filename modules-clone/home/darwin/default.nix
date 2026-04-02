{ self, ... }:
{
  home.stateVersion = "23.05";
  imports = [
    "${self}/modules-clone/home/common/settings.nix"
    "${self}/modules-clone/shared/options.nix"
    "${self}/modules-clone/shared/vars.nix"
  ];
}
