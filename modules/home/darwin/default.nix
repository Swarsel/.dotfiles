{ self, ... }:
{
  home.stateVersion = "23.05";
  imports = [
    "${self}/modules/home/common/settings.nix"
    "${self}/modules/shared/options.nix"
    "${self}/modules/shared/vars.nix"
  ];
}
