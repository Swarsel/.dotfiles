{ self, ... }:
{
  home.stateVersion = "23.05";
  imports = [
    "${self}/modules/home/common/settings.nix"
    "${self}/modules/shared/sharedsetup.nix"
  ];
}
